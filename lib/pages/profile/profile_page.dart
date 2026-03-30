import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';

import 'package:paracosm/widgets/common/app_modal.dart';
import 'package:paracosm/widgets/common/app_network_selector.dart';

import '../../modules/account/manager/account_manager.dart';
import '../../modules/account/model/account_model.dart';
import '../../modules/wallet/model/wallet_model.dart';
import '../../widgets/common/app_network_image.dart';

/// 个人中心页面 (钱包首页)
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isBalanceVisible = true; // 控制余额显示/隐藏的状态

  AccountModel? _accountModel;
  WalletModel? _walletModel;
  ChainAccount? _selectedNetwork;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final manager = AccountManager();
    _accountModel = manager.currentAccount;
    _walletModel = manager.currentWallet;
    setState(() {});
  }

  /// 显示网络选择弹窗
  void _showNetworkSelector() {
    if (_walletModel == null) return;
    AppModal.show(
      context,
      title: AppLocalizations.of(context)!.profileProfileChooseNetwork,
      confirmText: null, // 移除底部确认按钮，改为点击项即选择并关闭
      onConfirm: () {},
      child: AppNetworkSelector(
        initialNetwork: _walletModel!.currentChain ?? _walletModel!.chains.first,
        networks: _walletModel!.chains,
        onSelected: (network) {
          setState(() {
            _selectedNetwork = network;
          });
          context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: false, // 不显示默认导航栏
      child: Stack(
        children: [
          // 背景图 (从 wallet_setup_page.dart 复制)
          Positioned.fill(
            child: Image.asset(
              'assets/images/wallet/grid-bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              _buildHeader(), // 顶部标题和头像
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildWalletCard(), // 钱包资产卡片
                      _buildTokenList(), // 代币列表
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建顶部标题和头像区域
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // PARACOSM 标题，底部带有亮绿色下划线装饰 (根据 UI 截图)
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: 2,
                left: 0,
                right: 0,
                child: Container(
                  height: 8,
                  color: AppColors.primary, // 亮绿色下划线
                ),
              ),
              Text(
                AppLocalizations.of(context)!.profileProfileParacosm,
                style: AppTextStyles.h1.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.black
                ),
              ),
            ],
          ),
          // 圆形头像，带亮绿色边框 (根据 UI 截图)
          GestureDetector(
            onTap: () {
              context.push('/profile-details');
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary, // 亮绿色边框
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: const AssetImage('assets/images/chat/avatar.png'),
                backgroundColor: AppColors.grey100,
                onBackgroundImageError: (_, __) {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建主钱包资产展示卡片
  Widget _buildWalletCard({
    bool showActions = true,
    EdgeInsetsGeometry margin = const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 24),
    VoidCallback? onEyeTap,
  }) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 钱包名称
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.profileProfileWalletNo1,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.grey400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              // 网络选择 (BNB 下拉)
              GestureDetector(
                onTap: _showNetworkSelector,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.grey200, width: 1),
                  ),
                  child: Row(
                    children: [
                      AppNetworkImage(
                        url: _selectedNetwork?.logo,
                        width: 16,
                        height: 16,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedNetwork?.name ?? '',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 12, color: AppColors.grey400),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 余额数值及显隐切换按钮
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _isBalanceVisible
                  ? Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '\$',
                            style: AppTextStyles.h1.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                          const WidgetSpan(child: SizedBox(width: 2)),
                          TextSpan(
                            text: '7,859,942.00',
                            style: AppTextStyles.h1.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Transform.translate(
                      offset: const Offset(0, 4), 
                      child: Text(
                        '********',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                    ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() => _isBalanceVisible = !_isBalanceVisible);
                  onEyeTap?.call();
                },
                child: Image.asset(
                  _isBalanceVisible ? 'assets/images/common/eye-line.png' : 'assets/images/common/eye-off-line.png',
                  width: 20,
                  height: 20,
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                // Send 按钮
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      context.push('/transfer', extra: _selectedNetwork);
                    },
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.grey900, // 深黑色背景
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(width: 6),
                          Image.asset('assets/images/profile/send.png', width: 32, height: 32),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.profileTokenNetworkSend,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Receive 按钮
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      context.push('/token-receive');
                    },
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: AppColors.grey900, width: 1), // 黑色边框
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(width: 6),
                          Image.asset('assets/images/profile/receive.png', width: 32, height: 32),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.profileTokenNetworkReceive,
                            style: const TextStyle(
                              color: AppColors.grey900,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 构建代币列表区域
  Widget _buildTokenList() {
    // 模拟代币数据 (还原为之前的版本，保留补全图标逻辑)
    final tokens = [
      {'name': AppLocalizations.of(context)!.profileProfileAll, 'symbol': 'ALL', 'price': '0.00', 'change': '0.00%', 'isUp': true, 'icon': 'all.png'},
      {'name': 'Solana', 'symbol': 'SOL', 'price': '145.20', 'change': '2.45%', 'isUp': true, 'icon': 'solana.png'},
      {'name': 'Ethereum', 'symbol': 'ETH', 'price': '3,083.29', 'change': '0.63%', 'isUp': true, 'icon': 'eth.png'},
      {'name': 'BNB Chain', 'symbol': 'BNB', 'price': '580.00', 'change': '0.85%', 'isUp': true, 'icon': 'bnb.png'},
      {'name': 'Base', 'symbol': 'BASE', 'price': '1.00', 'change': '0.12%', 'isUp': true, 'icon': 'base.png'},
      {'name': 'Polygon', 'symbol': 'MATIC', 'price': '0.75', 'change': '1.25%', 'isUp': false, 'icon': 'polygon.png'},
      {'name': 'Optimism', 'symbol': 'OP', 'price': '2.40', 'change': '3.15%', 'isUp': true, 'icon': 'optimism.png'},
      {'name': 'Arbitrum', 'symbol': 'ARB', 'price': '1.20', 'change': '0.92%', 'isUp': false, 'icon': 'arbitrum.png'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x05000000), // #000000 2% 比例
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, -10), // X: 0, Y: -10
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.profileTokenNetworkTokens,
            style: AppTextStyles.h2.copyWith(fontSize: 18, color: AppColors.black),
          ),
          const SizedBox(height: 8),
          ...tokens.map((token) => _buildTokenItem(
                token['name'] as String,
                token['symbol'] as String,
                token['price'] as String,
                token['change'] as String,
                token['isUp'] as bool,
                token['icon'] as String,
              )),
          // 添加底部安全边距，确保列表在滑动到底部时不会紧贴边缘
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 构建代币列表项
  /// [name] 代币名称, [symbol] 代币符号, [price] 价格, [change] 涨跌幅, [isUp] 是否上涨, [iconName] 图标文件名
  Widget _buildTokenItem(String name, String symbol, String price, String change, bool isUp, String iconName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          // 1. 代币图标容器 (点击跳转代币详情 - 第二个截图页)
          GestureDetector(
            onTap: () {
              context.push('/token-detail', extra: {
                'name': name,
                'symbol': symbol,
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.grey100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.asset(
                  'assets/images/profile/$iconName',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      name.substring(0, 1).toUpperCase(),
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 2. 代币名称 (同样点击跳转代币详情)
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                context.push('/token-detail', extra: {
                  'name': name,
                  'symbol': symbol,
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Text(
                name,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.grey900,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // 3. 简易迷你趋势图 (点击跳转 K 线图 - 第一个截图页)
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () {
                context.push('/token-market', extra: {
                  'symbol': symbol,
                });
              },
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                height: 18,
                child: CustomPaint(
                  painter: MiniChartPainter(isUp: isUp),
                ),
              ),
            ),
          ),
          // 4. 价格和涨跌幅显示
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$$price',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.grey900,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: const Size(10, 7),
                      painter: ArrowPainter(isUp: isUp),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change,
                      style: AppTextStyles.caption.copyWith(
                        color: isUp ? AppColors.primaryDark : AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 趋势箭头绘制类
class ArrowPainter extends CustomPainter {
  final bool isUp;
  ArrowPainter({required this.isUp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isUp ? AppColors.primaryDark : AppColors.error
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0; // 增加线宽并配合圆角连接，使三角形边缘更圆润

    final path = Path();
    // 稍微向内收缩一点点，给 strokeWidth 留出空间
    const double padding = 1.0;
    if (isUp) {
      // 上涨箭头
      path.moveTo(size.width / 2, padding);
      path.lineTo(size.width - padding, size.height - padding);
      path.lineTo(padding, size.height - padding);
    } else {
      // 下跌箭头
      path.moveTo(padding, padding);
      path.lineTo(size.width - padding, padding);
      path.lineTo(size.width / 2, size.height - padding);
    }
    path.close();
    
    // 先绘制描边以获得圆角效果
    paint.style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
    // 再进行填充
    paint.style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ArrowPainter oldDelegate) => oldDelegate.isUp != isUp;
}

/// 简易迷你图绘制类 (使用 CustomPainter 还原 UI 效果)
/// 实现了平滑曲线、渐变颜色以及发光感
class MiniChartPainter extends CustomPainter {
  final bool isUp; // 是否为上涨趋势
  MiniChartPainter({required this.isUp});

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = isUp ? AppColors.primaryDark : AppColors.error;

    // 1. 绘制底层发光效果 (使用模糊滤镜模拟 Glow 效果)
    final glowPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = _createSmoothPath(size);
    canvas.drawPath(path, glowPaint);

    // 2. 绘制主趋势线条 (使用线性渐变，模拟从淡入到亮起的发光线条感)
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    linePaint.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        baseColor.withValues(alpha: 0.15),
        baseColor.withValues(alpha: 0.4),
        baseColor,
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, linePaint);
  }

  /// 使用三次贝塞尔曲线 (Cubic Bezier) 创建平滑自然的波动曲线
  Path _createSmoothPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    // 模拟真实的波动数据点坐标 (归一化到 size 范围)
    final List<Offset> points = isUp
        ? [
            Offset(0.0 * w, 0.55 * h),
            Offset(0.15 * w, 0.65 * h),
            Offset(0.35 * w, 0.25 * h),
            Offset(0.55 * w, 0.75 * h),
            Offset(0.75 * w, 0.35 * h),
            Offset(0.95 * w, 0.1 * h),
            Offset(1.0 * w, 0.15 * h),
          ]
        : [
            Offset(0.0 * w, 0.2 * h),
            Offset(0.2 * w, 0.15 * h),
            Offset(0.4 * w, 0.65 * h),
            Offset(0.6 * w, 0.35 * h),
            Offset(0.8 * w, 0.75 * h),
            Offset(1.0 * w, 0.95 * h),
          ];

    path.moveTo(points[0].dx, points[0].dy);

    // 遍历点并使用贝塞尔曲线连接
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      
      // 计算控制点，使曲线在各点之间平滑过渡
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) * 0.5, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) * 0.5, p1.dy);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant MiniChartPainter oldDelegate) => oldDelegate.isUp != isUp;
}
