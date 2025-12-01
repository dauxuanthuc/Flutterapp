import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_view.dart';
import 'biometric_lock_view.dart'; // Nhớ import màn hình khóa vân tay

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Đang chờ kiểm tra
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        // Đã đăng nhập -> Vào màn hình Khóa Vân Tay (hoặc Home nếu không dùng khóa)
        if (snapshot.hasData) {
          return const BiometricLockView(); 
        }
        
        // Chưa đăng nhập -> Vào màn hình Login
        return const LoginView();
      },
    );
  }
}