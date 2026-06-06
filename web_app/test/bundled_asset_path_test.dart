import 'package:flutter_test/flutter_test.dart';
import 'package:tellus_demo/ui/core/assets/bundled_asset_path.dart';

void main() {
  group('resolveBundledAssetPath', () {
    test('assets/ prefix is kept as-is', () {
      expect(
        resolveBundledAssetPath(
          'assets/images/templates/dam/example-thumbnail.png',
        ),
        'assets/images/templates/dam/example-thumbnail.png',
      );
    });

    test('images/ prefix gets assets/ prepended once', () {
      expect(
        resolveBundledAssetPath('images/templates/port/foo.png'),
        'assets/images/templates/port/foo.png',
      );
    });

    test('does not double-prefix assets/', () {
      final path = resolveBundledAssetPath('assets/images/sar/joganji_palsar2_l21.png');
      expect(path.startsWith('assets/assets/'), isFalse);
    });
  });

  group('isBundledAssetUrl', () {
    test('detects bundled paths', () {
      expect(isBundledAssetUrl('assets/images/disaster/noto_2024_before.png'), isTrue);
      expect(isBundledAssetUrl('images/sar/foo.png'), isTrue);
    });

    test('rejects remote URLs', () {
      expect(isBundledAssetUrl('https://example.com/thumb.png'), isFalse);
    });
  });
}
