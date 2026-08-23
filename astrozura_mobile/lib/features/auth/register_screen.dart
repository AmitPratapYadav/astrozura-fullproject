// lib/screens/auth/register_screen.dart
//
// Fields match Laravel ApiAuthController@register EXACTLY:
//   firstName (required), lastName (nullable), email, password
// NO phone field — Laravel doesn't validate phone on register.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/auth_services.dart';
import '../main_navigation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    ));
  }

  // ── SUBMIT ────────────────────────────────────────────────────────────────

  Future<void> _register() async {
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    // Validate
    if (firstName.isEmpty) return _showError('Please enter your first name');
    if (email.isEmpty || !email.contains('@')) {
      return _showError('Enter a valid email address');
    }
    if (password.length < 6) {
      return _showError('Password must be at least 6 characters');
    }
    if (password != confirm) return _showError('Passwords do not match');
    if (!_agreedToTerms) {
      return _showError('Please agree to Terms & Privacy Policy');
    }

    setState(() => _isLoading = true);

    final result = await _authService.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSuccess('Welcome to Astro Zura! ✨');
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => const MainNavigation(initialIndex: 0)),
      );
    } else {
      _showError(result['message'] ?? 'Registration failed. Try again.');
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
          'Create Account',
          style: TextStyle(
            color: Color(0xFF6C63FF),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          children: [
            // ── LOGO + HEADING ─────────────────────────────────────────
            const SizedBox(height: 8),
            Image.asset('assets/images/logo.png', width: 90, height: 90),
            Text(
              'Join Astro Zura',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF2E2A72),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Begin your cosmic journey today.',
              style: TextStyle(fontSize: 13, color: Color(0xFFDE9F2A)),
            ),

            const SizedBox(height: 28),

            // ── FORM CARD ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F6F3),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Personal Info'),
                  const SizedBox(height: 14),

                  // First + Last name row
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          label: 'First Name *',
                          hint: 'First name',
                          controller: _firstNameCtrl,
                          icon: Icons.person_outline,
                          capitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          label: 'Last Name',
                          hint: 'Last name',
                          controller: _lastNameCtrl,
                          icon: Icons.person_outline,
                          capitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _buildField(
                    label: 'Email Address *',
                    hint: 'you@example.com',
                    controller: _emailCtrl,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 22),
                  _sectionLabel('Set Password'),
                  const SizedBox(height: 14),

                  _buildPasswordField(
                    label: 'Password *',
                    hint: 'Min. 6 characters',
                    controller: _passwordCtrl,
                    obscure: _obscurePassword,
                    onToggle: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),

                  const SizedBox(height: 14),

                  _buildPasswordField(
                    label: 'Confirm Password *',
                    hint: 'Re-enter your password',
                    controller: _confirmCtrl,
                    obscure: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── TERMS ─────────────────────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _agreedToTerms
                          ? const Color(0xFF2E2A72)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _agreedToTerms
                            ? const Color(0xFF2E2A72)
                            : Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                    child: _agreedToTerms
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.black54, height: 1.5),
                        children: [
                          TextSpan(text: 'I agree to Astro Zura\'s '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: Color(0xFF2E2A72),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: Color(0xFF2E2A72),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── REGISTER BUTTON ───────────────────────────────────────
            GestureDetector(
              onTap: _isLoading ? null : _register,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: _isLoading
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF2E2A72), Color(0xFF4A44A0)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  color: _isLoading
                      ? const Color(0xFF2E2A72).withOpacity(0.6)
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFF2E2A72).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Create Account',
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Color(0xFFD4A73A), size: 18),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── SIGN IN LINK ──────────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 13.5, color: Colors.black45),
                  children: [
                    TextSpan(text: 'Already have an account?  '),
                    TextSpan(
                      text: 'Sign In',
                      style: TextStyle(
                        color: Color(0xFF2E2A72),
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── REUSABLE WIDGETS ──────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFD4A73A),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.playfairDisplay(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2E2A72),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Color(0xFF444466))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0DFEF)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: capitalization,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1C1756)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
              border: InputBorder.none,
              prefixIcon: Icon(icon, size: 16, color: const Color(0xFF9090C0)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Color(0xFF444466))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0DFEF)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1C1756)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.lock_outline,
                  size: 16, color: Color(0xFF9090C0)),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                  color: const Color(0xFF9090C0),
                ),
                onPressed: onToggle,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            ),
          ),
        ),
      ],
    );
  }
}
