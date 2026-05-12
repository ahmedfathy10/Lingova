String vimeoEmbedUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) {
    return url;
  }

  final host = uri.host.toLowerCase();
  if (!host.contains('vimeo.com')) {
    return url;
  }

  final videoId = _extractVimeoId(uri);
  if (videoId == null) {
    return url;
  }

  final queryParameters = <String, String>{
    'autoplay': '0',
    'title': '0',
    'byline': '0',
    'portrait': '0',
  };

  final privateHash = _extractPrivateHash(uri);
  if (privateHash != null) {
    queryParameters['h'] = privateHash;
  }

  return Uri.https(
    'player.vimeo.com',
    '/video/$videoId',
    queryParameters,
  ).toString();
}

String? _extractVimeoId(Uri uri) {
  final segments = uri.pathSegments
      .where((segment) => segment.trim().isNotEmpty)
      .toList();
  if (segments.isEmpty) {
    return null;
  }

  if (segments.length >= 2 && segments[0].toLowerCase() == 'video') {
    return _numericSegment(segments[1]);
  }

  for (final segment in segments) {
    final videoId = _numericSegment(segment);
    if (videoId != null) {
      return videoId;
    }
  }

  return null;
}

String? _extractPrivateHash(Uri uri) {
  final queryHash = uri.queryParameters['h'];
  if (queryHash != null && queryHash.trim().isNotEmpty) {
    return queryHash.trim();
  }

  final segments = uri.pathSegments
      .where((segment) => segment.trim().isNotEmpty)
      .toList();
  final videoIndex = segments.indexWhere(
    (segment) => _numericSegment(segment) != null,
  );
  if (videoIndex >= 0 && videoIndex + 1 < segments.length) {
    final hash = segments[videoIndex + 1].trim();
    if (hash.isNotEmpty && !hash.contains('/')) {
      return hash;
    }
  }

  return null;
}

String? _numericSegment(String value) {
  final trimmed = value.trim();
  if (RegExp(r'^\d+$').hasMatch(trimmed)) {
    return trimmed;
  }
  return null;
}
