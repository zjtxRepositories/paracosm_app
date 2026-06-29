import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/core/models/group_member_model.dart';
import 'package:paracosm/core/network/api/red_packet_api.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/im/listener/group_state_center.dart';
import 'package:paracosm/pages/chat/chat_session_args.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_toast.dart';
import 'package:paracosm/widgets/modals/dapp_modals.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

import '../../modules/im/manager/im_engine_manager.dart';
import '../../widgets/chat/remove_member_modal.dart';

enum RedPacketSendType { lucky, normal, exclusive }

class ChatRedPacketPage extends StatefulWidget {
  const ChatRedPacketPage({
    super.key,
    required this.sessionArgs,
    this.initialMemberCount,
  });

  final ChatSessionArgs? sessionArgs;
  final int? initialMemberCount;

  @override
  State<ChatRedPacketPage> createState() => _ChatRedPacketPageState();
}

class _ChatRedPacketPageState extends State<ChatRedPacketPage> {
  static const Color _headerColor = Color(0xFFF1473E);
  static const Color _pageColor = Color(0xFFF8F4F2);
  static const Color _fieldColor = Colors.white;
  static const Color _modalButtonColor = _headerColor;
  static const Color _buttonDisabledColor = Color(0xFF983D36);
  static const Color _primaryTextColor = AppColors.grey900;
  static const Color _secondaryTextColor = AppColors.grey600;
  static const Color _hintTextColor = AppColors.grey500;
  static const double _formFontSize = 14;
  static const double _tabFontSize = 16;
  static const double _assistFontSize = 12;
  static const double _pageHorizontalPadding = 16;
  static const double _formTopSpacing = 0;
  static const double _assetToFieldSpacing = 18;
  static const double _fieldSpacing = 16;
  static const double _buttonTopSpacing = 80;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  late final TextEditingController _blessingController;

  RedPacketSendType _type = RedPacketSendType.lucky;
  RedPacketAsset? _selectedAsset;
  RedPacketBalance? _selectedBalance;
  List<RedPacketAsset> _assets = const [];
  Map<String, RedPacketBalance> _balances = const {};
  String? _exclusiveRecipientUserId;
  String? _exclusiveRecipientName;
  String? _exclusiveRecipientAvatar;
  List<RCIMIWGroupMemberInfo> members = [];
  int _memberCount = 0;
  bool _isSending = false;

  bool get _isGroupSession =>
      widget.sessionArgs?.conversationType == RCIMIWConversationType.group ||
      widget.sessionArgs?.isGroup == true;

  @override
  void initState() {
    super.initState();
    _blessingController = TextEditingController(
      text: AppLocalizations.currentText('chat_red_packet_default_blessing'),
    );
    _memberCount = widget.initialMemberCount ?? 0;
    _loadMemberCount();
    unawaited(_loadAssetsAndBalances());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _countController.dispose();
    _blessingController.dispose();
    super.dispose();
  }

