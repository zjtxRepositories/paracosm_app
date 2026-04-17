import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:paracosm/theme/app_colors.dart';

import '../../theme/app_text_styles.dart';
import '../common/app_modal.dart';

enum ProtocolType {
  runes,
  src20,
  brc20,
}
extension ProtocolTypeText on ProtocolType {
  String get text {
    switch (this) {
      case ProtocolType.runes:
        return 'Runes';
      case ProtocolType.src20:
        return 'SRC20';
      case ProtocolType.brc20:
        return 'BRC20';
    }
  }
}
class WalletProtocolModal {
  /// =========================
  /// 网络选择
  /// =========================
  static Future<void> show({
    required BuildContext context,
    void Function(ProtocolType protocolType)? onConfirm,
  }) async {
    List<ProtocolType> all = [ProtocolType.runes,ProtocolType.src20,ProtocolType.brc20,];
    AppModal.show(
        context,
        title: '请选择协议',
        child: SizedBox(
          height: 200,
          child: ListView.separated(
            itemCount: all.length,
            separatorBuilder: (_, __) => Padding(
              padding: EdgeInsets.only(left: 0),
              child: Divider(height: 0.5, color: AppColors.grey200),
            ),
            itemBuilder: (_, index) {
              final type = all[index];
              return SizedBox(
                height: 52,
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 0,vertical: 16),
                  minVerticalPadding: 0,
                  minLeadingWidth: 0,
                  leading: Text(
                    type.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey600,
                    ),
                  ),
                  onTap: () {
                    if(onConfirm != null){
                      onConfirm(type);
                    }
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
      onConfirm: () {},

    );
  }
}