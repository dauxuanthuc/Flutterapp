import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  // Khởi tạo instance của LocalAuthentication
  static final LocalAuthentication _auth = LocalAuthentication();

  // --- 1. KIỂM TRA THIẾT BỊ CÓ HỖ TRỢ KHÔNG ---
  static Future<bool> isBiometricAvailable() async {
    try {
      // Kiểm tra phần cứng có cảm biến không
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      
      // Kiểm tra thiết bị có hỗ trợ bảo mật không (gồm cả PIN/Pattern)
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      
      return canCheckBiometrics || isDeviceSupported;
    } on PlatformException catch (e) {
      print("Lỗi kiểm tra sinh trắc học: $e");
      return false;
    }
  }

  // --- 2. THỰC HIỆN XÁC THỰC (QUÉT) ---
  static Future<bool> authenticate() async {
    try {
      // Lấy danh sách các phương thức có sẵn (Vân tay, Khuôn mặt, Mống mắt...)
      final List<BiometricType> availableBiometrics =
          await _auth.getAvailableBiometrics();

      print("Các phương thức bảo mật có sẵn: $availableBiometrics");

      // Gọi hàm xác thực
      return await _auth.authenticate(
        localizedReason: 'Vui lòng quét vân tay hoặc khuôn mặt để đăng nhập',
        
        // Cấu hình cho phiên bản v3.0.0
        options: const AuthenticationOptions(
          stickyAuth: true,      // Giữ app active khi hộp thoại hệ thống hiện lên
          biometricOnly: true,   // True: Chỉ dùng Vân tay/FaceID. False: Cho phép nhập mã PIN đt
          useErrorDialogs: true, // Tự động hiện thông báo lỗi hệ thống nếu quét sai
        ),
      );
    } on PlatformException catch (e) {
      print("Lỗi trong quá trình xác thực: $e");
      return false;
    }
  }
}