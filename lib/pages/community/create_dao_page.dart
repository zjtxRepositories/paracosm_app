import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/models/group_model.dart';
import 'package:paracosm/core/network/api/create_community_api.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../core/models/community_model.dart';
import '../../core/models/conversation_model.dart';
import '../../core/models/custom_message_model.dart';
import '../../modules/im/manager/im_conversation_manager.dart';
import '../../modules/im/manager/im_group_manager.dart';
import '../../modules/im/message/base/im_message.dart';
import '../../modules/im/message/send/im_sender.dart';
import '../../widgets/common/app_loading.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/app_toast.dart';

/// 创建 DAO 页面
class CreateDaoPage extends StatefulWidget {
  final TokenModel token;
  const CreateDaoPage({super.key, required this.token});

  @override
  State<CreateDaoPage> createState() => _CreateDaoPageState();
}

class _CreateDaoPageState extends State<CreateDaoPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final int _maxDescriptionLength = 80;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _nameController.text = widget.token.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createCommunity() async {
    final asset = widget.token;
    String jid = asset.address;
    final name = _nameController.text;
    final desc = _descriptionController.text;
    final avatarUrl = asset.logo;
    final roomType = 1;
    final communityType = 1;
    if (jid.isEmpty) {
      jid = "${asset.symbol.toLowerCase()}_${asset.chainId}_native";
    }
    final groupId = generateGroupId(GroupType.dao);
    final param = CommunityParam(
      symbol: asset.symbol,
      chainId: asset.chainId,
      tokenAddress: asset.address,
      isNative: asset.address.isEmpty,
      groupId: groupId,
    );
    AppLoading.show();
    final isCreate = await CreateCommunityApi.create(
      jid,
      name,
      desc,
      asset.address.isNotEmpty ? avatarUrl : '',
      roomType,
      communityType,
      jsonEncode(param.toJson()),
    );
    if (!isCreate) {
      AppLoading.dismiss();
      AppToast.show(AppLocalizations.of(context)!.commonCreateGroupFailed);
      return;
    }
    final groupInfo = RCIMIWGroupInfo.create(
        groupId: groupId,
        groupName: name,
        portraitUri: avatarUrl,
        introduction: desc,
        invitePermission: RCIMIWGroupOperationPermission.everyone,
        joinPermission: RCIMIWGroupJoinPermission.free
    );
    final result = await ImGroupManager().createByGroupInfo(groupInfo, []);
    if (result == null) {
      AppLoading.dismiss();
      AppToast.show(AppLocalizations.of(context)!.commonCreateGroupFailed);
      return;
    }
    final message = CustomMessage(
      targetId: groupId,
      customMessageType: CustomMessageType.createDao,
      conversationType: RCIMIWConversationType.group,
    );
    final isSend = await ImSender.instance.send(message: message);
    AppLoading.dismiss();
    if (!isSend) return;
    final conversation = await ImConversationManager().getConversation(
      type: RCIMIWConversationType.group,
      targetId: groupId,
    );
    if (conversation == null) return;
    final model = ConversationModel(info: conversation);
    await ConversationResolver().resolve(model);
    AppToast.show(AppLocalizations.of(context)!.commonCreatedSuccess);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPage(
      title: l10n.communityCreateDaoTitle,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 头像上传区域
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none, // 允许子组件超出 Stack 边界
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECEFF0),
                            borderRadius: BorderRadius.circular(34),
                          ),
                          child: Center(
                            child:AppNetworkImage(
                              url: widget.token.logo,
                              width: 65,
                              height: 65,
                              fit: BoxFit.contain,

                            ),
                          ),
                        ),
                        Positioned(
                          right: -6, // 调整偏移量，确保不被遮挡
                          bottom: -6,
                          child: Image.asset(
                            'assets/images/community/photo.png',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 名称输入
                  Text(
                    l10n.communityCreateName,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.grey600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        border: InputBorder.none,
                      ),
                      style: AppTextStyles.h2.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 描述输入
                  Text(
                    l10n.communityCreateDaoDescription,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.grey600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 126,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        TextField(
                          controller: _descriptionController,
                          maxLines: null,
                          maxLength: _maxDescriptionLength,
                          onChanged: (value) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: l10n.communityCreateDaoDescHint,
                            hintStyle: AppTextStyles.body.copyWith(
                              color: AppColors.grey400,
                              fontSize: 14,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            border: InputBorder.none,
                            counterText: '', // 隐藏默认计数器，使用自定义
                          ),
                          style: AppTextStyles.body.copyWith(
                            fontSize: 14,
                            color: AppColors.grey900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 4,
                          child: Text(
                            '${_descriptionController.text.length}/$_maxDescriptionLength',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 12,
                              color: AppColors.grey400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 说明文字
                  Text(
                    l10n.communityCreateDaoIntro,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: AppColors.grey400,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 确认按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: AppButton(
              text: l10n.commonConfirm,
              onPressed: _createCommunity,
            ),
          ),
        ],
      ),
    );
  }
}
