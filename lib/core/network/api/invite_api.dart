import 'package:dio/dio.dart';
import 'package:paracosm/core/network/interceptor/api_exception.dart';
import 'package:paracosm/modules/invite/model/invite_models.dart';
import 'package:paracosm/modules/invite/service/invite_access_token_manager.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';

class InviteApi {
  InviteApi({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: inviteBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
              responseType: ResponseType.json,
              contentType: 'application/json',
            ),
          );

  static const profilePath = '/invite/profile.json';
  static const inviteBaseUrl = 'http://8.210.9.90:9100';
  static const childrenPath = '/invite/children.json';
  static const parentPath = '/invite/parent.json';
  static const resolvePath = '/invite/resolve.json';
  static const bindPath = '/invite/bind.json';

  final Dio _dio;

  Future<InviteProfile> getProfile() async {
    final response = await _post(profilePath, auth: true);
    final data = response['data'];
    return InviteProfile.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : null,
    );
  }

  Future<InviteChildrenPage> getChildren({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _post(
      childrenPath,
      auth: true,
      body: {'page': page, 'pageSize': pageSize},
    );
    return InviteChildrenPage.fromResponse(response);
  }

  Future<InviteUser?> getParent() async {
    final response = await _post(parentPath, auth: true);
    final data = response['data'];
    if (data is! Map) return null;
    final parent = data['parent'];
    return parent is Map
        ? InviteUser.fromJson(Map<String, dynamic>.from(parent))
        : null;
  }

  Future<InviteResolveResult> resolve(String code) async {
    final response = await _post(resolvePath, body: {'code': code.trim()});
    final data = response['data'];
    return InviteResolveResult.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : null,
    );
  }

  Future<InviteBindResult> bind(String inviteCode) async {
    final response = await _post(
      bindPath,
      auth: true,
      body: {'inviteCode': inviteCode.trim()},
    );
    final data = response['data'];
    return InviteBindResult.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : null,
    );
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final payload = <String, dynamic>{...?body};
    if (auth) {
      final token = await InviteAccessTokenManager.ensureAccessToken();
      if (token.isEmpty) {
        throw ApiException(
          40101,
          AppLocalizations.currentText('invite_login_required'),
        );
      }
      payload['accessToken'] = token;
    }

    final response = await _dio.post<Object?>(path, data: payload);
    final decoded = response.data;
    if (decoded is! Map) {
      throw ApiException(-1, AppLocalizations.currentText('common_data_error'));
    }

    final data = Map<String, dynamic>.from(decoded);
    final code = _intValue(data['resultCode'], fallback: -1);
    if (code != 1) {
      throw ApiException(
        code,
        data['message']?.toString() ??
            AppLocalizations.currentText('network_error'),
      );
    }
    return data;
  }
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}
