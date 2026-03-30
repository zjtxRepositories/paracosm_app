import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';

/// 群组信息页面
class GroupInformationPage extends StatefulWidget {
  final String groupName;

  const GroupInformationPage({
    super.key,
    required this.groupName,
  });

  @override
  State<GroupInformationPage> createState() => _GroupInformationPageState();
}

class _GroupInformationPageState extends State<GroupInformationPage> {
  late TextEditingController _nameController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.groupName);
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: false,
      child: Stack(
        children: [
          // 1. 全屏背景图 (完全对齐 wallet_setup_page.dart L30-35)
          Positioned.fill(
            child: Image.asset(
              'assets/images/chat/group-bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. 页面内容 (完全对齐 wallet_setup_page.dart L38-42 结构)
          Positioned.fill(
            child: Column(
              children: [
                // 自定义导航栏
                SafeArea(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Image.asset('assets/images/common/back-icon.png',width: 32,height: 32,)
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.chatGroupInfoTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // 占位保持居中
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 180),

                // 白色圆角内容区
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      clipBehavior: Clip.none, // 允许头像超出容器
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 群头像预览 (叠加在内容区上方)
                          Transform.translate(
                            offset: const Offset(0, -60),
                            child: _buildGroupAvatar(),
                          ),

                          // Group name
                          Text(
                            AppLocalizations.of(context)!.chatGroupInfoName,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.grey600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.grey900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Group note
                          Text(
                            AppLocalizations.of(context)!.chatGroupInfoNote,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.grey600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.grey200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                TextField(
                                  controller: _noteController,
                                  maxLines: 5,
                                  maxLength: 80,
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!.chatGroupInfoHint,
                                    hintStyle: AppTextStyles.body.copyWith(color: AppColors.grey400),
                                    border: InputBorder.none,
                                    counterText: '',
                                  ),
                                  onChanged: (val) => setState(() {}), // 刷新字数统计
                                  style: AppTextStyles.body.copyWith(color: AppColors.grey900),
                                ),
                                Text(
                                  '${_noteController.text.length}/80',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.grey400),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Save Button
                          AppButton(
                            text: AppLocalizations.of(context)!.commonSave,
                            onPressed: () {
                              // TODO: 实现保存逻辑
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupAvatar() {
    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          4,
          (index) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset('assets/images/chat/avatar.png', fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
