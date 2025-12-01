import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading; // Để View hiển thị vòng xoay loading

  // Hàm Đăng nhập
  Future<String?> login(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signIn(email, password);
      _setLoading(false);
      return null; // Null nghĩa là thành công, không có lỗi
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return e.message; // Trả về nội dung lỗi
    }
  }

  // Hàm Đăng ký
  Future<String?> register(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signUp(email, password);
      _setLoading(false);
      return null; 
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return e.message;
    }
  }

  // Hàm Đăng xuất
  Future<void> logout() async {
    await _authService.signOut();
  }

  // Helper để cập nhật trạng thái loading
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // QUAN TRỌNG: Báo cho View vẽ lại
  }
}