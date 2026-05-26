import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioEmbedWidget extends StatefulWidget {
  final String html;

  const AudioEmbedWidget({super.key, required this.html});

  @override
  State<AudioEmbedWidget> createState() => _AudioEmbedWidgetState();
}

class _AudioEmbedWidgetState extends State<AudioEmbedWidget> {
  late final AudioPlayer _player;
  late String _source;
  PlayerState _state = PlayerState.stopped;
  bool _loading = false;
  String _error = '';

  bool get _isPlaying => _state == PlayerState.playing;
  bool get _canPlay => _source.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _source = _extractSource(widget.html);
    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _state = state;
        if (state == PlayerState.playing || state == PlayerState.paused) {
          _loading = false;
        }
      });
    });
    if (_canPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  @override
  void didUpdateWidget(covariant AudioEmbedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSource = _extractSource(widget.html);
    if (nextSource != _source) {
      _source = nextSource;
      _error = '';
      _player.stop();
      if (_canPlay) {
        _play();
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (!_canPlay) {
      setState(() => _error = 'رابط الصوت غير صالح');
      return;
    }

    if (_isPlaying) {
      await _player.pause();
      return;
    }

    await _play();
  }

  Future<void> _play() async {
    if (!_canPlay) {
      setState(() => _error = 'رابط الصوت غير صالح');
      return;
    }

    debugPrint('AUDIO URL = $_source');
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      await _player.play(UrlSource(_source));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _isGoogleDriveDownload(_source)
            ? 'هذا الرابط غير مناسب للتشغيل المباشر، يُفضل رفع الملف على Supabase Storage أو Firebase Storage.'
            : 'رابط الصوت غير صالح';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              IconButton.filled(
                onPressed: _loading ? null : _toggle,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  foregroundColor: Colors.white,
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _loading
                      ? 'جاري تحميل الصوت...'
                      : _isPlaying
                      ? 'الصوت يعمل الآن'
                      : 'تشغيل الصوت',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _error,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFFFFB4AB),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _extractSource(String html) {
  return RegExp(r'src\s*=\s*"([^"]+)"').firstMatch(html)?.group(1)?.trim() ??
      '';
}

bool _isGoogleDriveDownload(String value) {
  final url = value.toLowerCase();
  return url.contains('drive.google.com') && url.contains('export=download');
}
