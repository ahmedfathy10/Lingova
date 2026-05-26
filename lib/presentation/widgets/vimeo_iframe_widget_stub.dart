import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'vimeo_embed_url.dart';

class VimeoIframeWidget extends StatelessWidget {
  final String url;

  const VimeoIframeWidget({super.key, required this.url});

  Future<void> _openVideo() async {
    final uri = Uri.parse(vimeoEmbedUrl(url));
    await launchUrlString(uri.toString(), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openVideo,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(0),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 64,
              ),
              SizedBox(height: 8),
              Text(
                'اضغط لفتح الفيديو في مشغل خارجي',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
