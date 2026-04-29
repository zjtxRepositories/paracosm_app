import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

abstract class ImMessage {
  RCIMIWMessageType get type;

  Future<RCIMIWMessage?> toRCMessage();
}