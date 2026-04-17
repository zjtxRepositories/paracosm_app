import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/common/app_button.dart';
import 'package:paracosm/widgets/common/app_checkbox.dart';

class MomentReportPage extends StatefulWidget {
  const MomentReportPage({super.key});

  @override
  State<MomentReportPage> createState() => _MomentReportPageState();
}

class _MomentReportPageState extends State<MomentReportPage> {
  int? _selectedIndex;

  static const List<String> _reasons = [
    'Pornographic and vulgar',
    'Bloody violence',
    'False advertising links',
    'Malicious fraud',
    'Disturbing content',
    'other',
  ];

  @override
  Widget build(BuildContext context) {
    final isSelected = _selectedIndex != null;

    return AppPage(
      title: 'Report',
      showNavBorder: true,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reason for reporting:',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grey400,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _reasons.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final selected = _selectedIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppColors.grey900 : AppColors.grey200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            AppCheckbox(
                              value: selected,
                              isRadio: false,
                              size: 20,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _reasons[index],
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.grey600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Next step',
                onPressed: isSelected
                    ? () {
                        context.push('/moment-report-detail');
                      }
                    : null,
                backgroundColor: isSelected ? AppColors.grey900 : AppColors.grey300,
                textColor: AppColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
