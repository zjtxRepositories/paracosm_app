import 'package:flutter/cupertino.dart';

class KeyboardDetector extends StatefulWidget {
  final Widget Function(double height) builder;

  const KeyboardDetector({required this.builder});

  @override
  State<KeyboardDetector> createState() =>
      _KeyboardDetectorState();
}

class _KeyboardDetectorState
    extends State<KeyboardDetector>
    with WidgetsBindingObserver {
  double height = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    final newHeight =
        WidgetsBinding.instance.window.viewInsets.bottom;

    setState(() {
      height = newHeight;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(height);
  }
}