import 'dart:convert';

String buildTokenReceivePaymentPayload({
  required String address,
  required String tokenSymbol,
  required String chain,
}) {
  return jsonEncode({
    'type': 'payment',
    'address': address,
    'token': tokenSymbol,
    'chain': chain,
  });
}
