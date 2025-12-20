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
  // Trong controllers/auth_controller.dart

  String? _verificationId;
  String? get verificationId => _verificationId;

  // Bước 1: Gửi OTP
  Future<void> sendOtp(String phone, Function(String?) onResult) async {
    _setLoading(true);
    await _authService.verifyPhone(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        // Trường hợp tự động xác thực trên Android
        await FirebaseAuth.instance.signInWithCredential(credential);
        _setLoading(false);
        onResult(null); 
      },
      verificationFailed: (e) {
        _setLoading(false);
        onResult(e.message);
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId; // Lưu lại mã này để dùng ở bước 2
        _setLoading(false);
        onResult("OTP_SENT"); 
      },
      codeAutoRetrievalTimeout: (vId) => _verificationId = vId,
    );
  }

  // Bước 2: Xác nhận OTP
  Future<String?> verifyOtp(String smsCode) async {
    if (_verificationId == null) return "Phiên làm việc hết hạn";
    _setLoading(true);
    try {
      await _authService.signInWithPhone(_verificationId!, smsCode);
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return e.message;
    }
  }
}