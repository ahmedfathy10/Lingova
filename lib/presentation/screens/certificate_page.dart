import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/app_colors.dart';
import '../../data/models/exam.dart';

class CertificatePage extends StatefulWidget {
  final ExamResult result;

  const CertificatePage({super.key, required this.result});

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  static const _templateAsset = 'assets/images/certificate_template_blank.png';
  static const _templateWidth = 1086.0;
  static const _templateHeight = 1536.0;

  bool _isExporting = false;

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);

    try {
      final pdf = pw.Document();
      final templateImage = pw.MemoryImage(await _loadTemplateBytes());
      final regularFont = _isRtl
          ? await PdfGoogleFonts.cairoRegular()
          : await PdfGoogleFonts.robotoRegular();
      final boldFont = _isRtl
          ? await PdfGoogleFonts.cairoBold()
          : await PdfGoogleFonts.robotoBold();
      final displayFont = _isRtl
          ? await PdfGoogleFonts.cairoBold()
          : await PdfGoogleFonts.greatVibesRegular();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Image(templateImage, fit: pw.BoxFit.fill),
              ),
              _pdfText(
                widget.result.studentName,
                x: 240,
                y: _isRtl ? 485 : 470,
                width: 606,
                height: 82,
                font: displayFont,
                fontSize: _isRtl ? 38 : 58,
                direction: _pdfTextDirection,
              ),
              _pdfText(
                widget.result.courseTitle,
                x: 500,
                y: 803,
                width: 330,
                height: 30,
                font: boldFont,
                fontSize: 17,
                direction: _pdfTextDirection,
              ),
              _pdfText(
                widget.result.levelTitle,
                x: 500,
                y: 860,
                width: 330,
                height: 30,
                font: boldFont,
                fontSize: 17,
                direction: _pdfTextDirection,
              ),
              _pdfText(
                widget.result.courseLanguage,
                x: 500,
                y: 918,
                width: 330,
                height: 30,
                font: boldFont,
                fontSize: 17,
                direction: _pdfTextDirection,
              ),
              _pdfText(
                _examDateLabel,
                x: 500,
                y: 976,
                width: 330,
                height: 30,
                font: regularFont,
                fontSize: 15,
                direction: pw.TextDirection.ltr,
              ),
              _pdfText(
                _scoreLabel,
                x: 500,
                y: 1034,
                width: 330,
                height: 30,
                font: boldFont,
                fontSize: 17,
                direction: pw.TextDirection.ltr,
              ),
              _pdfText(
                _examDateLabel,
                x: 650,
                y: 1282,
                width: 260,
                height: 56,
                font: displayFont,
                fontSize: 26,
                direction: pw.TextDirection.ltr,
              ),
            ],
          ),
        ),
      );

      final bytes = await pdf.save();
      final fileName = _safeFileName(
        'Lingova_Certificate_${widget.result.studentName}_${widget.result.courseTitle}_${widget.result.levelTitle}.pdf',
      );
      final savedPath = await _savePdfToUserDevice(bytes, fileName);
      if (savedPath == null || !mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_copy.savedMessage(savedPath))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${_copy.saveError}\n$error')));
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<Uint8List> _loadTemplateBytes() async {
    try {
      final data = await rootBundle.load(_templateAsset);
      if (data.lengthInBytes > 0) {
        return data.buffer.asUint8List();
      }
    } catch (_) {}

    final file = _templateFallbackFile();
    if (file != null) {
      return file.readAsBytes();
    }

    throw StateError('Certificate template asset could not be loaded.');
  }

  Future<String?> _savePdfToUserDevice(Uint8List bytes, String fileName) async {
    try {
      final savedPath = await FilePicker.saveFile(
        dialogTitle: _copy.download,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        bytes: bytes,
        lockParentWindow: true,
      );

      if (kIsWeb) return fileName;
      return savedPath;
    } catch (error) {
      final didShare = await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
        subject: _copy.certificateTitle,
      );
      if (didShare) return fileName;
      throw Exception('${_copy.saveError}\n$error');
    }
  }

  pw.Widget _pdfText(
    String text, {
    required double x,
    required double y,
    required double width,
    required double height,
    required pw.Font font,
    required double fontSize,
    required pw.TextDirection direction,
  }) {
    return pw.Positioned(
      left: _pdfX(x),
      top: _pdfY(y),
      child: pw.Container(
        width: _pdfW(width),
        height: _pdfH(height),
        alignment: pw.Alignment.center,
        child: pw.Directionality(
          textDirection: direction,
          child: pw.FittedBox(
            fit: pw.BoxFit.scaleDown,
            child: pw.Text(
              text.isEmpty ? '-' : text,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font: font,
                fontSize: fontSize,
                color: PdfColors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _certificatePreview() {
    return AspectRatio(
      aspectRatio: _templateWidth / _templateHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double sx(double value) {
              return value / _templateWidth * constraints.maxWidth;
            }

            double sy(double value) {
              return value / _templateHeight * constraints.maxHeight;
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                _templateImage(),
                _previewText(
                  widget.result.studentName,
                  left: sx(240),
                  top: sy(_isRtl ? 485 : 470),
                  width: sx(606),
                  height: sy(82),
                  fontSize: sx(_isRtl ? 46 : 70),
                  fontFamily: _isRtl ? null : 'serif',
                  fontStyle: _isRtl ? FontStyle.normal : FontStyle.italic,
                  fontWeight: _isRtl ? FontWeight.w800 : FontWeight.w400,
                ),
                _previewText(
                  widget.result.courseTitle,
                  left: sx(500),
                  top: sy(803),
                  width: sx(330),
                  height: sy(30),
                  fontSize: sx(20),
                  fontWeight: FontWeight.w700,
                ),
                _previewText(
                  widget.result.levelTitle,
                  left: sx(500),
                  top: sy(860),
                  width: sx(330),
                  height: sy(30),
                  fontSize: sx(20),
                  fontWeight: FontWeight.w700,
                ),
                _previewText(
                  widget.result.courseLanguage,
                  left: sx(500),
                  top: sy(918),
                  width: sx(330),
                  height: sy(30),
                  fontSize: sx(20),
                  fontWeight: FontWeight.w700,
                ),
                _previewText(
                  _examDateLabel,
                  left: sx(500),
                  top: sy(976),
                  width: sx(330),
                  height: sy(30),
                  fontSize: sx(18),
                  fontWeight: FontWeight.w700,
                  textDirection: TextDirection.ltr,
                ),
                _previewText(
                  _scoreLabel,
                  left: sx(500),
                  top: sy(1034),
                  width: sx(330),
                  height: sy(30),
                  fontSize: sx(20),
                  fontWeight: FontWeight.w700,
                  textDirection: TextDirection.ltr,
                ),
                _previewText(
                  _examDateLabel,
                  left: sx(650),
                  top: sy(1282),
                  width: sx(260),
                  height: sy(56),
                  fontSize: sx(31),
                  fontFamily: 'serif',
                  fontStyle: FontStyle.italic,
                  textDirection: TextDirection.ltr,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _templateImage() {
    return Image.asset(
      _templateAsset,
      fit: BoxFit.fill,
      errorBuilder: (context, error, stackTrace) {
        final fallback = _templateFallbackFile();
        if (fallback != null) {
          return Image.file(fallback, fit: BoxFit.fill);
        }
        return Center(
          child: Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        );
      },
    );
  }

  File? _templateFallbackFile() {
    final executableDir = File(Platform.resolvedExecutable).parent;
    final candidates = [
      File(_templateAsset),
      File('assets/images/certificate_template_blank.png'),
      File(
        'build/windows/x64/runner/Debug/data/flutter_assets/$_templateAsset',
      ),
      File('${executableDir.path}/data/flutter_assets/$_templateAsset'),
    ];

    for (final file in candidates) {
      if (file.existsSync() && file.lengthSync() > 0) {
        return file;
      }
    }
    return null;
  }

  Widget _previewText(
    String text, {
    required double left,
    required double top,
    required double width,
    required double height,
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    FontStyle fontStyle = FontStyle.normal,
    String? fontFamily,
    TextDirection? textDirection,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Directionality(
        textDirection: textDirection ?? _textDirection,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text.isEmpty ? '-' : text,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: fontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle,
              fontFamily: fontFamily,
            ),
          ),
        ),
      ),
    );
  }

  double _pdfX(double value) => value / _templateWidth * PdfPageFormat.a4.width;

  double _pdfY(double value) =>
      value / _templateHeight * PdfPageFormat.a4.height;

  double _pdfW(double value) => value / _templateWidth * PdfPageFormat.a4.width;

  double _pdfH(double value) =>
      value / _templateHeight * PdfPageFormat.a4.height;

  bool get _isEnglish {
    final language = widget.result.courseLanguage.toLowerCase();
    return language.contains('english') || language.contains('eng');
  }

  bool get _isGerman {
    final language = widget.result.courseLanguage.toLowerCase();
    return language.contains('german') || language.contains('deutsch');
  }

  bool get _isRtl => !_isEnglish && !_isGerman;

  TextDirection get _textDirection =>
      _isRtl ? TextDirection.rtl : TextDirection.ltr;

  pw.TextDirection get _pdfTextDirection =>
      _isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;

  _CertificateCopy get _copy {
    if (_isGerman) return _CertificateCopy.german();
    return _CertificateCopy.english();
  }

  String get _scoreLabel {
    return '${widget.result.score}% (${widget.result.correctAnswers}/${widget.result.totalQuestions})';
  }

  String get _examDateLabel {
    final parsed = DateTime.tryParse(widget.result.submittedAt)?.toLocal();
    if (parsed == null) return widget.result.submittedAtLabel;
    return _formatDate(parsed);
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _safeFileName(String value) {
    return value
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final isFinal = widget.result.type == 'level_final';

    return Directionality(
      textDirection: _textDirection,
      child: Scaffold(
        appBar: AppBar(title: Text(_copy.screenTitle)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: .35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _certificatePreview(),
                ),
              ),
              const SizedBox(height: 18),
              if (isFinal)
                FilledButton.icon(
                  onPressed: _isExporting ? null : _exportPdf,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    _isExporting ? _copy.downloading : _copy.download,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    _copy.finalOnlyNotice,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CertificateCopy {
  final String screenTitle;
  final String certificateTitle;
  final String download;
  final String downloading;
  final String finalOnlyNotice;
  final String saveError;
  final String Function(String path) savedMessage;

  const _CertificateCopy({
    required this.screenTitle,
    required this.certificateTitle,
    required this.download,
    required this.downloading,
    required this.finalOnlyNotice,
    required this.saveError,
    required this.savedMessage,
  });

  factory _CertificateCopy.english() {
    return _CertificateCopy(
      screenTitle: 'Student Certificate',
      certificateTitle: 'Level Completion Certificate',
      download: 'Download PDF Certificate',
      downloading: 'Downloading...',
      finalOnlyNotice:
          'Official certificates are available only for final level exams.',
      saveError: 'Could not save the certificate. Please try again.',
      savedMessage: (path) => 'Certificate saved to $path',
    );
  }

  factory _CertificateCopy.german() {
    return _CertificateCopy(
      screenTitle: 'Studentenzertifikat',
      certificateTitle: 'Zertifikat zum Levelabschluss',
      download: 'PDF-Zertifikat herunterladen',
      downloading: 'Wird heruntergeladen...',
      finalOnlyNotice:
          'Offizielle Zertifikate sind nur fur Abschlussprufungen verfugbar.',
      saveError: 'Das Zertifikat konnte nicht gespeichert werden.',
      savedMessage: (path) => 'Zertifikat gespeichert unter $path',
    );
  }
}
