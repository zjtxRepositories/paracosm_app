import 'package:paracosm/widgets/base/app_localizations.dart';

class ImErrorMapper {
  static String message(int code) {
    switch (code) {
      case 0:
        return AppLocalizations.currentText('im_error_success');

      case 25101:
        return AppLocalizations.currentText('im_error_user_not_found');

      case 25102:
        return AppLocalizations.currentText('im_error_already_friend');

      case 25103:
        return AppLocalizations.currentText('im_error_friend_rejected');

      case 25104:
        return AppLocalizations.currentText('im_error_in_blacklist');

      case 23424:
        return AppLocalizations.currentText('im_error_network');

      default:
        return AppLocalizations.currentText('im_error_unknown', {'code': code});
    }
  }
}
