import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:paracosm/core/models/user_model.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../modules/im/manager/im_engine_manager.dart';
import '../../modules/im/manager/im_user_manager.dart';
import '../network/api/get_uer_info_api.dart';
import 'im_user_profile_resolver.dart';

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

  String get tokenAddress {
    return communityParam?.tokenAddress ?? '';
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
class CommunityPostPageModel {
  CommunityPostPageModel({
    required this.pageCount,
    required this.pageData,
  });

  final int pageCount;

  final List<CommunityPostModel> pageData;

  factory CommunityPostPageModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return CommunityPostPageModel(
      pageCount: json['pageCount'] is int
          ? json['pageCount']
          : int.tryParse(
        json['pageCount'].toString(),
      ) ??
          0,

      pageData: (json['pageData'] as List<dynamic>? ?? [])
          .map(
            (e) => CommunityPostModel.fromJson(
          e as Map<String, dynamic>,
        ),
      )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pageCount': pageCount,
      'pageData': pageData
          .map((e) => e.toJson())
          .toList(),
    };
  }

  bool get hasData => pageData.isNotEmpty;

  bool get isEmpty => pageData.isEmpty;
}
class CommunityPostModel {
  CommunityPostModel({
    required this.id,
    required this.nickname,
    required this.roomId,
    required this.text,
    required this.time,
    required this.typeNum,
    required this.userId,
  });

  final String id;

  /// 发布人昵称
  final String nickname;

  /// 社区/房间 ID
  final String roomId;

  /// 动态内容
  final String text;

  /// 秒级时间戳
  final int time;

  /// 动态类型
  final int typeNum;

  /// 用户 ID
  final int userId;

  UserModel? user;

  factory CommunityPostModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return CommunityPostModel(
      id: json['id']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      time: json['time'] is int
          ? json['time']
          : int.tryParse(
        json['time'].toString(),
      ) ??
          0,
      typeNum: json['typeNum'] is int
          ? json['typeNum']
          : int.tryParse(
        json['typeNum'].toString(),
      ) ??
          0,
      userId: json['userId'] is int
          ? json['userId']
          : int.tryParse(
        json['userId'].toString(),
      ) ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'roomId': roomId,
      'text': text,
      'time': time,
      'typeNum': typeNum,
      'userId': userId,
    };
  }

  /// 发布时间
  DateTime get dateTime {
    return DateTime.fromMillisecondsSinceEpoch(
      time * 1000,
    );
  }

  /// 是否文本动态
  bool get isTextPost => typeNum == 0;
}


class CommunityResolver {
  final ImUserManager _manager = ImUserManager();

  /// 内存缓存
  final Map<String, UserModel> _cache = {};

  Future<void> resolve(List<CommunityPostModel> models) async {
    if (models.isEmpty) return;

    try {
      /// 1. 收集 socialId
      final socialUserIds = models
          .map((e) => e.userId.toString())
          .toSet()
          .toList();

      /// 2. 过滤缓存
      final needLoadIds = socialUserIds
          .where((e) => !_cache.containsKey(e))
          .toList();

      /// 3. 获取业务用户
      final userInfos =
      await GetUerInfoApi.getList(needLoadIds);

      /// 4. 直接交给 IM resolver（关键优化点🔥）
      final imResolver = IMUserProfileResolver(_manager);

      final profileMap =
      await imResolver.resolveFromSocialUsers(
        userInfos: userInfos,
        currentUserId: IMEngineManager().currentUserId,
      );

      /// 5. 只做缓存 + model 回填
      for (final item in userInfos) {
        final imId = item.account;
        final profile = profileMap[imId];

        if (profile != null) {
          _cache[item.userId] =
              UserModel(profile: profile);
        }
      }

      for (final model in models) {
        model.user = _cache[model.userId];
      }
    } catch (e) {
      debugPrint("MomentsResolver resolve error: $e");
    }
  }

  void clearCache() {
    _cache.clear();
  }
}