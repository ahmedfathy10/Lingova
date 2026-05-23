// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class AudioEmbedWidget extends StatefulWidget {
  final String html;

  const AudioEmbedWidget({super.key, required this.html});

  @override
  State<AudioEmbedWidget> createState() => _AudioEmbedWidgetState();
}

class _AudioEmbedWidgetState extends State<AudioEmbedWidget> {
  late final String _viewType;
  late html.IFrameElement _iframeElement;

  @override
  void initState() {
    super.initState();
    _viewType = 'audio-embed-${DateTime.now().microsecondsSinceEpoch}';
    _iframeElement = _createIframe(widget.html);
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return _iframeElement;
    });
  }

  @override
  void didUpdateWidget(covariant AudioEmbedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      _iframeElement.srcdoc = widget.html;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}

html.IFrameElement _createIframe(String source) {
  return html.IFrameElement()
    ..srcdoc = source
    ..style.border = '0'
    ..style.display = 'block'
    ..style.width = '100%'
    ..style.height = '100%'
    ..allow = 'autoplay; encrypted-media; fullscreen'
    ..allowFullscreen = true;
}
