import 'package:dio/dio.dart' hide LogInterceptor;

import '../config/network_config.dart';
import '../interceptor/auth_interceptor.dart';
import '../interceptor/error_interceptor.dart';
import '../interceptor/log_interceptor.dart';
import '../response/base_response.dart';
import '../response/response_parser.dart';

class HttpClient {
  static final HttpClient _instance =
  HttpClient._internal();

  factory HttpClient() => _instance;

  late Dio dio;

  HttpClient._internal() {
    BaseOptions options = BaseOptions(
      baseUrl: NetworkConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
      contentType: "application/json",
    );

    dio = Dio(options);

    /// 拦截器
    dio.interceptors.add(AuthInterceptor());
    dio.interceptors.add(ErrorInterceptor());
    dio.interceptors.add(LogInterceptor());
  }

  /// 更新 BaseUrl
  void updateBaseUrl(String url) {
    dio.options.baseUrl = url;
  }

  /// ================== 核心请求（泛型版） ==================
  Future<T> request<T>(
      String path, {
        String method = "GET",
        Map<String, dynamic>? params,
        dynamic data,
        CancelToken? cancelToken,
        T Function(dynamic json)? fromJson,
      }) async {
    try {
      final response = await dio.request(
        path,
        queryParameters: params,
        data: data,
        options: Options(method: method),
        cancelToken: cancelToken,
      );

      /// 1. 转 BaseResponse
      final baseResponse = BaseResponse<T>.fromJson(
        response.data,
        fromJson,
      );

      /// 2. 统一解析（处理 code / error）
      return ResponseParser.parse(baseResponse);
    } on DioException catch (e) {
      /// Dio 层错误（网络错误等）
      throw Exception(_handleDioError(e));
    } catch (e) {
      rethrow;
    }
  }

  /// ================== 快捷方法 ==================

  Future<T> get<T>(
      String path, {
        Map<String, dynamic>? params,
        T Function(dynamic json)? fromJson,
      }) {
    return request<T>(
      path,
      params: params,
      fromJson: fromJson,
    );
  }

  Future<T> post<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? params,
        T Function(dynamic json)? fromJson,
      }) {
    return request<T>(
      path,
      method: "POST",
      data: data,
      params: params,
      fromJson: fromJson,
    );
  }

  Future<T> put<T>(
      String path, {
        dynamic data,
        T Function(dynamic json)? fromJson,
      }) {
    return request<T>(
      path,
      method: "PUT",
      data: data,
      fromJson: fromJson,
    );
  }

  Future<T> delete<T>(
      String path, {
        dynamic data,
        T Function(dynamic json)? fromJson,
      }) {
    return request<T>(
      path,
      method: "DELETE",
      data: data,
      fromJson: fromJson,
    );
  }

  /// ================== 错误处理 ==================
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return "连接超时";
      case DioExceptionType.sendTimeout:
        return "请求超时";
      case DioExceptionType.receiveTimeout:
        return "响应超时";
      case DioExceptionType.badResponse:
        return "服务器异常(${e.response?.statusCode})";
      case DioExceptionType.cancel:
        return "请求取消";
      case DioExceptionType.unknown:
      default:
        return "网络异常";
    }
  }
}