import 'dart:convert';

enum RoomType {
  dao,    // 1 DAO
  club,   // 2 Club
  key,    // 3 Key 群
  all     // 全部类型，仅用于筛选，不用于存储
}

extension RoomTypeExtension on RoomType {
  /// 展示名称（可替换为多语言）
  String get displayName {
    switch (this) {
      case RoomType.dao:
        return 'DAO';
      case RoomType.club:
        return 'Club';
      case RoomType.key:
        return 'Key';
      case RoomType.all:
        return 'all';
    }
  }

  /// 群聊专用 int → ChatType（不含 friend / all）
  static RoomType fromInt(int value) {
    switch (value) {
      case 1:
        return RoomType.dao;
      case 2:
        return RoomType.club;
      case 3:
        return RoomType.key;
      default:
        return RoomType.dao; // 默认值
    }
  }

  /// 群聊专用 ChatType → int（不含 friend / all）
  static int toInt(RoomType type) {
    switch (type) {
      case RoomType.dao:
        return 1;
      case RoomType.club:
        return 2;
      case RoomType.key:
        return 3;
      default:
        return 0;
    }
  }
}
class CommunityModel {
  final String? id;
  final String? jid;
  final int? roomType;
  final int? communityType;

  final CommunityParam? communityParam;

  final String? name;
  final String? avatarUrl;
  final int? memberNum;
  final String? desc;
  final List<String>? tags;

  const CommunityModel({
    this.id,
    this.jid,
    this.roomType,
    this.communityType,
    this.communityParam,
    this.name,
    this.avatarUrl,
    this.memberNum,
    this.desc,
    this.tags,
  });
  String get displayAddress {
    if (communityParam == null){
      return jid ?? '';
    }
    if (communityParam!.isNative) {
      return communityParam!.symbol;
    }

    return communityParam!.tokenAddress ?? '--';
  }

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    final communityParamValue = json['communityParam'];

    CommunityParam? communityParam;

    if (communityParamValue != null &&
        communityParamValue.toString().isNotEmpty) {
      if (communityParamValue is String) {
        communityParam = CommunityParam.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(communityParamValue),
          ),
        );
      } else if (communityParamValue is Map) {
        communityParam = CommunityParam.fromJson(
          Map<String, dynamic>.from(communityParamValue),
        );
      }
    }

    return CommunityModel(
      id: json['id'],
      jid: json['jid'],
      roomType: json['roomType'],
      communityType: json['communityType'],
      communityParam: communityParam,
      name: json['name'],
      avatarUrl: json['avatarUrl'],
      memberNum: json['memberNum'],
      desc: json['desc'],
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jid': jid,
      'roomType': roomType,
      'communityType': communityType,
      'communityParam': communityParam?.toJson(),
      'name': name,
      'avatarUrl': avatarUrl,
      'memberNum': memberNum,
      'desc': desc,
      'tags': tags,
    };
  }
}
class CommunityParam {
  final String symbol;
  final int chainId;

  final String? tokenAddress;
  final bool isNative;

  final String? groupId; // ⭐ 可以放，但只是绑定信息

  const CommunityParam({
    required this.symbol,
    required this.chainId,
    this.tokenAddress,
    required this.isNative,
    this.groupId,
  });


  Map<String, dynamic> toJson() => {
    "symbol": symbol,
    "chainId": chainId,
    "tokenAddress": tokenAddress,
    "isNative": isNative,
    "groupId": groupId,
  };

  factory CommunityParam.fromJson(Map<String, dynamic> json) {
    return CommunityParam(
      symbol: json["symbol"] ?? "",
      chainId: json["chainId"] ?? 0,
      tokenAddress: json["tokenAddress"],
      isNative: json["isNative"] ?? false,
      groupId: json["groupId"],
    );
  }
}

