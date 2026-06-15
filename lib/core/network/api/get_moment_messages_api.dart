import 'package:paracosm/core/models/moment_message_model.dart';
import 'package:paracosm/core/network/client/friend_circle_base_client.dart';
import '../../../modules/account/manager/account_manager.dart';
import 'api_paths.dart';

class GetMomentMessagesApi {
  static FriendCircleBaseClient _client = FriendCircleBaseClient();

  static Future<List<MomentMessageModel>> get({
    int pageIndex = 0,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      ApiPaths.userMessage,
      params: {
        'user_id': AccountManager().currentAccount?.accountId,
        'page': pageIndex,
        'size': pageSize,
      },
    );

    final dynamic rawList = response is Map ? response['data'] : response;
    if (rawList is! List) return const [];

    return rawList
        .whereType<Map>()
        .map(
          (item) =>
              MomentMessageModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static void setClientForTesting(FriendCircleBaseClient client) {
    _client = client;
  }

  static void resetClientForTesting() {
    _client = FriendCircleBaseClient();
  }
}
