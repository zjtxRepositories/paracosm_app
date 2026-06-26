import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';

import '../../core/models/user_display_model.dart';
import '../../modules/im/listener/user_display_state_center.dart';
import '../../modules/im/manager/im_engine_manager.dart';
import '../../modules/im/message/base/im_message.dart';
import '../../widgets/base/app_localizations.dart';

class RedPacketDetailPage extends StatefulWidget {
  const RedPacketDetailPage({super.key, required this.userId, required this.data});
  final String userId;
  final RedPacketData data;

  @override
  State<RedPacketDetailPage> createState() => _RedPacketDetailPageState();
}

class _RedPacketDetailPageState extends State<RedPacketDetailPage> {
  final double headerHeight = 180;
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

  @override
  Widget build(BuildContext context) {
    final records = [
      {"name": "京", "time": "2026-06-25 17:09:08", "amount": "0.147 BOX"},
      {"name": "广州阿华", "time": "2026-06-25 17:09:08", "amount": "0.298 BOX"},
      {"name": "你猜", "time": "2026-06-25 17:09:08", "amount": "0.265 BOX"},
      {"name": "岁月安然", "time": "2026-06-25 17:09:07", "amount": "0.075 BOX"},
    ];
    final l10n = AppLocalizations.of(context)!;

    final greeting = widget.data.greeting.trim().isNotEmpty
        ? widget.data.greeting.trim()
        : l10n.chatRedPacketDefaultBlessing;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Stack(
        children: [
          Positioned(
            top: headerHeight-40,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 100),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                   Text(
                    _user?.name ?? '',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(greeting, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),
                  const Text(
                    "手慢了，已被领完",
                    style: TextStyle(
                      color: Color(0xFFFFB300),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 20),
                  Container(height: 10,color: AppColors.grey100),

                  const SizedBox(height: 20),

                  _buildTitle(records.length),

                  const SizedBox(height: 20),

                  Container(height: 1,color: AppColors.grey100),

                  Expanded(child: _buildList(records)),
                ],
              ),
            ),
          ),
          
          SizedBox(
            height: headerHeight,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    "assets/images/chat/red_packet/top_icon.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
              ],
            ),
          ),
          Positioned(
            top: headerHeight - 30,
            left: 0,
            right: 0,
            child: Center(
              child: UserAvatarWidget(userId: _user?.userId,avatarUrl: _user?.avatar,size: 72),
            )
          ),

        ],
      ),
    );
  }

  // =========================
  // 顶部栏
  // =========================
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children:  [
          InkWell(
            onTap: (){
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go('/chat');
            },
            child: Image.asset(
              'assets/images/common/back-icon.png',
              width: 30,
              height: 30,
            ),
          ),
          Spacer(),
          IconButton(
            onPressed: () {
              context.push(
                '/red-packet_record',
                extra: widget.userId,
              );
            },
            icon: Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // title
  // =========================
  Widget _buildTitle(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "已领取 $count/18，共 5/5 BOX",
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

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
          decoration:  BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.grey100),
            ),
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
                    Text(item["time"],
                        style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
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

// =========================
// 圆弧（关键修正）
// =========================
class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFC107)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();

    path.moveTo(0, size.height - 30);

    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 30,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}