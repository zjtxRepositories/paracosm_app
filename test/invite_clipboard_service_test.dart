import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/modules/invite/service/invite_clipboard_service.dart';

void main() {
  group('InviteClipboardService', () {
    test('extracts invite code from plain clipboard code', () {
      expect(
        InviteClipboardService.extractInviteCode(' ABCD1234 '),
        'ABCD1234',
      );
    });

    test('extracts invite code from invite landing links', () {
      expect(
        InviteClipboardService.extractInviteCode(
          'https://invite.zjtxy.top/invite/REPLACE_WITH_DOWNLOAD_PAGE_URL?code=ABCD1234',
        ),
        'ABCD1234',
      );
    });

    test('extracts invite code from paracosm scheme links', () {
      expect(
        InviteClipboardService.extractInviteCode(
          'paracosm:///invite?code=ABCD1234',
        ),
        'ABCD1234',
      );
    });

    test('ignores ordinary clipboard text', () {
      expect(InviteClipboardService.extractInviteCode('hello world'), isNull);
      expect(InviteClipboardService.extractInviteCode('paracosm'), isNull);
    });
  });
}
