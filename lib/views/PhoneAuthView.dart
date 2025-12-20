import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../utils/show_snack.dart';
import 'biometric_lock_view.dart';

class PhoneAuthView extends StatefulWidget {
  const PhoneAuthView({super.key});

  @override
  State<PhoneAuthView> createState() => _PhoneAuthViewState();
}

class _PhoneAuthViewState extends State<PhoneAuthView> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isOtpSent = false;

  void _sendOtp() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    await authController.sendOtp(_phoneController.text.trim(), (result) {
      if (result == "OTP_SENT") {
        setState(() => _isOtpSent = true);
        showSnackBar(context, "Mã OTP đã được gửi!");
      } else if (result != null) {
        showSnackBar(context, result);
      }
    });
  }

  void _verifyOtp() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    String? error = await authController.verifyOtp(_otpController.text.trim());

    if (error == null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BiometricLockView()),
      );
    } else if (mounted) {
      showSnackBar(context, error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthController>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text("Xác thực Số điện thoại")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Số điện thoại (+84...)"),
              keyboardType: TextInputType.phone,
              enabled: !_isOtpSent,
            ),
            if (_isOtpSent) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: "Nhập mã OTP"),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _isOtpSent ? _verifyOtp : _sendOtp,
                    child: Text(_isOtpSent ? "Xác nhận OTP" : "Gửi mã OTP"),
                  ),
          ],
        ),
      ),
    );
  }
}