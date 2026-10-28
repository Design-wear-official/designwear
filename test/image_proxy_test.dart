import 'package:cached_network_image/cached_network_image.dart';
import 'package:designwear/presentation/widgets/image_proxy.dart';
import 'package:designwear/presentation/widgets/safe_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash = 'f5068b271caf192bc1f36743f9433766aa941525';
const _sanity =
    'https://cdn.sanity.io/images/jh7llku7/production/$_hash-1080x1440.jpg';

void main() {
  tearDown(() => ImageProxy.configure(null));

  group('ImageProxy', () {
    test(
      'is off by default: URLs are used as they are (phones and desktop)',
      () {
        expect(ImageProxy.enabled, isFalse);
        expect(ImageProxy.resolve(_sanity), _sanity);
      },
    );

    test('on web, CDN photos go through the API with a size', () {
      ImageProxy.configure('http://localhost:8787/');
      expect(
        ImageProxy.resolve(_sanity, width: 600),
        'http://localhost:8787/v1/img/cdn.sanity.io/jh7llku7/production/$_hash-1080x1440.jpg?w=600&q=80&auto=format',
      );
    });

    test('clamps absurd widths', () {
      ImageProxy.configure('https://api.example.com');
      expect(ImageProxy.resolve(_sanity, width: 99999), contains('w=2000'));
      expect(ImageProxy.resolve(_sanity, width: 1), contains('w=16'));
    });

    test('leaves everything that is not an images-CDN photo alone', () {
      ImageProxy.configure('https://api.example.com');
      for (final other in [
        'https://example.com/a.jpg',
        'http://cdn.sanity.io/images/jh7llku7/production/$_hash-1080x1440.jpg', // not https
        'https://cdn.sanity.io.evil.com/images/jh7llku7/production/$_hash-1080x1440.jpg',
        'https://cdn.sanity.io/files/jh7llku7/production/$_hash-1080x1440.jpg',
        'https://cdn.sanity.io/images/jh7llku7/production/not-a-hash.jpg',
        'assets/images/tshirt_white.png',
      ]) {
        expect(ImageProxy.resolve(other), other, reason: other);
      }
    });
  });

  testWidgets('SafeNetworkImage loads through the API when the proxy is on', (
    tester,
  ) async {
    ImageProxy.configure('http://localhost:8787');
    await tester.pumpWidget(
      const MaterialApp(home: SafeNetworkImage(imageUrl: _sanity, width: 200)),
    );
    // Web uses Image.network, the phone/desktop build uses CachedNetworkImage; the test
    // machine is the latter. Either way the URL must be the API's.
    final cached = find.byType(CachedNetworkImage);
    final url = cached.evaluate().isNotEmpty
        ? tester.widget<CachedNetworkImage>(cached).imageUrl
        : ((tester.widget<Image>(find.byType(Image)).image) as NetworkImage)
              .url;
    expect(url, startsWith('http://localhost:8787/v1/img/cdn.sanity.io/'));
    expect(url, contains('w=400'), reason: 'twice the displayed width');
  });
}
