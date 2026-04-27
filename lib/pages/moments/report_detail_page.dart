import 'package:flutter/material.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';

class MomentReportDetailPage extends StatefulWidget {
  const MomentReportDetailPage({super.key});

  @override
  State<MomentReportDetailPage> createState() => _MomentReportDetailPageState();
}

class _MomentReportDetailPageState extends State<MomentReportDetailPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasText = _controller.text.trim().isNotEmpty;

    return AppPage(
      title: l10n.translate('moments_report_title'),
      showNavBorder: true,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('moments_problem_description'),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grey400,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                height: 240,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                    color: hasText ? AppColors.grey900 : AppColors.grey200,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  onChanged: (_) {
                    setState(() {});
                  },
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.grey900,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                    decoration: InputDecoration(
                    hintText: l10n.translate('moments_please_enter'),
                    hintStyle: AppTextStyles.body.copyWith(
                      color: AppColors.grey400,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const Spacer(),
              AppButton(
                text: l10n.translate('moments_submit'),
                onPressed: hasText ? () {} : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
