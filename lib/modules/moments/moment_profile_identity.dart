import 'package:paracosm/core/models/social_wallet_address.dart';

String resolveMomentProfileUserId({
  required String userId,
  required String imUserId,
  required bool isSelf,
  required String currentUserId,
}) {
  final normalizedUserId = userId.trim().toLowerCase();
  if (normalizedUserId.isNotEmpty) {
    return normalizedUserId;
  }

  final normalizedImUserId = SocialWalletAddress.normalize(imUserId);
  if (normalizedImUserId.isNotEmpty) {
    return normalizedImUserId;
  }

  if (isSelf) {
    return currentUserId.trim().toLowerCase();
  }

  return '';
}
