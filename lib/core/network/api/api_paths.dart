class ApiPaths {
  /// 用户
  static const login = "/user/loginRegRes";
  static const logout = "/user/logout";
  static const userInfo = "/user/get";
  static const userInfoList = "/user/getBatch";
  static const searchUser = "/nearby/user";

  /// IM
  static const conversationList = "/im/conversation/list";
  static const messageList = "/im/message/list";

  /// 钱包
  static const walletInfo = "/wallet/info";
  static const walletBalance = "/wallet/balance";
  static const transfer = "/wallet/transfer";
  static const coinOverview = "/imApi/block/coin/overview";

  /// 配置
  static const config = '/imApi/config';

  /// dapp
  static const dappList = '/prod-api/im/app/dApp/list';

  /// 朋友圈
  /// http://8.210.9.90:7000 测试
  /// https://imapi.zjtxy.top/moments/friend97 生产
  static const circleUrl = 'https://imapi.zjtxy.top/moments/friend97';

  /// 社区
  static const createCommunity = '/room/community/add';
  static const recommendCommunity = '/room/community/recommend/list';
  static const communityList = '/room/community/list';
  static const communityDynamics = '/room/community/dynamics/page';
  static const addCommunityDynamics = '/room/community/dynamics/add';

  /// block
  static const getTokenTransactionRecord = '/block/getTokenTransactionRecord';
}
