import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';

/// 创建俱乐部页面
class CreateClubPage extends StatefulWidget {
  const CreateClubPage({super.key});

  @override
  State<CreateClubPage> createState() => _CreateClubPageState();
}

class _CreateClubPageState extends State<CreateClubPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final int _maxDescriptionLength = 80;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPage(
      title: l10n.communityCreateClubTitle,
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/chat/avatar.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.token, size: 60, color: AppColors.grey400),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -10, // 调整偏移量，确保不被遮挡
                          bottom: -10,
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
                    l10n.communityCreateNameNft,
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
                      decoration: InputDecoration(
                        hintText: l10n.communityCreateClubNameHint,
                        hintStyle: AppTextStyles.body.copyWith(
                          color: AppColors.grey400,
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        border: InputBorder.none,
                      ),
                      style: AppTextStyles.h2.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 新增: Choose the NFT to stake
                  GestureDetector(
                    onTap: () {
                      // TODO: 选择 NFT
                    },
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.communityCreateClubStakeNft,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.grey400,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.grey400,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 描述输入
                  Text(
                    l10n.communityCreateClubDescription,
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
                            hintText: l10n.communityCreateClubDescHint,
                            hintStyle: AppTextStyles.body.copyWith(
                              color: AppColors.grey400,
                              fontSize: 14,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    l10n.communityCreateClubIntro,
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
              onPressed: () {
                // TODO: 提交逻辑
              },
            ),
          ),
        ],
      ),
    );
  }
}
