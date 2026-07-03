// // lib/screens/auth/astrologer_login_screen.dart
// //
// // Astrologer login screen — matches reference UI exactly.
// // Purple gradient header with logo + portal badge.
// // White body with gold accents, email/password fields, Access Portal button.

// import 'package:flutter/material.dart';
// import '../astrologer_login/astrologer_home_screen.dart';
// import '../../core/services/auth_services.dart';
// import '../astrologer_login/widgets/astrologer_nav_shell.dart';
// import '../../core/models/astrologer/astrologer_model.dart';

// class AstrologerLoginScreen extends StatefulWidget {
//   const AstrologerLoginScreen({super.key});

//   @override
//   State<AstrologerLoginScreen> createState() => _AstrologerLoginScreenState();
// }

// class _AstrologerLoginScreenState extends State<AstrologerLoginScreen> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _obscurePassword = true;
//   bool _isLoading = false;

//   final AuthService _authService = AuthService();

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   void _showError(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(msg),
//       backgroundColor: Colors.red.shade700,
//       behavior: SnackBarBehavior.floating,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       margin: const EdgeInsets.all(16),
//     ));
//   }

//   Future<void> _login() async {
//     final email = _emailController.text.trim();
//     final password = _passwordController.text;

//     if (email.isEmpty) return _showError('Please enter your email');
//     if (!email.contains('@')) return _showError('Enter a valid email');
//     if (password.isEmpty) return _showError('Please enter your password');
//     if (password.length < 6) {
//       return _showError('Password must be at least 6 characters');
//     }

//     setState(() => _isLoading = true);
//     final result = await _authService.astrologerLogin(email, password);
//     setState(() => _isLoading = false);

//     if (!mounted) return;

//     if (result['success'] == true) {
//       final astrologerData =
//           result['astrologer'] as Map<String, dynamic>? ?? {};
//       final astrologer = AstrologerModel.fromJson(astrologerData);

//       // ✅ Correct — use the variable defined just above it
// // Clear the entire back stack so pressing Back never returns to login.
// Navigator.pushAndRemoveUntil(
//   context,
//   MaterialPageRoute(
//     builder: (_) => AstrologerNavShell(astrologer: astrologer),
//   ),
//   (route) => false,
// );
//     } else {
//       _showError(result['message'] ?? 'Login failed. Check credentials.');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           _buildHeader(context),
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 32),

//                   // ── Sign-in label ─────────────────────────────────
//                   Row(
//                     children: [
//                       Container(
//                         width: 3,
//                         height: 36,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(2),
//                           gradient: const LinearGradient(
//                             colors: [Color(0xFFD4AF37), Color(0xFFDE9F2A)],
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: const [
//                           Text(
//                             'SIGN IN',
//                             style: TextStyle(
//                               fontSize: 10,
//                               fontWeight: FontWeight.w700,
//                               color: Color(0xFFD4AF37),
//                               letterSpacing: 2,
//                             ),
//                           ),
//                           SizedBox(height: 2),
//                           Text(
//                             'Astrologer Credentials',
//                             style: TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.w700,
//                               color: Color(0xFF2E2A72),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 20),

//                   // ── Email ─────────────────────────────────────────
//                   _buildLabel('Email Address'),
//                   const SizedBox(height: 6),
//                   _buildInputField(
//                     controller: _emailController,
//                     hint: 'astrologer@example.com',
//                     icon: Icons.alternate_email_rounded,
//                     keyboardType: TextInputType.emailAddress,
//                   ),

//                   const SizedBox(height: 18),

//                   // ── Password ──────────────────────────────────────
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       _buildLabel('Password'),
//                       GestureDetector(
//                         onTap: () {},
//                         child: const Text(
//                           'Forgot Password?',
//                           style: TextStyle(
//                             fontSize: 13,
//                             color: Color(0xFFDE9F2A),
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//                   _buildPasswordField(),

//                   const SizedBox(height: 28),

//                   // ── Login button ──────────────────────────────────
//                   GestureDetector(
//                     onTap: _isLoading ? null : _login,
//                     child: Container(
//                       width: double.infinity,
//                       height: 54,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(16),
//                         gradient: const LinearGradient(
//                           colors: [Color(0xFF2E2A72), Color(0xFF1A1040)],
//                           begin: Alignment.centerLeft,
//                           end: Alignment.centerRight,
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: const Color(0xFF2E2A72).withOpacity(0.3),
//                             blurRadius: 14,
//                             offset: const Offset(0, 6),
//                           ),
//                         ],
//                       ),
//                       child: Center(
//                         child: _isLoading
//                             ? const SizedBox(
//                                 width: 22,
//                                 height: 22,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2.5,
//                                   color: Colors.white,
//                                 ),
//                               )
//                             : Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: const [
//                                   Text(
//                                     'Access Portal',
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 15,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                   SizedBox(width: 8),
//                                   Text(
//                                     '→',
//                                     style: TextStyle(
//                                       color: Color(0xFFD4AF37),
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 24),

