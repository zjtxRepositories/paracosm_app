import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';

class GroupIntroductionPage extends StatefulWidget {
  final String title;
  final String initialIntroduction;
  final int? maxLength;

  const GroupIntroductionPage({
    super.key,
    required this.title,
    this.initialIntroduction = '',
    this.maxLength,
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

  void _submit() {
    context.pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPage(
      title: widget.title,
      backgroundColor: Colors.white,
      showNavBorder: true,
      headerActions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton(
            onPressed: _submit,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(54, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              l10n.translate('moments_release'),
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: TextField(
          controller: _controller,
          maxLines: null,
          maxLength: widget.maxLength,
          inputFormatters: [
            if (widget.maxLength != null)
              LengthLimitingTextInputFormatter(widget.maxLength),
          ],
          decoration: InputDecoration(
            hintText: '${l10n.profileTransferPleaseEnter}${widget.title}',
            hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          style: const TextStyle(color: Color(0xFF1F1F1F)),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            FocusScope.of(context).unfocus();
          },
        ),
      ),
    );
  }
}
