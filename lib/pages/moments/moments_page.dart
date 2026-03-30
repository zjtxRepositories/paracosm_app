import 'package:flutter/material.dart';
import 'package:paracosm/widgets/base/app_page.dart';

/// 动态/朋友圈页面 (占位)
class MomentsPage extends StatelessWidget {
  const MomentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Moments',
      showBack: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.blur_circular, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Moments Page Placeholder', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
