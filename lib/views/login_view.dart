import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../utils/show_snack.dart';
import 'signup_view.dart';

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

    // Gọi controller để xử lý logic
    String? error = await authController.login(
      _emailController.text.trim(),
      _passController.text.trim(),
    );

    // Nếu có lỗi thì hiện thông báo
    if (error != null && mounted) {
      showSnackBar(context, error);
    }
    // Nếu thành công, Main.dart sẽ tự chuyển hướng nhờ StreamBuilder
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe trạng thái loading từ Controller
    final isLoading = context.watch<AuthController>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text("Đăng nhập Hệ thống")),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupView()),
                );
              },
              child: const Text("Chưa có tài khoản? Đăng ký ngay"),
            ),
          ],
        ),
      ),
    );
  }
}
