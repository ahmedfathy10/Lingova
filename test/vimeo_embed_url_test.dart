import 'package:flutter_test/flutter_test.dart';
import 'package:lingova_app/presentation/widgets/vimeo_embed_url.dart';

void main() {
  group('vimeoEmbedUrl', () {
    test('converts a regular Vimeo URL to a player URL', () {
      expect(
        vimeoEmbedUrl('https://vimeo.com/123456789'),
        'https://player.vimeo.com/video/123456789?autoplay=0&title=0&byline=0&portrait=0',
      );
    });

    test('preserves private Vimeo hash from query string', () {
      expect(
        vimeoEmbedUrl('https://player.vimeo.com/video/123456789?h=abc123'),
        'https://player.vimeo.com/video/123456789?autoplay=0&title=0&byline=0&portrait=0&h=abc123',
      );
    });

    test('preserves private Vimeo hash from path', () {
      expect(
        vimeoEmbedUrl('https://vimeo.com/123456789/abc123'),
        'https://player.vimeo.com/video/123456789?autoplay=0&title=0&byline=0&portrait=0&h=abc123',
      );
    });
  });
}
