import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';

import '../../core/models/user_display_model.dart';
import '../../modules/im/listener/user_display_state_center.dart';
import '../../theme/app_colors.dart';
import '../../widgets/base/app_localizations.dart';
import '../../widgets/base/app_page.dart';

class RedPacketRecordPage extends StatefulWidget {
  const RedPacketRecordPage({super.key, required this.userId});

  final String userId;

  @override
  State<RedPacketRecordPage> createState() => _RedPacketRecordPageState();
}

class _RedPacketRecordPageState extends State<RedPacketRecordPage> {
  int _selectedIndex = 0;
  final List records = []; // 空数据 -> 展示你图的状态
  UserDisplayModel? _user;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    var user = await UserDisplayStateCenter().getUser(
      widget.userId,
    );
    setState(() {
      _user = user;
    });
  }
  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/chat');
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: false,
      isAddBottomMargin: false,
      backgroundColor: AppColors.white,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  InkWell(
                    onTap: _handleBack,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Image.asset(
                        'assets/images/common/back-icon.png',
                        width: 32,
                        height: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Center(child: _buildTopTab())),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildHeader(),
            const SizedBox(height: 14),
            Container(height: 10,color: AppColors.grey100),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _selectedIndex == 0
                  ? _buildReceived()
                  : _buildSent(),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Tab
  // =========================
  Widget _buildTopTab() {
    const tabs = ['收到', '发出'];

    return SizedBox(
      width: 180,
      height: 42,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.32)),
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final selected = _selectedIndex == index;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_selectedIndex == index) return;
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: selected ? AppColors.error : AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // =========================
  // Header（和你图一致）
  // =========================
  Widget _buildHeader() {
    final isReceived = _selectedIndex == 0;
    final summaryText = isReceived ? '共收到 0 个' : '共发出 0 个';

    return Column(
      children: [
        UserAvatarWidget(userId: _user?.userId,avatarUrl: _user?.avatar,size: 80),
        const SizedBox(height: 10),

        Text(
          _user?.name ?? '',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          summaryText,
          style: const TextStyle(color: AppColors.black, fontSize: 16),
        ),

        const SizedBox(height: 14),

        const Text(
          "\$0",
          style: TextStyle(
            color: Color(0xFFFFD54F),
            fontSize: 44,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // =========================
  // 收到
  // =========================
  Widget _buildReceived() {
    if (records.isEmpty) {
      return _buildEmpty();
    }
    return _buildList(records);
  }

  // =========================
  // 发出
  // =========================
  Widget _buildSent() {
    if (records.isEmpty) {
      return _buildEmpty();
    }
    return _buildList(records);
  }

  // =========================
  // 空状态（完全复刻你图）
  // =========================
  Widget _buildEmpty() {
    return SizedBox(height: 400,
        child: AppEmptyView(
          text: AppLocalizations.of(context)!.chatSearchNoData,
          bottomOffset: 0,
    ));
  }

  // =========================
  // list（有数据时）
  // =========================
  // =========================
  // list
  // =========================
  Widget _buildList(List records) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: records.length,
      itemBuilder: (_, i) {
        final item = records[i];
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.grey100)),
          ),
          child: Row(
            children: [
              const CircleAvatar(radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item["name"]),
                    const SizedBox(height: 4),
                    Text(
                      item["time"],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                item["amount"],
                style: const TextStyle(
                  color: Color(0xFFFF3B30),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const Color _white70 = Color(0xB3FFFFFF);
const Color _white38 = Color(0x61FFFFFF);
