class ImErrorMapper {
  static String message(int code) {
    switch (code) {

      case 0:
        return "成功";

      case 25101:
        return "用户不存在";

      case 25102:
        return "已经是好友";

      case 25103:
        return "对方拒绝添加";

      case 25104:
        return "已在黑名单";

      case 23424:
        return "网络错误";

      default:
        return "未知错误($code)";
    }
  }
}