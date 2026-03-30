import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_localizations_keys.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_modal.dart';

/// 好友申请页面
class FriendRequestPage extends StatefulWidget {
  const FriendRequestPage({super.key});

  @override
  State<FriendRequestPage> createState() => _FriendRequestPageState();
}

class _FriendRequestPageState extends State<FriendRequestPage> {
  // 模拟待处理数据
  final List<Map<String, String>> _newRequests = [
    {
      'name': 'Jesseny',
      'avatar': 'assets/images/chat/avatar.png',
      'msg': 'I\'m asking you to add me',
    },
    {
      'name': 'Wade Warren',
      'avatar': 'assets/images/chat/avatar.png',
      'msg': 'Hello~',
    },
    {
      'name': 'Wade Warren',
      'avatar': 'assets/images/chat/avatar.png',
      'msg': 'This is a long example of ..',
    },
  ];

  // 模拟已处理数据
  final List<Map<String, dynamic>> _processedRequests = [
    {
      'name': 'Leslie Alexander',
      'avatar': 'assets/images/chat/avatar.png',
      'msg': 'This is a long example of ..',
      'status': 'Added',
      'isSent': false,
    },
    {
      'name': 'Jenny Wilson',
      'avatar': 'assets/images/chat/avatar.png',
      'msg': 'This is a long example of ..',
      'status': 'Added',
      'isSent': true,
    },
    {
      'name': 'Jerome Bell',
      'avatar': 'assets/images/chat/avatar.png',
      'msg': 'This is a long example of ..',
      'status': 'Expired',
      'isSent': false,
    },
    {
      'name': 'Marvin McKinney',
      'avatar': 'assets/images/chat/avatar.png',
      'msg': 'This is a long example of ..',
      'status': 'Expired',
      'isSent': true,
    },
    {
      'name': 'Eleanor Pena',
      'avatar': 'assets/images/chat/avatar.png',
      'msg': 'This is a long example of ..',
      'status': 'Rejected',
      'isSent': false,
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 初始化时将硬编码的状态值替换为对应的国际化字符串
    for (var req in _processedRequests) {
      if (req['status'] == 'Added') {
        req['status'] = AppLocalizations.of(context)!.chatRequestStatusAdded;
      } else if (req['status'] == 'Expired') {
        req['status'] = AppLocalizations.of(context)!.chatRequestStatusExpired;
      } else if (req['status'] == 'Rejected') {
        req['status'] = AppLocalizations.of(context)!.chatRequestStatusRejected;
      }
    }
  }

  /// 显示同意确认弹窗
  void _showAgreeConfirmModal(Map<String, String> req) {
    AppModal.show(
      context,
      title: req['name']!,
      titleWidget: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              req['avatar']!,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            req['name']!,
            style: AppTextStyles.h2.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.grey900,
            ),
          ),
        ],
      ),
      confirmText: AppLocalizations.of(context)!.chatRequestAgree,
      confirmColor: const Color(0xFF12B76A),
      cancelText: AppLocalizations.of(context)!.chatRequestReject,
      cancelColor: AppColors.error,
      cancelTextColor: Colors.white,
      confirmWidth: 161,
      cancelWidth: 161,
      child: _AgreeRequestInputWrapper(
        initialText: req['msg']!,
      ),
      onConfirm: () {
        setState(() {
          _newRequests.remove(req);
          _processedRequests.insert(0, {
            ...req,
            'status': AppLocalizations.of(context)!.chatRequestStatusAdded,
            'isSent': false,
          });
        });
        Navigator.pop(context);
      },
      onCancel: () {
        setState(() {
          _newRequests.remove(req);
          _processedRequests.insert(0, {
            ...req,
            'status': AppLocalizations.of(context)!.chatRequestStatusRejected,
            'isSent': false,
          });
        });
        Navigator.pop(context);
      },
    );
  }

  /// 显示拒绝确认弹窗
  void _showRejectConfirmModal(Map<String, String> req) {
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.chatRequestHint,
      description: AppLocalizations.of(context)!.chatRequestRejectConfirm,
      confirmText: AppLocalizations.of(context)!.chatRequestSure,
      cancelText: AppLocalizations.of(context)!.chatRequestCancel,
      confirmWidth: 161,
      cancelWidth: 161,
      cancelBorder: const BorderSide(color: AppColors.grey300),
      icon: Image.asset(
        'assets/images/wallet/bell-icon.png',
        width: 120,
        height: 120,
        fit: BoxFit.contain,
      ),
      onConfirm: () {
        setState(() {
          _newRequests.remove(req);
          _processedRequests.insert(0, {
            ...req,
            'status': AppLocalizations.of(context)!.chatRequestStatusRejected,
            'isSent': false,
          });
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: AppLocalizations.of(context)!.chatFriendRequest,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 16),
          _buildSectionTitle(AppLocalizations.of(context)!.chatRequestNew),
          ..._newRequests.map((req) => _buildNewRequestItem(req)),
          const SizedBox(height: 24),
          _buildSectionTitle(AppLocalizations.of(context)!.chatRequestProcessed),
          ..._processedRequests.map((req) => _buildProcessedItem(req)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.grey400,
          fontSize: 12,
        ),
      ),
    );
  }

  /// 构建待处理申请项
  Widget _buildNewRequestItem(Map<String, String> req) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(req['avatar']!, width: 44, height: 44),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.grey100, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req['name']!,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.grey900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          req['msg']!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showRejectConfirmModal(req),
                    child: Image.asset(
                      'assets/images/chat/refuse.png',
                      width: 40,
                      height: 26,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showAgreeConfirmModal(req),
                    child: Image.asset(
                      'assets/images/chat/agree.png',
                      width: 40,
                      height: 26,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建已处理申请项
  Widget _buildProcessedItem(Map<String, dynamic> req) {
    final String status = req['status'] ?? '';
    final String statusText = switch (status) {
      'Added' => AppLocalizations.of(context)!.chatRequestStatusAdded,
      'Expired' => AppLocalizations.of(context)!.chatRequestStatusExpired,
      'Rejected' => AppLocalizations.of(context)!.chatRequestStatusRejected,
      _ => status,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(req['avatar']!, width: 44, height: 44),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.grey100, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req['name']!,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.grey900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          req['msg']!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      if (req['isSent'] == true) ...[
                        Image.asset(
                          'assets/images/chat/go.png',
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        statusText,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 同意好友申请输入框包装组件，管理自身状态
class _AgreeRequestInputWrapper extends StatefulWidget {
  final String initialText;

  const _AgreeRequestInputWrapper({required this.initialText});

  @override
  State<_AgreeRequestInputWrapper> createState() => _AgreeRequestInputWrapperState();
}

class _AgreeRequestInputWrapperState extends State<_AgreeRequestInputWrapper> {
  late TextEditingController controller;
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AgreeRequestInput(
      controller: controller,
      focusNode: focusNode,
    );
  }
}

/// 同意好友申请输入框组件
class _AgreeRequestInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _AgreeRequestInput({
    required this.controller,
    required this.focusNode,
  });

  @override
  State<_AgreeRequestInput> createState() => _AgreeRequestInputState();
}

class _AgreeRequestInputState extends State<_AgreeRequestInput> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocused = widget.focusNode.hasFocus;
    final bool hasText = widget.controller.text.isNotEmpty;

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? AppColors.grey900 : Colors.transparent,
          width: isFocused ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        maxLines: null,
        onChanged: (value) => setState(() {}),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: AppTextStyles.body.copyWith(
          fontSize: 14,
          color: (isFocused || hasText) ? AppColors.grey900 : AppColors.grey400,
          fontWeight: (isFocused || hasText) ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }
}