//                   // ── Divider ───────────────────────────────────────
//                   Row(children: [
//                     Expanded(
//                         child: Container(height: 1, color: Colors.grey.shade200)),
//                     const Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 12),
//                       child: Text(
//                         'ASTROLOGER ONLY',
//                         style: TextStyle(
//                           fontSize: 10,
//                           color: Color(0xFF9E9E9E),
//                           letterSpacing: 1.2,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                     Expanded(
//                         child: Container(height: 1, color: Colors.grey.shade200)),
//                   ]),

//                   const SizedBox(height: 20),

//                   // ── Info box ──────────────────────────────────────
//                   Container(
//                     padding: const EdgeInsets.all(14),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFFFF8E8),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                           color: const Color(0xFFDE9F2A).withOpacity(0.3)),
//                     ),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: const [
//                         Icon(Icons.auto_awesome,
//                             size: 16, color: Color(0xFFDE9F2A)),
//                         SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             'Astrologer accounts are created by the admin. Contact support if you need access to this portal.',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Color(0xFFAD7A1A),
//                               height: 1.6,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 32),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Header ────────────────────────────────────────────────────────────────

//   Widget _buildHeader(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFF2E2A72), Color(0xFF1A1040)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.only(
//           bottomLeft: Radius.circular(32),
//           bottomRight: Radius.circular(32),
//         ),
//       ),
//       child: SafeArea(
//         bottom: false,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(8, 4, 20, 28),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.arrow_back_ios_new,
//                     color: Colors.white60, size: 18),
//                 onPressed: () => Navigator.pop(context),
//               ),
//               const SizedBox(height: 8),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         // App logo
//                         Container(
//                           width: 54,
//                           height: 54,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(12),
//                             color: Colors.white,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.15),
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 3),
//                               ),
//                             ],
//                           ),
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(12),
//                             child: Image.asset(
//                               'assets/images/logo.png',
//                               fit: BoxFit.cover,
//                               errorBuilder: (_, __, ___) => const Icon(
//                                 Icons.auto_awesome,
//                                 color: Color(0xFF2E2A72),
//                                 size: 28,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         // Portal badge
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 10, vertical: 5),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(20),
//                             color: Colors.white.withOpacity(0.1),
//                             border: Border.all(
//                                 color:
//                                     const Color(0xFFD4AF37).withOpacity(0.5)),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: const [
//                               Icon(Icons.auto_awesome,
//                                   size: 11, color: Color(0xFFD4AF37)),
//                               SizedBox(width: 5),
//                               Text(
//                                 'ASTROLOGER PORTAL',
//                                 style: TextStyle(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.w600,
//                                   color: Color(0xFFD4AF37),
//                                   letterSpacing: 1.2,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 18),
//                     const Text(
//                       'Astrologer Login',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 26,
//                         fontWeight: FontWeight.w700,
//                         letterSpacing: 0.2,
//                       ),
//                     ),
//                     const SizedBox(height: 5),
//                     Text(
//                       'Enter your credentials to access the portal',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.5),
//                         fontSize: 12.5,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 8),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ── Form helpers ──────────────────────────────────────────────────────────

//   Widget _buildLabel(String text) {
//     return Text(
//       text,
//       style: const TextStyle(
//         fontWeight: FontWeight.w500,
//         fontSize: 13,
//         color: Colors.black87,
//       ),
//     );
//   }

//   Widget _buildInputField({
//     required TextEditingController controller,
//     required String hint,
//     required IconData icon,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFFF1F0ED),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: TextField(
//         controller: controller,
//         keyboardType: keyboardType,
//         decoration: InputDecoration(
//           hintText: hint,
//           hintStyle: const TextStyle(
//               fontSize: 12, color: Colors.grey, letterSpacing: 0.5),
//           border: InputBorder.none,
//           prefixIcon: Icon(icon, size: 18, color: Colors.grey),
//           contentPadding:
//               const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//         ),
//       ),
//     );
//   }

//   Widget _buildPasswordField() {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFFF1F0ED),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: TextField(
//         controller: _passwordController,
//         obscureText: _obscurePassword,
//         decoration: InputDecoration(
//           hintText: 'Enter your secure password',
//           hintStyle:
//               const TextStyle(fontSize: 12, color: Colors.grey),
//           border: InputBorder.none,
//           prefixIcon: const Icon(Icons.lock_outline,
//               size: 18, color: Colors.grey),
//           suffixIcon: IconButton(
//             icon: Icon(
//               _obscurePassword
//                   ? Icons.visibility_off_outlined
//                   : Icons.visibility_outlined,
//               size: 18,
//               color: Colors.grey,
//             ),
//             onPressed: () =>
//                 setState(() => _obscurePassword = !_obscurePassword),
//           ),
//           contentPadding:
//               const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//         ),
//       ),
//     );
//   }
// }