import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart'; 
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
  // Chúng ta sẽ lưu số điện thoại đầy đủ (có cả +84) vào biến này
  String completePhoneNumber = "";
  final _otpController = TextEditingController();
  bool _isOtpSent = false;

  void _sendOtp() async {
    if (completePhoneNumber.isEmpty) {
      showSnackBar(context, "Vui lòng nhập số điện thoại hợp lệ");
      return;
    }

    final authController = Provider.of<AuthController>(context, listen: false);

    // Gửi completePhoneNumber (đã có dạng +84...)
    await authController.sendOtp(completePhoneNumber, (result) {
      if (result == "OTP_SENT") {
        setState(() => _isOtpSent = true);
        showSnackBar(context, "Mã OTP đã được gửi đến $completePhoneNumber");
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
      appBar: AppBar(title: const Text("Xác thực điện thoại")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            IntlPhoneField(
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
              ),
              initialCountryCode: 'VN', 
              languageCode: "vi", 
              disableLengthCheck:
                  false, 
              enabled: !_isOtpSent,
              onChanged: (phone) {
                completePhoneNumber = phone.completeNumber;
              },
            ),

            if (_isOtpSent) ...[
              const SizedBox(height: 15),
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: "Nhập mã OTP gồm 6 số",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                keyboardType: TextInputType.number,
              ),
            ],

            const SizedBox(height: 25),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _isOtpSent ? _verifyOtp : _sendOtp,
                    child: Text(
                      _isOtpSent ? "Xác nhận mã OTP" : "Gửi yêu cầu OTP",
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
