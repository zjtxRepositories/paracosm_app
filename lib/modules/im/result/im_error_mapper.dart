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

      case 25460:
        return AppLocalizations.currentText('im_error_already_friend');

      case 25461:
        return AppLocalizations.currentText('im_error_friend_waiting_approval');

      case 25462:
        return AppLocalizations.currentText(
          'im_error_in_target_user_blacklist',
        );

      case 25463:
        return AppLocalizations.currentText(
          'im_error_not_in_target_user_whitelist',
        );

      case 25464:
        return AppLocalizations.currentText(
          'im_error_target_user_in_my_blacklist',
        );

      case 25465:
        return AppLocalizations.currentText(
          'im_error_target_user_not_in_my_whitelist',
        );

      case 25466:
        return AppLocalizations.currentText(
          'im_error_friend_request_not_exist_or_expired',
        );

      case 25467:
        return AppLocalizations.currentText(
          'im_error_my_friend_count_exceeded',
        );

      case 25468:
        return AppLocalizations.currentText(
          'im_error_target_friend_count_exceeded',
        );

      case 25469:
        return AppLocalizations.currentText('im_error_not_friend_relation');

      case 25470:
        return AppLocalizations.currentText(
          'im_error_friend_ext_fields_exceeded',
        );

      case 25471:
        return AppLocalizations.currentText('im_error_friend_not_allowed');

      case 25472:
        return AppLocalizations.currentText('im_error_friend_not_found');

      case 25473:
        return AppLocalizations.currentText('im_error_cannot_add_self');

      case 23424:
        return AppLocalizations.currentText('im_error_network');

      default:
        return AppLocalizations.currentText('im_error_unknown', {'code': code});
    }
  }
}
