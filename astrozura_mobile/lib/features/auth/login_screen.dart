// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/services/auth_services.dart';
import 'otp_verification_screen.dart';
import 'register_screen.dart';
import '../main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── OTP TAB ───────────────────────────────────────────────────────────────
  final _phoneController = TextEditingController();
  bool _isOtpLoading = false;

  // ── PASSWORD TAB ──────────────────────────────────────────────────────────
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isPasswordLoading = false;
  bool _isGoogleLoading = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Snack-bar helpers ─────────────────────────────────────────────────────
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Role-based navigation ─────────────────────────────────────────────────
  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigation(initialIndex: 0),
      ),
      (_) => false,
    );
  }

  void _goToRegister() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  // ── OTP FLOW: step 1 — send OTP ──────────────────────────────────────────
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) return _showError('Please enter your phone number');
    if (phone.length != 10) return _showError('Phone must be 10 digits');

    setState(() => _isOtpLoading = true);
    final result = await _authService.sendOtp(phone);
    setState(() => _isOtpLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      // Navigate to OTP screen; pass devOtp so it can be shown on screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phoneNumber: phone,
            devOtp: result['dev_otp'] as String? ?? '',
          ),
        ),
      );
    } else {
      // Could not reach server
      _showError(result['message'] ?? 'Could not send OTP. Try again.');
    }
  }

  // ── PASSWORD LOGIN ────────────────────────────────────────────────────────
  Future<void> _loginWithPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) return _showError('Please enter your email');
    if (!email.contains('@')) return _showError('Enter a valid email');
    if (password.isEmpty) return _showError('Please enter your password');
    if (password.length < 6) {
      return _showError('Password must be at least 6 characters');
    }

    setState(() => _isPasswordLoading = true);
    // POST /api/login-password — returns token + user { role }
    final result = await _authService.loginWithPassword(email, password);
    setState(() => _isPasswordLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      await context.read<ProfileProvider>().refresh();
      if (!mounted) return;
      _showSuccess('Login successful!');
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _navigateToHome();
    } else {
      _showError(result['message'] ?? 'Login failed');
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    final result = await _authService.loginWithGoogle();
    if (mounted) setState(() => _isGoogleLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      await context.read<ProfileProvider>().refresh();
      if (!mounted) return;
      _showSuccess('Login successful!');
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _navigateToHome();
    } else {
      _showError(result['message'] ?? 'Google login failed');
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Welcome To ASTROZURA',
          style: TextStyle(
            color: Color(0xFF6C63FF),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
              // Logo
              Image.asset('assets/images/logo.png', width: 110, height: 110),

              // Heading
              Text(
                'Step into the Light',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2E2A72),
                ),
              ),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Access your daily insights and connect with your spiritual guides.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFDE9F2A),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── TAB BAR ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EFF8),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: const Color(0xFF2E2A72),
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Text('🔢 '), Text('OTP Login')],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Text('🔒 '), Text('Password')],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── TAB VIEWS ─────────────────────────────────────────────
              SizedBox(
                height: 320,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOtpTab(),
                    _buildPasswordTab(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── DIVIDER ───────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                      child: Container(height: 1, color: Colors.grey.shade300)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR CONTINUE WITH',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9E9E9E),
                        letterSpacing: 1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                      child: Container(height: 1, color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 16),

              // ── GOOGLE BUTTON ─────────────────────────────────────────
              InkWell(
                onTap: _isGoogleLoading ? null : _loginWithGoogle,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _isGoogleLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/images/google.png',
                                height: 20, width: 20),
                            const SizedBox(width: 10),
                            const Text(
                              'Sign in with Google',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ── TERMS ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
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

  // ── OTP TAB ───────────────────────────────────────────────────────────────
  Widget _buildOtpTab() {
    return Column(
      children: [
        const Text(
          'Enter your mobile number to receive a one-time password',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.black45),
        ),
        const SizedBox(height: 20),
        _buildPhoneField(),
        const SizedBox(height: 24),

        // ── SEND OTP BUTTON ───────────────────────────────────────────
        GestureDetector(
          onTap: _isOtpLoading ? null : _sendOtp,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF2E2A72),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: _isOtpLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Send OTP →',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ── REGISTER LINK ─────────────────────────────────────────────
        GestureDetector(
          onTap: _goToRegister,
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black45),
              children: [
                const TextSpan(text: "New here? "),
                TextSpan(
                  text: 'Create your account',
                  style: TextStyle(
                    color: const Color(0xFF2E2A72),
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFF2E2A72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── PASSWORD TAB ──────────────────────────────────────────────────────────
  Widget _buildPasswordTab() {
    return Column(
      children: [
        const Text(
          'Sign in with your email and password',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.black45),
        ),
        const SizedBox(height: 20),
        _buildInputField(
          label: 'Email Address',
          hint: 'you@example.com',
          controller: _emailController,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _buildPasswordField(),
        const SizedBox(height: 20),

        // ── SIGN IN BUTTON ────────────────────────────────────────────
        GestureDetector(
          onTap: _isPasswordLoading ? null : _loginWithPassword,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF2E2A72),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: _isPasswordLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Sign In →',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ── REGISTER LINK ─────────────────────────────────────────────
        GestureDetector(
          onTap: _goToRegister,
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black45),
              children: [
                const TextSpan(text: "New here? "),
                TextSpan(
                  text: 'Create your account',
                  style: TextStyle(
                    color: const Color(0xFF2E2A72),
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFF2E2A72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── REUSABLE INPUT WIDGETS ────────────────────────────────────────────────
  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.black87)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F0ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  fontSize: 12, color: Colors.grey, letterSpacing: 0.5),
              border: InputBorder.none,
              prefixIcon: Icon(icon, size: 18, color: Colors.grey),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mobile Number',
            style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.black87)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F0ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text('+91',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: Colors.black87)),
              ),
              Container(width: 1, height: 38, color: Colors.grey.shade300),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'ENTER YOUR MOBILE NUMBER',
                    hintStyle: TextStyle(
                        fontSize: 12, color: Colors.grey, letterSpacing: 0.5),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Password',
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Colors.black87)),
            GestureDetector(
              onTap: () {
                // TODO: Forgot password screen
              },
              child: const Text('Forgot?',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFDE9F2A),
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F0ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
              border: InputBorder.none,
              prefixIcon:
                  const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
