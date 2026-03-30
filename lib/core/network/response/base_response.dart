class BaseResponse<T> {
  final int code;
  final String message;
  final T? data;

  BaseResponse({
    required this.code,
    required this.message,
    this.data,
  });

  factory BaseResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic json)? fromJsonT,
      ) {
    return BaseResponse<T>(
      code: json["resultCode"] ?? -1,
      message: json["message"] ?? "",
      data: fromJsonT != null && json["data"] != null
          ? fromJsonT(json["data"])
          : json["data"],
    );
  }
}