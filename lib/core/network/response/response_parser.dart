import '../interceptor/api_exception.dart';
import 'base_response.dart';

class ResponseParser {

  static T parse<T>(
      BaseResponse<T> response,
      ) {

    if (response.code == 1) {
      if (response.data == null) {
        throw Exception("数据为空");
      }
      return response.data as T;
    }

    if (response.code == 401) {
      throw ApiException(401, "Token expired");
    }

    throw ApiException(
        response.code, response.message);
  }

}