class AppVersionModel {
  const AppVersionModel({
    required this.isUpdate,
    required this.version,
    required this.download,
    required this.updateContent,
    required this.time,
    required this.isForceUpdate,
  });

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      isUpdate: _asBool(json['isUpdate']),
      version: _asString(json['version']),
      download: _asString(json['download']),
      updateContent: _asString(json['updateContent']),
      time: _asInt(json['time']),
      isForceUpdate: _asInt(json['isForceUpdate']),
    );
  }

  final bool isUpdate;
  final String version;
  final String download;
  final String updateContent;
  final int time;
  final int isForceUpdate;

  bool get isForce => isForceUpdate == 1;

  bool get canUpdate => isUpdate && download.trim().isNotEmpty;

  static String _asString(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is bool) {
      return value ? 1 : 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == 'yes') {
        return 1;
      }
      if (normalized == 'false' || normalized == 'no') {
        return 0;
      }
      return int.tryParse(normalized) ?? 0;
    }
    return 0;
  }
}
