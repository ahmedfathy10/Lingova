// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

import 'vimeo_embed_url.dart';

class VimeoIframeWidget extends StatefulWidget {
  final String url;

  const VimeoIframeWidget({super.key, required this.url});

  @override
  State<VimeoIframeWidget> createState() => _VimeoIframeWidgetState();
}

class _VimeoIframeWidgetState extends State<VimeoIframeWidget> {
  late final String _viewType;
  late html.IFrameElement _iframeElement;

  @override
  void initState() {
    super.initState();
    _viewType = 'vimeo-iframe-${widget.url.hashCode}';
    _iframeElement = _createIframe(vimeoEmbedUrl(widget.url));
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return _iframeElement;
    });
  }

  @override
  void didUpdateWidget(covariant VimeoIframeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _iframeElement.src = vimeoEmbedUrl(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}

html.IFrameElement _createIframe(String src) {
  final iframe = html.IFrameElement()
    ..src = src
    ..style.border = '0'
    ..style.display = 'block'
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.backgroundColor = 'black'
    ..allow = 'autoplay; fullscreen'
    ..allowFullscreen = true;

  return iframe;
}
