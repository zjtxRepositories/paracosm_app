class ImConnectionListener {

  void onConnected() {
    print("IM 已连接");
  }

  void onDisconnected() {
    print("IM 断开连接");
  }

  void onTokenExpired() {
    print("token 过期");
  }
}