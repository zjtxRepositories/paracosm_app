
import 'package:get/get_connect/http/src/multipart/form_data.dart' as dio hide FormData;
import 'package:paracosm/core/network/client/http_client.dart';
import '../../../modules/account/manager/account_manager.dart';
import '../../../modules/wallet/model/token_transaction_record_model.dart';
import 'api_paths.dart';
import 'package:dio/dio.dart' as dio;

class GetTokenTransactionRecordApi {
  static Future<List<TokenTransactionRecordModel>> get({
    required String address,
    required String contractAddress,
    int pageIndex = 0,
    int pageSize = 20,
  }) async {
     String? token = AccountManager().currentAccount?.token;
    final data = await HttpClient().get(
        ApiPaths.getTokenTransactionRecord,
        params: {
         'access_token': token,
          'address': address,
          'contractAddress': contractAddress,
          'pageIndex': pageIndex.toString(),
          'pageSize': pageSize.toString(),
        },
    );
     print('GetTokenTransactionRecordApi------$data');
     final list =  (data as List).map((e) {
       final utxo = TokenTransactionRecordModel.fromJson(e,address);
       return utxo;
     }).toList();
     return list;
    return [];
  }
}
