import 'package:flutter/material.dart';
import 'reset_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  OtpVerificationScreen({required this.email});

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();

  void _verifyOtp() {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Masukkan 6 digit kode OTP")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResetPasswordScreen(
          email: widget.email,
          otp: _otpController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verifikasi OTP")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Masukkan Kode OTP",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Kode telah dikirim ke ${widget.email}. Silakan cek kotak masuk atau log server Anda.",
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 32),
            TextField(
              controller: _otpController,
              decoration: InputDecoration(
                labelText: "Kode OTP",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_clock),
                counterText: "",
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _verifyOtp,
                child: Text("Verifikasi Kode"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
