class ApiPaths {

  /// 用户
  static const login = "/user/loginRegRes";
  static const logout = "/user/logout";
  static const userInfo = "/user/get";

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
  static const circleUrl = 'https://imapi.zjtxy.top/moments/link';
  static const noteList = '/app/note/list';
}