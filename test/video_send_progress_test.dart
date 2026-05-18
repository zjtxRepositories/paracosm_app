import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/pages/chat/detail/video_send_progress.dart';

void main() {
  test('maps compression progress to 0-40 percent', () {
    expect(mapVideoCompressionProgress(0), 0);
    expect(mapVideoCompressionProgress(50), 20);
    expect(mapVideoCompressionProgress(100), 40);
    expect(mapVideoCompressionProgress(120), 40);
  });

  test('maps combined upload progress to 40-90 percent', () {
    expect(
      mapVideoUploadProgress(
        videoSent: 0,
        videoTotal: 100,
        coverSent: 0,
        coverTotal: 100,
      ),
      40,
    );
    expect(
      mapVideoUploadProgress(
        videoSent: 100,
        videoTotal: 100,
        coverSent: 0,
        coverTotal: 100,
      ),
      65,
    );
    expect(
      mapVideoUploadProgress(
        videoSent: 100,
        videoTotal: 100,
        coverSent: 100,
        coverTotal: 100,
      ),
      90,
    );
  });

  test('maps IM send progress to 90-99 percent', () {
    expect(mapVideoImSendProgress(0), 90);
    expect(mapVideoImSendProgress(50), 94);
    expect(mapVideoImSendProgress(100), 99);
  });

  test('normalizes and deduplicates progress notifications', () {
    expect(normalizeVideoSendProgress(-10), 0);
    expect(normalizeVideoSendProgress(120), 100);

    expect(
      shouldNotifyVideoSendProgress(previousProgress: 40, nextProgress: 40),
      isFalse,
    );
    expect(
      shouldNotifyVideoSendProgress(previousProgress: 40, nextProgress: 41),
      isTrue,
    );
    expect(
      shouldNotifyVideoSendProgress(
        previousProgress: 40,
        nextProgress: 40,
        statusChanged: true,
      ),
      isTrue,
    );
  });

  test('matches pending video by remote url', () {
    expect(
      isSamePendingVideoRemote(
        pendingRemote: ' http://dl.zjtx9.top/a.mp4 ',
        incomingRemote: 'http://dl.zjtx9.top/a.mp4',
      ),
      isTrue,
    );
    expect(
      isSamePendingVideoRemote(
        pendingRemote: 'http://dl.zjtx9.top/a.mp4',
        incomingRemote: 'http://dl.zjtx9.top/b.mp4',
      ),
      isFalse,
    );
    expect(
      isSamePendingVideoRemote(
        pendingRemote: null,
        incomingRemote: 'http://dl.zjtx9.top/a.mp4',
      ),
      isFalse,
    );
  });
}
