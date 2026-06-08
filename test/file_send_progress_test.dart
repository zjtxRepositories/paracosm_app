import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/pages/chat/detail/file_send_progress.dart';

void main() {
  test('maps file upload progress to 0-90 percent', () {
    expect(mapFileUploadProgress(sent: 0, total: 100), 0);
    expect(mapFileUploadProgress(sent: 50, total: 100), 45);
    expect(mapFileUploadProgress(sent: 100, total: 100), 90);
    expect(mapFileUploadProgress(sent: 120, total: 100), 90);
    expect(mapFileUploadProgress(sent: -10, total: 100), 0);
  });

  test('keeps unknown upload total at zero percent', () {
    expect(mapFileUploadProgress(sent: 50, total: 0), 0);
    expect(mapFileUploadProgress(sent: 50, total: -1), 0);
  });

  test('maps IM send progress to 90-99 percent', () {
    expect(mapFileImSendProgress(0), 90);
    expect(mapFileImSendProgress(50), 94);
    expect(mapFileImSendProgress(100), 99);
    expect(mapFileImSendProgress(120), 99);
    expect(mapFileImSendProgress(-10), 90);
  });

  test('normalizes and deduplicates progress notifications', () {
    expect(normalizeFileSendProgress(-10), 0);
    expect(normalizeFileSendProgress(120), 100);

    expect(
      shouldNotifyFileSendProgress(previousProgress: 45, nextProgress: 45),
      isFalse,
    );
    expect(
      shouldNotifyFileSendProgress(previousProgress: 45, nextProgress: 46),
      isTrue,
    );
    expect(
      shouldNotifyFileSendProgress(
        previousProgress: 45,
        nextProgress: 45,
        statusChanged: true,
      ),
      isTrue,
    );
  });

  test('matches pending file by remote url', () {
    expect(
      isSamePendingFileRemote(
        pendingRemote: ' http://dl.zjtx9.top/a.pdf ',
        incomingRemote: 'http://dl.zjtx9.top/a.pdf',
      ),
      isTrue,
    );
    expect(
      isSamePendingFileRemote(
        pendingRemote: 'http://dl.zjtx9.top/a.pdf',
        incomingRemote: 'http://dl.zjtx9.top/b.pdf',
      ),
      isFalse,
    );
    expect(
      isSamePendingFileRemote(
        pendingRemote: null,
        incomingRemote: 'http://dl.zjtx9.top/a.pdf',
      ),
      isFalse,
    );
  });
}
