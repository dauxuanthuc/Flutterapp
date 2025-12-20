import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../utils/show_snack.dart';
import 'phoneAuthView.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  void _handleSignup() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    
    String? error = await authController.register(
      _emailController.text.trim(),
      _passController.text.trim(),
    );

    if (error != null && mounted) {
      showSnackBar(context, error);
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthController>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký tài khoản")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController, 
              decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passController, 
              decoration: const InputDecoration(labelText: "Mật khẩu", border: OutlineInputBorder()), 
              obscureText: true
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    onPressed: _handleSignup,
                    child: const Text("Đăng ký"),
                  ),
            const SizedBox(height: 20),
            const Text("Hoặc sử dụng phương thức khác"),
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(builder: (_) => const PhoneAuthView())
                );
              }, 
              icon: const Icon(Icons.phone_android, size: 40, color: Colors.blue)
            )
          ],
        ),
      ),
    );
  }
}