  Future<void> _loadMemberCount() async {
    final args = widget.sessionArgs;
    if (args == null) return;
    if (!_isGroupSession) {
      setState(() => _memberCount = 1);
      return;
    }

    try {
      final result = await GroupStateCenter().getGroupMembers(args.targetId);
      if (!mounted) return;
      setState(() {
        members = result;
        _memberCount = result.length;
        _clearMissingExclusiveRecipient();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _memberCount = 0);
    }
  }

  Future<void> _loadAssetsAndBalances() async {
    try {
      final results = await Future.wait([
        RedPacketApi.assetList(),
        RedPacketApi.queryBalances(),
      ]);
      if (!mounted) return;
      final assets = results[0] as List<RedPacketAsset>;
      final balances = {
        for (final item in results[1] as List<RedPacketBalance>)
          item.assetId: item,
      };
      setState(() {
        _assets = assets;
        _balances = balances;
        if (_selectedAsset == null && assets.isNotEmpty) {
          _selectedAsset = assets.first;
          _selectedBalance = balances[assets.first.assetId];
        } else if (_selectedAsset != null) {
          _selectedBalance = balances[_selectedAsset!.assetId];
        }
      });
    } catch (e) {
      debugPrint('Load red packet assets failed: $e');
    }
  }

  void _showTokenSelector() {
    if (_assets.isEmpty) {
      AppToast.show(
        AppLocalizations.currentText('chat_red_packet_select_token'),
      );
      unawaited(_loadAssetsAndBalances());
      return;
    }

    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.chatRedPacketSelectToken,
      confirmText: null,
      onConfirm: () {},
      child: SizedBox(
        height: 360,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _assets.length,
          separatorBuilder: (_, _) => Divider(color: AppColors.grey100),
          itemBuilder: (context, index) {
            final asset = _assets[index];
            final balance = _balances[asset.assetId];
            final selected = asset.assetId == _selectedAsset?.assetId;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                asset.symbol,
                style: AppTextStyles.h2.copyWith(
                  color: _primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.chatRedPacketAvailable(
                  '${balance?.display ?? '0'} ${asset.symbol}',
                ),
                style: AppTextStyles.body.copyWith(
                  color: _secondaryTextColor,
                  fontSize: 12,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check, color: _headerColor)
                  : null,
              onTap: () {
                setState(() {
                  _selectedAsset = asset;
                  _selectedBalance = balance;
                });
                context.pop();
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> showChooseUser() async {
    final l10n = AppLocalizations.of(context)!;
    final args = widget.sessionArgs;
    if (args == null) {
      AppToast.show(l10n.chatRedPacketMissingSession);
      return;
    }

    if (!_isGroupSession) {
      setState(() {
        _exclusiveRecipientUserId = args.targetId;
        _exclusiveRecipientName = args.name;
        _exclusiveRecipientAvatar = args.avatar;
      });
      return;
    }

    var sourceMembers = members;
    if (sourceMembers.isEmpty) {
      try {
        sourceMembers = await GroupStateCenter().getGroupMembers(args.targetId);
        if (!mounted) return;
        setState(() {
          members = sourceMembers;
          _memberCount = sourceMembers.length;
        });
      } catch (_) {
        return;
      }
    }

    final currentUserId = IMEngineManager().currentUserId ?? '';
    final memberList = sourceMembers
        .where((item) {
          final userId = item.userId ?? '';
          return userId.isNotEmpty && userId != currentUserId;
        })
        .map((item) => GroupMemberModel(item: item))
        .toList(growable: false);

    final result = await RemoveMemberModal.show(
      context,
      members: memberList,
      title: l10n.chatRedPacketSelectRecipient,
      defaultSelectedUserIds: _exclusiveRecipientUserId == null
          ? null
          : [_exclusiveRecipientUserId!],
      singleSelection: true,
    );
    final userId = result?.firstOrNull;
    if (userId == null || userId.isEmpty) return;

    final member = memberList
        .where((item) => item.item.userId == userId)
        .firstOrNull;
    if (!mounted) return;
    setState(() {
      _exclusiveRecipientUserId = userId;
      _exclusiveRecipientName = member?.name ?? userId;
      _exclusiveRecipientAvatar = member?.item.portraitUri;
    });
  }

  void _clearMissingExclusiveRecipient() {
    final userId = _exclusiveRecipientUserId;
    if (userId == null || userId.isEmpty || members.isEmpty) return;
    final exists = members.any((item) => item.userId == userId);
    if (!exists) {
      _exclusiveRecipientUserId = null;
      _exclusiveRecipientName = null;
      _exclusiveRecipientAvatar = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPage(
      title: l10n.chatRedPacketTitle,
      navBackgroundColor: _headerColor,
      titleColor: Colors.white,
      isAddBottomMargin: false,
      backgroundColor: _pageColor,
      backTheme: Brightness.dark,
      resizeToAvoidBottomInset: false,
      headerActions: [
        IconButton(
          onPressed: () {
            context.push(
              '/red-packet_record',
              extra: IMEngineManager().currentUserId,
            );
          },
          icon: const Icon(
            Icons.history_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(width: 8),
      ],
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: _pageColor)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 128,
            child: ClipPath(
              clipper: _RedPacketHeaderClipper(),
              child: Container(color: _headerColor),
            ),
          ),
          Positioned(
            top: 112,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(color: _pageColor),
          ),
          Column(
            children: [
              _buildTypeTabs(l10n),
              Expanded(child: _buildForm(l10n)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTabs(AppLocalizations l10n) {
    final items = [
      (RedPacketSendType.lucky, l10n.chatRedPacketLucky),
      (RedPacketSendType.normal, l10n.chatRedPacketNormal),
      (RedPacketSendType.exclusive, l10n.chatRedPacketExclusive),
    ];

    return SizedBox(
      height: 60,
      child: Row(
        children: items
            .map((item) {
              final active = _type == item.$1;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _type = item.$1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.$2,
                        style: AppTextStyles.h2.copyWith(
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          fontSize: _tabFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: active ? 34 : 0,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            _pageHorizontalPadding,
            _formTopSpacing,
            _pageHorizontalPadding,
            0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  _buildAssetCard(l10n),
                  const SizedBox(height: _assetToFieldSpacing),
                  ..._buildTypeFields(l10n),
                  const SizedBox(height: _fieldSpacing),
                  _buildBlessingInput(l10n),
                  const SizedBox(height: _buttonTopSpacing),
                  _buildSubmitButton(l10n),
                  const Spacer(),
                  const SizedBox(height: 20),
                  Text(
                    l10n.chatRedPacketRefundTip,
                    style: AppTextStyles.body.copyWith(
                      color: _secondaryTextColor,
                      fontSize: _assistFontSize,
                    ),
                  ),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildTypeFields(AppLocalizations l10n) {
    final amountInput = _buildInputRow(
      label: _type == RedPacketSendType.normal
          ? l10n.chatRedPacketSingleAmount
          : _type == RedPacketSendType.exclusive
          ? l10n.chatRedPacketAmount
          : l10n.chatRedPacketTotalAmount,
      controller: _amountController,
      hintText: l10n.chatRedPacketAvailable('0'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
    );

    switch (_type) {
      case RedPacketSendType.lucky:
        return [
          amountInput,
          const SizedBox(height: _fieldSpacing),
          _buildInputRow(
            label: l10n.chatRedPacketCount,
            controller: _countController,
            hintText: _countHint(l10n),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ];
      case RedPacketSendType.normal:
        return [
          _buildInputRow(
            label: l10n.chatRedPacketPeople,
            controller: _countController,
            hintText: _countHint(l10n),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: _fieldSpacing),
          amountInput,
        ];
      case RedPacketSendType.exclusive:
        return [
          _buildRecipientRow(l10n),
          const SizedBox(height: _fieldSpacing),
          amountInput,
        ];
    }
  }

  Widget _buildAssetCard(AppLocalizations l10n) {
    final asset = _selectedAsset;
    final balance = _selectedBalance;
    final hasToken = asset != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showTokenSelector,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: _fieldColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: _headerColor.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              l10n.chatRedPacketAsset,
              style: AppTextStyles.h2.copyWith(
                color: _primaryTextColor,
                fontSize: _formFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (hasToken) ...[
              Text(
                asset.symbol,
                style: AppTextStyles.h2.copyWith(
                  color: _primaryTextColor,
                  fontSize: _formFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.chatRedPacketAvailable(
                  '${balance?.display ?? '0'} ${asset.symbol}',
                ),
                style: AppTextStyles.body.copyWith(
                  color: _secondaryTextColor,
                  fontSize: _assistFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else
              Text(
                l10n.chatRedPacketSelectToken,
                style: AppTextStyles.h2.copyWith(
                  color: _hintTextColor,
                  fontSize: _formFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: AppColors.grey400, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientRow(AppLocalizations l10n) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: showChooseUser,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: _fieldColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              l10n.chatRedPacketSendTo,
              style: AppTextStyles.h2.copyWith(
                color: _primaryTextColor,
                fontSize: _formFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildRecipientAvatar(),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      _exclusiveRecipientUserId != null
                          ? _exclusiveRecipientName ??
                                _exclusiveRecipientUserId!
                          : l10n.chatRedPacketSelectRecipient,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h2.copyWith(
                        color: _exclusiveRecipientUserId != null
                            ? _primaryTextColor
                            : _hintTextColor,
                        fontSize: _formFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: AppColors.grey400, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientAvatar() {
    final userId = _exclusiveRecipientUserId;
    if (userId != null && userId.isNotEmpty) {
      return UserAvatarWidget(
        userId: userId,
        avatarUrl: _exclusiveRecipientAvatar,
        size: 28,
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Color(0xFFE5E5E5),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, color: AppColors.grey500, size: 18),
    );
  }

  Widget _buildInputRow({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
    required List<TextInputFormatter> inputFormatters,
  }) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: _fieldColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.h2.copyWith(
              color: _primaryTextColor,
              fontSize: _formFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              textAlign: TextAlign.right,
              cursorColor: _headerColor,
              style: AppTextStyles.h2.copyWith(
                color: _primaryTextColor,
                fontSize: _formFontSize,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.h2.copyWith(
                  color: _hintTextColor,
                  fontSize: _formFontSize,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlessingInput(AppLocalizations l10n) {
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      decoration: BoxDecoration(
        color: _fieldColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.chatRedPacketBlessing,
            style: AppTextStyles.h2.copyWith(
              color: _primaryTextColor,
              fontSize: _formFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _blessingController,
              maxLines: 1,
              cursorColor: _headerColor,
              style: AppTextStyles.h2.copyWith(
                color: _primaryTextColor,
                fontSize: _formFontSize,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AppLocalizations l10n) {
    final enabled = _canSubmit;
    return SizedBox(
      width: 220,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? () => _submit(l10n) : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _headerColor,
          disabledBackgroundColor: _buttonDisabledColor,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _buttonText(l10n),
                style: AppTextStyles.h2.copyWith(
                  color: enabled
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  String _countHint(AppLocalizations l10n) {
    if (_isGroupSession) {
      return l10n.chatRedPacketGroupCount(_memberCount);
    }
    return l10n.chatRedPacketSingleCount(1);
  }

  String _buttonText(AppLocalizations l10n) {
    if (_selectedAsset == null) {
      return l10n.chatRedPacketSelectToken;
    }
    if (_type == RedPacketSendType.exclusive &&
        (_exclusiveRecipientUserId == null ||
            _exclusiveRecipientUserId!.isEmpty)) {
      return l10n.chatRedPacketSelectRecipient;
    }
    if (_type != RedPacketSendType.exclusive &&
        _countController.text.trim().isEmpty) {
      return l10n.chatRedPacketEnterCount;
    }
    if (_amountController.text.trim().isEmpty) {
      return l10n.chatRedPacketEnterAmount;
    }
    return l10n.chatRedPacketSubmit;
  }

  bool get _canSubmit {
    if (_isSending || widget.sessionArgs == null) return false;
    if (_selectedAsset == null) return false;
    if (_type == RedPacketSendType.exclusive &&
        (_exclusiveRecipientUserId == null ||
            _exclusiveRecipientUserId!.isEmpty)) {
      return false;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return false;
    if (_type != RedPacketSendType.exclusive) {
      final count = int.tryParse(_countController.text.trim());
      if (count == null || count <= 0) return false;
      if (_isGroupSession && _memberCount > 0 && count > _memberCount) {
        return false;
      }
    }
    return true;
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final args = widget.sessionArgs;
    if (!_validateBeforeSubmit(l10n)) return;
    await _showGenerateRedPacketSheet(l10n);
    if (args == null || !mounted) return;
  }

  bool _validateBeforeSubmit(AppLocalizations l10n) {
    final args = widget.sessionArgs;
    if (args == null) {
      AppToast.show(l10n.chatRedPacketMissingSession);
      return false;
    }
    if (_selectedAsset == null) {
      AppToast.show(l10n.chatRedPacketSelectToken);
      return false;
    }

    if (_type == RedPacketSendType.exclusive &&
        (_exclusiveRecipientUserId == null ||
            _exclusiveRecipientUserId!.isEmpty)) {
      AppToast.show(l10n.chatRedPacketSelectRecipient);
      return false;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      AppToast.show(l10n.chatRedPacketInvalidAmount);
      return false;
    }

    if (_type != RedPacketSendType.exclusive) {
      final count = int.tryParse(_countController.text.trim());
      if (count == null || count <= 0) {
        AppToast.show(l10n.chatRedPacketInvalidCount);
        return false;
      }

      if (_isGroupSession && _memberCount > 0 && count > _memberCount) {
        AppToast.show(l10n.chatRedPacketCountOverGroup);
        return false;
      }
    }

    if (!_hasEnoughBalance()) {
      AppToast.show(l10n.profileTransferInsufficientBalance);
      return false;
    }

    return true;
  }

  Future<void> _showGenerateRedPacketSheet(AppLocalizations l10n) {
    final asset = _selectedAsset;
    if (asset == null) return Future.value();
    return AppModal.show(
      context,
      title: l10n.chatRedPacketGenerateTitle,
      confirmText: l10n.chatRedPacketSend,
      confirmColor: _modalButtonColor,
      contentPadding: true,
      closeButtonOnLeft: true,
      barrierColor: _headerColor.withValues(alpha: 0.18),
      onConfirm: () {
        Navigator.pop(context);
        unawaited(_confirmSignatureAndSend(l10n));
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 18, 32, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGenerateTokenHeader(asset),
            const SizedBox(height: 34),
            _buildGenerateInfoRow(
              label: l10n.chatRedPacketCount,
              value: _packetCountForSummary().toString(),
            ),
            const SizedBox(height: 24),
            _buildGenerateInfoRow(
              label: l10n.chatRedPacketMinerFee,
              value: _redPacketMinerFeeText(asset),
              showInfoIcon: true,
            ),
            const SizedBox(height: 24),
            _buildGenerateInfoRow(
              label: l10n.chatRedPacketPacketType,
              value: _typeLabel(l10n),
            ),
            const SizedBox(height: 24),
            _buildGenerateInfoRow(
              label: l10n.chatRedPacketBlessing,
              value: _greetingText(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignatureAndSend(AppLocalizations l10n) async {
    final args = widget.sessionArgs;
    final asset = _selectedAsset;
    if (args == null || asset == null || _isSending) return;

    RedPacketSignatureRequest signatureRequest;
    try {
      signatureRequest = RedPacketApi.prepareSendSignature(
        assetId: asset.assetId,
        amount: _requestAmount(asset),
        count: _packetCountForSummary(),
        mode: _redPacketModeValue,
        groupId: _isGroupSession ? args.targetId : null,
      );
    } catch (e) {
      debugPrint('Prepare red packet signature failed: $e');
      AppToast.show(l10n.chatRedPacketSendFailed);
      return;
    }

    final confirmed = await DappModals.showSignInfoModal(
      context,
      message: signatureRequest.message,
      address: signatureRequest.userId,
      host: 'RongCloud redSend',
      faviconUrl: '',
      walletLabel: AccountManager().currentWallet?.name,
    );
    if (confirmed != true || !mounted) return;

    await _sendRedPacket(l10n, signatureRequest: signatureRequest);
  }

  Widget _buildGenerateTokenHeader(RedPacketAsset asset) {
    final symbol = asset.symbol;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFF3C313),
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: Center(
            child: Text(
              symbol.characters.take(1).toString(),
              style: AppTextStyles.h1.copyWith(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${_totalAmountText()} $symbol',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.h1.copyWith(
            color: _primaryTextColor,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  String _redPacketMinerFeeText(RedPacketAsset asset) {
    // 发红包走中心化余额扣减，不触发用户侧链上交易；链上 Gas 由平台侧处理。
    return '0 ${_redPacketFeeSymbol(asset)}';
  }

  String _redPacketFeeSymbol(RedPacketAsset asset) {
    final assetPrefix = asset.assetId.split('-').first.toLowerCase();
    switch (assetPrefix) {
      case 'bsc':
        return 'BNB';
      case 'eth':
      case 'ethereum':
        return 'ETH';
      case 'polygon':
      case 'matic':
        return 'MATIC';
      case 'arb':
      case 'arbitrum':
      case 'op':
      case 'optimism':
      case 'base':
      case 'linea':
      case 'scroll':
      case 'blast':
        return 'ETH';
      case 'tron':
      case 'trx':
        return 'TRX';
      case 'sol':
      case 'solana':
        return 'SOL';
      case 'btc':
      case 'bitcoin':
        return 'BTC';
    }

    final wallet = AccountManager().currentWallet;
    for (final chain in wallet?.chains ?? const []) {
      final symbol = chain.symbol.trim();
      if (symbol.isNotEmpty &&
          asset.assetId.toLowerCase().contains(symbol.toLowerCase())) {
        return symbol;
      }
    }

    final currentSymbol = wallet?.currentChain?.symbol.trim();
    if (currentSymbol != null && currentSymbol.isNotEmpty) {
      return currentSymbol;
    }
    return 'BNB';
  }

  Widget _buildGenerateInfoRow({
    required String label,
    required String value,
    Color? valueColor,
    bool showInfoIcon = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: _secondaryTextColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (showInfoIcon) ...[
          const SizedBox(width: 8),
          Icon(Icons.info_outline, color: _secondaryTextColor, size: 16),
        ],
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppTextStyles.body.copyWith(
              color: valueColor ?? _secondaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendRedPacket(
    AppLocalizations l10n, {
    RedPacketSignatureRequest? signatureRequest,
  }) async {
    final args = widget.sessionArgs;
    final asset = _selectedAsset;
    if (args == null || asset == null) return;
    if (_isSending) return;

    setState(() => _isSending = true);
    final greeting = _greetingText(l10n);
    bool success = false;
    try {
      final count = _packetCountForSummary();
      final amount = _requestAmount(asset);
      await RedPacketApi.send(
        assetId: asset.assetId,
        amount: amount,
        count: count,
        mode: _redPacketModeValue,
        groupId: _isGroupSession ? args.targetId : null,
        to: _type == RedPacketSendType.exclusive || !_isGroupSession
            ? _exclusiveRecipientUserId ?? args.targetId
            : null,
        greeting: greeting,
        signatureRequest: signatureRequest,
      );
      success = true;
    } catch (e) {
      debugPrint('Send red packet failed: $e');
      success = false;
    }

    if (!mounted) return;
    setState(() => _isSending = false);
    if (success) {
      context.pop();
    } else {
      AppToast.show(l10n.chatRedPacketSendFailed);
    }
  }

  int _packetCountForSummary() {
    if (!_isGroupSession || _type == RedPacketSendType.exclusive) return 1;
    return int.tryParse(_countController.text.trim()) ?? 0;
  }

  String _requestAmount(RedPacketAsset asset) {
    return redPacketDecimalToUnits(
      _amountController.text.trim(),
      asset.decimals,
      multiplier: _isGroupSession && _type == RedPacketSendType.normal
          ? _packetCountForSummary()
          : 1,
    );
  }

  String _greetingText(AppLocalizations l10n) {
    final text = _blessingController.text.trim();
    return text.isEmpty ? l10n.chatRedPacketDefaultBlessing : text;
  }

  String _typeLabel(AppLocalizations l10n) {
    switch (_type) {
      case RedPacketSendType.lucky:
        return l10n.chatRedPacketLucky;
      case RedPacketSendType.normal:
        return l10n.chatRedPacketNormal;
      case RedPacketSendType.exclusive:
        return l10n.chatRedPacketExclusive;
    }
  }

  String _totalAmountText() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final total = _type == RedPacketSendType.normal
        ? amount * _packetCountForSummary()
        : amount;
    if (total <= 0) return '0';
    final fixed = total.toStringAsFixed(8);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  bool _hasEnoughBalance() {
    final asset = _selectedAsset;
    if (asset == null) return false;
    final available = BigInt.tryParse(_selectedBalance?.available ?? '0');
    if (available == null || available <= BigInt.zero) return false;
    try {
      final required = BigInt.parse(_requestAmount(asset));
      return available >= required;
    } catch (_) {
      return false;
    }
  }

  String get _redPacketModeValue {
    if (!_isGroupSession) return 'p2p';
    switch (_type) {
      case RedPacketSendType.lucky:
        return 'lucky';
      case RedPacketSendType.normal:
        return 'even';
      case RedPacketSendType.exclusive:
        return 'p2p';
    }
  }
}

class _RedPacketHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 42)
      ..cubicTo(
        size.width * 0.22,
        size.height - 24,
        size.width * 0.36,
        size.height,
        size.width * 0.5,
        size.height,
      )
      ..cubicTo(
        size.width * 0.64,
        size.height,
        size.width * 0.78,
        size.height - 24,
        size.width,
        size.height - 42,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
