import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Import các file cần thiết
import '../services/biometric_service.dart';
import '../controllers/auth_controller.dart';
import 'home_view.dart';
import 'auth_wrapper.dart'; // <--- NHỚ IMPORT CÁI NÀY ĐỂ LOGOUT CHUẨN

class BiometricLockView extends StatefulWidget {
  const BiometricLockView({super.key});

  @override
  State<BiometricLockView> createState() => _BiometricLockViewState();
}

class _BiometricLockViewState extends State<BiometricLockView> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  void _checkBiometric() async {
    // Kiểm tra mounted để tránh lỗi gọi setState khi màn hình chưa vẽ xong
    if (!mounted) return;
    setState(() => _isAuthenticating = true);

    // 1. Kiểm tra máy có hỗ trợ không
    bool isAvailable = await BiometricService.isBiometricAvailable();

    if (!isAvailable) {
      if (!mounted) return;
      print("Thiết bị không hỗ trợ -> Vào thẳng Home");
      _goToHome();
      return;
    }

    // 2. Tiến hành quét
    bool isAuthenticated = await BiometricService.authenticate();

    if (!mounted) return; // Kiểm tra lại sau khi await

    if (isAuthenticated) {
      _goToHome();
    } else {
      setState(() => _isAuthenticating = false);
      // Quét sai hoặc bấm Hủy thì ở yên đây
    }
  }

  void _goToHome() {
    // Dùng pushReplacement để thay thế màn hình Khóa bằng màn hình Home
    // Người dùng bấm Back sẽ không quay lại màn hình Khóa nữa (trừ khi đăng xuất)
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeView()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              "Ứng dụng đang bị khóa",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("Vui lòng xác thực để tiếp tục"),
            const SizedBox(height: 30),

            // Nút quét lại
            ElevatedButton.icon(
              onPressed: _isAuthenticating ? null : _checkBiometric,
              icon: const Icon(Icons.fingerprint, size: 30),
              label: const Text("Mở khóa bằng FaceID/Vân tay"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Nút Đăng xuất (ĐÃ SỬA LẠI CHO CHUẨN ĐIỀU HƯỚNG)
            TextButton(
              onPressed: () async {
                // 1. Đăng xuất Firebase
                await context.read<AuthController>().logout();

                // 2. Chuyển hướng dứt khoát về AuthWrapper (Màn hình khởi động)
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    (route) => false, // Xóa sạch lịch sử cũ
                  );
                }
              },
              child: const Text("Đăng xuất / Dùng mật khẩu"),
            ),
          ],
        ),
      ),
    );
  }
}
