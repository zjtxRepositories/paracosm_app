import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/core/models/social_media_model.dart';

void main() {
  group('SocialMediaModel.previewUrl', () {
    test('uses url for image media', () {
      final media = SocialMediaModel(
        'https://example.com/image.jpg',
        0,
        'https://example.com/cover.jpg',
        0,
        100,
        100,
      );

      expect(media.previewUrl, 'https://example.com/image.jpg');
    });

    test('uses cover for video media', () {
      final media = SocialMediaModel(
        'https://example.com/video.mp4',
        1,
        'https://example.com/video-cover.jpg',
        0,
        100,
        100,
      );

      expect(media.previewUrl, 'https://example.com/video-cover.jpg');
    });

    test('falls back to url when video cover is empty', () {
      final media = SocialMediaModel(
        'https://example.com/video.mp4',
        1,
        '',
        0,
        100,
        100,
      );

      expect(media.previewUrl, 'https://example.com/video.mp4');
    });
  });

  group('SocialMediaModel.isVideo', () {
    test('distinguishes video from image media', () {
      final image = SocialMediaModel('', 0, '', 0, null, null);
      final video = SocialMediaModel('', 1, '', 0, null, null);

      expect(image.isVideo, isFalse);
      expect(video.isVideo, isTrue);
    });
  });
}
