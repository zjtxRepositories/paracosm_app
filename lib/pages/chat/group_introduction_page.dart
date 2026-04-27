import 'package:flutter/material.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_reply_sheet.dart';

class GroupIntroductionPage extends StatefulWidget {
  final String initialIntroduction;

  const GroupIntroductionPage({
    super.key,
    this.initialIntroduction = '',
  });

  @override
  State<GroupIntroductionPage> createState() => _GroupIntroductionPageState();
}

class _GroupIntroductionPageState extends State<GroupIntroductionPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialIntroduction);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openReplySheet() async {
    final result = await AppReplySheet.show<String>(
      context,
      initialText: _controller.text,
      hintText: AppLocalizations.of(context)!.chatGroupInfoHint,
      showVoiceButton: true,
      showEmojiButton: true,
      showBottomAccessoryBar: true,
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _controller.text = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: AppLocalizations.of(context)!.chatSettingIntroduction,
      backgroundColor: Colors.white,
      showNavBorder: true,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openReplySheet,
          child: AbsorbPointer(
            child: TextField(
              controller: _controller,
              maxLines: null,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.chatGroupInfoHint,
                hintStyle: const TextStyle(
                  color: Color(0xFFBDBDBD),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              style: const TextStyle(
                color: Color(0xFF1F1F1F),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
