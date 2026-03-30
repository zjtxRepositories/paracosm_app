import 'im_error_mapper.dart';

class ImResult<T> {
  final bool success;
  final int code;
  final String message;
  final T? data;

  const ImResult({
    required this.success,
    required this.code,
    required this.message,
    this.data,
  });

  /// =========================
  /// 成功
  /// =========================
  factory ImResult.success({T? data}) {
    return ImResult(
      success: true,
      code: 0,
      message: "success",
      data: data,
    );
  }

  /// =========================
  /// 失败
  /// =========================
  factory ImResult.error({
    required int code,
    String? message,
  }) {
    return ImResult(
      success: false,
      code: code,
      message: message ?? ImErrorMapper.message(code),
    );
  }

  /// 快捷判断
  bool get isSuccess => success;
}