import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_reply_sheet.dart';

class GroupIntroductionPage extends StatefulWidget {
  final String title;
  final String initialIntroduction;

  const GroupIntroductionPage({
    super.key,
    required this.title,
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


  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: widget.title,
      backgroundColor: Colors.white,
      showNavBorder: true,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: TextField(
          controller: _controller,
          maxLines: null,
          decoration: InputDecoration(
            hintText: '${AppLocalizations.of(context)!.profileTransferPleaseEnter}${widget.title}',
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
            textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            context.pop(value.trim());
          },
        ),
      ),
    );
  }
}
