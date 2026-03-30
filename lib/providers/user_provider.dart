import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 一个简单的用户状态模型
class UserState {
  final String name;
  final bool isLoggedIn;

  UserState({required this.name, required this.isLoggedIn});

  UserState copyWith({String? name, bool? isLoggedIn}) {
    return UserState(
      name: name ?? this.name,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

/// 使用 StateNotifierProvider 管理用户状态
class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(UserState(name: '游客', isLoggedIn: false));

  void login(String name) {
    state = state.copyWith(name: name, isLoggedIn: true);
  }

  void logout() {
    state = UserState(name: '游客', isLoggedIn: false);
  }
}

/// 全局可用的 userProvider
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});
