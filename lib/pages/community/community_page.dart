import 'package:flutter/material.dart';
import 'package:paracosm/widgets/base/app_page.dart';

/// 社区页面 (占位)
class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Community',
      showBack: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.whatshot, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Community Page Placeholder', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
