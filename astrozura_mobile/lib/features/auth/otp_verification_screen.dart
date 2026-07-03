// lib/screens/auth/otp_verification_screen.dart
//
// UI  → logo, masked number, styled boxes, resend timer,
//        "Verify & Proceed" button, dev OTP banner, terms footer
// Logic → server-side OTP via POST /api/login (verifyOtp), role-based routing

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/profile_provider.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/auth_services.dart';
import '../main_navigation.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String devOtp;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.devOtp = '',
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  int _seconds = 60;
  Timer? _timer;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_seconds == 0) {
        t.cancel();
        return;
      }
      setState(() => _seconds--);
    });
  }

  String get _enteredOtp => _controllers.map((c) => c.text.trim()).join();

  String _maskNumber(String n) {
    if (n.length < 4) return n;
    return '******${n.substring(n.length - 4)}';
  }

  String _paddedSeconds() {
    return '0:${_seconds.toString().padLeft(2, '0')}';
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    ));
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigation(initialIndex: 0),
      ),
      (_) => false,
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _enteredOtp;
    if (otp.length != 6) {
      _showError('Please enter the complete 6-digit OTP');
      return;
    }
    setState(() => _isVerifying = true);
    final result = await _authService.verifyOtp(widget.phoneNumber, otp);
    setState(() => _isVerifying = false);
    if (!mounted) return;

    if (result['success'] == true) {
      await context.read<ProfileProvider>().refresh();
      if (!mounted) return;
      _showSuccess(result['message'] ?? 'Verified!');
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _navigateToHome();
    } else {
      _showError(result['message'] ?? 'Verification failed. Try again.');
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resendOtp() async {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    _startTimer();
    final result = await _authService.sendOtp(widget.phoneNumber);
    if (!mounted) return;
    if (result['success'] == true) {
      _showSuccess('OTP resent successfully');
    } else {
      _showError(result['message'] ?? 'Failed to resend OTP');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Verification',
          style: TextStyle(
            color: Color(0xFF4A5BD3),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset('assets/images/logo.png', height: 100, width: 100),
              const SizedBox(height: 10),
              Text(
                'Verify Phone',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2E2A72),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'We have sent a 6-digit verification code to',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFBDBCBC), fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                '+91 ${_maskNumber(widget.phoneNumber)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF2E2A72),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Edit Phone Number',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, _buildOtpBox),
              ),
              const SizedBox(height: 20),
              if (widget.devOtp.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.developer_mode,
                          size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Dev OTP: ${widget.devOtp}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Container(
                width: 220,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: _seconds > 0
                    ? RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.grey,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          children: [
                            const TextSpan(text: 'RESEND IN  '),
                            TextSpan(
                              text: _paddedSeconds(),
                              style: const TextStyle(
                                color: Color(0xFF4A5BD3),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: _resendOtp,
                        child: const Text(
                          'RESEND CODE',
                          style: TextStyle(
                            color: Color(0xFF4A5BD3),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 36),
              GestureDetector(
                onTap: _isVerifying ? null : _verifyOtp,
                child: Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFF26235E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: _isVerifying
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Verify & Proceed \u2192',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    children: [
                      TextSpan(
                          text: 'By continuing, you agree to Astro Zura\'s '),
                      TextSpan(
                        text: 'Terms of Services',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.black54,
                        ),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy.',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E2A72),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFF5F4FC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4A5BD3), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _controllers[index].text.isNotEmpty
                  ? const Color(0xFF4A5BD3).withOpacity(0.4)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
        ),
        onChanged: (value) {
          setState(() {});
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
              _verifyOtp();
            }
          } else {
            if (index > 0) _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}
