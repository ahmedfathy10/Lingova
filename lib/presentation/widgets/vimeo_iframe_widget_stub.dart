import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'vimeo_embed_url.dart';

class VimeoIframeWidget extends StatefulWidget {
  final String url;

  const VimeoIframeWidget({super.key, required this.url});

  @override
  State<VimeoIframeWidget> createState() => _VimeoIframeWidgetState();
}

class _VimeoIframeWidgetState extends State<VimeoIframeWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadRequest(Uri.parse(vimeoEmbedUrl(widget.url)));
  }

  @override
  void didUpdateWidget(covariant VimeoIframeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller.loadRequest(Uri.parse(vimeoEmbedUrl(widget.url)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
