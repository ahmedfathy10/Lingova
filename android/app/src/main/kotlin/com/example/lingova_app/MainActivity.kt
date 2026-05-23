package com.example.lingova_app

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.speech.tts.TextToSpeech
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Locale

class MainActivity : FlutterActivity() {
    private var textToSpeech: TextToSpeech? = null
    private var textToSpeechReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lingova/downloads")
            .setMethodCallHandler { call, result ->
                if (call.method != "savePdf") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val fileName = call.argument<String>("fileName") ?: "certificate.pdf"
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null) {
                    result.error("missing_bytes", "No PDF bytes were provided.", null)
                    return@setMethodCallHandler
                }

                try {
                    val path = savePdfToDownloads(fileName, bytes)
                    result.success(path)
                } catch (error: Exception) {
                    result.error("save_failed", error.message, null)
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lingova/speech")
            .setMethodCallHandler { call, result ->
                if (call.method != "speak") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val text = call.argument<String>("text") ?: ""
                val language = call.argument<String>("language") ?: "en"
                if (text.isBlank()) {
                    result.error("missing_text", "No text was provided.", null)
                    return@setMethodCallHandler
                }

                speakText(text, language, result)
            }
    }

    override fun onDestroy() {
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
        super.onDestroy()
    }

    private fun savePdfToDownloads(fileName: String, bytes: ByteArray): String {
        val cleanName = fileName.replace(Regex("""[\\/:*?"<>|]"""), "_")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val values = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, cleanName)
                    put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
                    put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/Lingova")
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }

                val resolver = applicationContext.contentResolver
                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                    ?: throw IllegalStateException("Could not create Downloads file.")

                resolver.openOutputStream(uri)?.use { output ->
                    output.write(bytes)
                } ?: throw IllegalStateException("Could not open Downloads file.")

                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
                return "Downloads/Lingova/$cleanName"
            } catch (_: Exception) {
                return savePdfToAppDownloads(cleanName, bytes)
            }
        }

        return savePdfToAppDownloads(cleanName, bytes)
    }

    private fun savePdfToAppDownloads(fileName: String, bytes: ByteArray): String {
        val downloads = applicationContext.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
            ?: applicationContext.filesDir
        val folder = File(downloads, "Lingova")
        if (!folder.exists()) {
            folder.mkdirs()
        }
        val file = File(folder, fileName)
        file.writeBytes(bytes)
        return file.absolutePath
    }

    private fun speakText(text: String, language: String, result: MethodChannel.Result) {
        val engine = textToSpeech
        if (engine != null && textToSpeechReady) {
            engine.language = localeFor(language)
            engine.speak(text, TextToSpeech.QUEUE_FLUSH, null, "lingova-vocabulary")
            result.success(null)
            return
        }

        textToSpeech = TextToSpeech(applicationContext) { status ->
            if (status != TextToSpeech.SUCCESS) {
                result.error("tts_unavailable", "Text to speech is unavailable.", null)
                return@TextToSpeech
            }

            val initializedEngine = textToSpeech
            if (initializedEngine == null) {
                result.error("tts_unavailable", "Text to speech is unavailable.", null)
                return@TextToSpeech
            }

            textToSpeechReady = true
            initializedEngine.language = localeFor(language)
            initializedEngine.speak(text, TextToSpeech.QUEUE_FLUSH, null, "lingova-vocabulary")
            result.success(null)
        }
    }

    private fun localeFor(language: String): Locale {
        return when (language.lowercase(Locale.ROOT)) {
            "de", "de-de" -> Locale.GERMAN
            "ar", "ar-eg" -> Locale("ar", "EG")
            else -> Locale.ENGLISH
        }
    }
}
