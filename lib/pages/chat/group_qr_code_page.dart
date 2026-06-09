import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:paracosm/core/models/group_model.dart';
import 'package:paracosm/core/models/group_member_model.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/group_avatar_widget.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class GroupQrCodePage extends StatefulWidget {
  const GroupQrCodePage({super.key, required this.group});

  final GroupModel group;

  @override
  State<GroupQrCodePage> createState() => _GroupQrCodePageState();
}

class _GroupQrCodePageState extends State<GroupQrCodePage> {
  late final DateTime _expiresAt;
  String _groupName = '';
  List<GroupMemberModel> _members = [];

  @override
  void initState() {
    super.initState();
    _expiresAt = DateTime.now().add(const Duration(days: 7));
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    final name = await widget.group.name;
    final members = await widget.group.members;
    if (!mounted) return;
    setState(() {
      _groupName = name;
      _members = members;
    });
  }

  String get _qrContent {
    return jsonEncode({
      'type': 'group',
      'groupId': widget.group.info.groupId ?? '',
      'expiresAt': _expiresAt.millisecondsSinceEpoch,
      'members': _members
          .map(
            (member) => {
              'userId': member.item.userId,
              'name': member.item.name,
              'nickname': member.item.nickname,
              'portraitUri': member.item.portraitUri,
              'role': member.item.role?.index,
            },
          )
          .toList(),
    });
  }

  String get _expiredText {
    final date =
        '${_expiresAt.year}.${_twoDigits(_expiresAt.month)}.${_twoDigits(_expiresAt.day)}';
    return AppLocalizations.of(context)!.groupQrCodeExpiresAt(date);
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final groupId = widget.group.info.groupId ?? '';
    final name = _groupName.isEmpty
        ? widget.group.displayName ?? ''
        : _groupName;

    return AppPage(
      showNav: true,
      title: AppLocalizations.of(context)!.groupQrCodeTitle,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/wallet/grid-bg.png',
              fit: BoxFit.cover,
            ),
          ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        GroupAvatarWidget(
                          groupId: groupId,
                          portraitUri: widget.group.info.portraitUri,
                          size: 48,
                          initialMembers: _members
                              .map((member) => member.item)
                              .toList(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.h2.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.groupQrCodeScanToJoin,
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 12,
                                  color: AppColors.grey400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: AppColors.grey100),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: PrettyQrView.data(
                          data: _qrContent,
                          decoration: const PrettyQrDecoration(
                            shape: PrettyQrSmoothSymbol(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Text(
                      _expiredText,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.grey400,
                        fontSize: 13,
                      ),
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
}
