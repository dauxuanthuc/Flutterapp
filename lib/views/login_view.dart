import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../utils/show_snack.dart';
import 'signup_view.dart';
import 'biometric_lock_view.dart'; // <--- 1. Import màn hình Khóa

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  void _handleLogin() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    
    // Gọi controller đăng nhập
    String? error = await authController.login(
      _emailController.text.trim(),
      _passController.text.trim(),
    );

    // Nếu có lỗi thì hiện thông báo
    if (error != null && mounted) {
      showSnackBar(context, error);
    } 
    // --- 2. CODE MỚI SỬA: NẾU THÀNH CÔNG THÌ CHUYỂN TRANG NGAY ---
    else if (mounted) {
      // Đăng nhập thành công -> Chuyển thẳng sang màn hình Khóa Vân Tay
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BiometricLockView()),
      );
    }
    // -------------------------------------------------------------
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthController>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text("Đăng nhập")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passController,
              decoration: const InputDecoration(labelText: "Mật khẩu"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleLogin,
                    child: const Text("Đăng nhập"),
                  ),
            
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupView()));
              },
              child: const Text("Chưa có tài khoản? Đăng ký ngay"),
            )
          ],
        ),
      ),
    );
  }
}