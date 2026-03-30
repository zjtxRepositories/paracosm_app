import 'package:flutter/material.dart';
import 'package:paracosm/widgets/base/app_page.dart';

/// 发现页面 (占位)
class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Discover',
      showBack: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Discover Page Placeholder', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
