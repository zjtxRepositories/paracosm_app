import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/base/app_page.dart';

/// 群组简介编辑页面
class GroupIntroductionPage extends StatefulWidget {
  final String initialIntroduction;

  const GroupIntroductionPage({
    super.key,
    this.initialIntroduction = '',
  });

  @override
  State<GroupIntroductionPage> createState() => _GroupIntroductionPageState();
}

class _GroupIntroductionPageState extends State<GroupIntroductionPage> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialIntroduction);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && !_isEditing) {
      setState(() {
        _isEditing = true;
      });
    }
  }

  void _handleAction() {
    if (_isEditing) {
      // 完成逻辑
      _focusNode.unfocus();
      setState(() {
        _isEditing = false;
      });
      // TODO: 保存简介到服务器
    } else {
      // 编辑逻辑
      _focusNode.requestFocus();
      setState(() {
        _isEditing = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: AppLocalizations.of(context)!.chatSettingIntroduction,
      backgroundColor: Colors.white,
      showNavBorder: true,
      headerActions: [
        TextButton(
          onPressed: _handleAction,
          child: Text(
            _isEditing ? AppLocalizations.of(context)!.commonDone : AppLocalizations.of(context)!.commonEdit,
            style: AppTextStyles.body.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: null,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.chatGroupInfoHint,
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.grey400,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          style: AppTextStyles.body.copyWith(
            color: AppColors.grey900,
          ),
        ),
      ),
    );
  }
}
