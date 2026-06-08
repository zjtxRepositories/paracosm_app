import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/pages/chat/detail/file_download_state.dart';

void main() {
  test('sanitizes file names for local storage', () {
    expect(sanitizeChatFileName(' report?.pdf '), 'report_.pdf');
    expect(sanitizeChatFileName('a/b:c*d"e<f>g|h.txt'), 'a_b_c_d_e_f_g_h.txt');
    expect(sanitizeChatFileName(''), 'downloaded_file');
    expect(sanitizeChatFileName(null), 'downloaded_file');
  });

  test('builds stable private download path', () {
    final first = buildChatFileDownloadPath(
      directoryPath: '/tmp/chat_files',
      messageId: 'msg-1',
      remoteUrl: 'https://example.com/a.pdf',
      fileName: 'a.pdf',
    );
    final second = buildChatFileDownloadPath(
      directoryPath: '/tmp/chat_files/',
      messageId: 'msg-1',
      remoteUrl: 'https://example.com/a.pdf',
      fileName: 'a.pdf',
    );

    expect(first, second);
    expect(first, startsWith('/tmp/chat_files/'));
    expect(first, endsWith('-a.pdf'));
  });

  test('detects usable local file paths', () {
    expect(isUsableLocalFilePath('/tmp/a.pdf'), isTrue);
    expect(isUsableLocalFilePath('file:///tmp/a.pdf'), isTrue);
    expect(isUsableLocalFilePath('https://example.com/a.pdf'), isFalse);
    expect(isUsableLocalFilePath(''), isFalse);
    expect(isUsableLocalFilePath(null), isFalse);
  });

  test('maps download progress to 0-100 percent', () {
    expect(mapFileDownloadProgress(received: 0, total: 100), 0);
    expect(mapFileDownloadProgress(received: 50, total: 100), 50);
    expect(mapFileDownloadProgress(received: 100, total: 100), 100);
    expect(mapFileDownloadProgress(received: 120, total: 100), 100);
    expect(mapFileDownloadProgress(received: -10, total: 100), 0);
    expect(mapFileDownloadProgress(received: 10, total: 0), 0);
  });
}
