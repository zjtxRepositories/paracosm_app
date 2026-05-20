import 'package:paracosm/widgets/base/app_localizations.dart';

import '../interceptor/api_exception.dart';
import 'base_response.dart';

class ResponseParser {
  static T parse<T>(BaseResponse<T> response) {
    if (response.code == 1) {
      if (response.data == null) {
        throw Exception(AppLocalizations.currentText('common_data_empty'));
      }
      return response.data as T;
    }

    if (response.code == 401) {
      throw ApiException(401, "Token expired");
    }

    throw ApiException(response.code, response.message);
  }
}
