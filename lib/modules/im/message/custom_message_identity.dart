import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

final RegExp _clientMessageIdPattern = RegExp(r'^[0-9a-fA-F]{32}$');

String? customClientMessageId(RCIMIWMessage message) {
  if (message is! RCIMIWCustomMessage) {
    return null;
  }
  final identifier = message.identifier?.trim() ?? '';
  return _clientMessageIdPattern.hasMatch(identifier) ? identifier : null;
}

bool hasSameCustomClientMessageId(RCIMIWMessage first, RCIMIWMessage second) {
  final firstId = customClientMessageId(first);
  return firstId != null && firstId == customClientMessageId(second);
}
