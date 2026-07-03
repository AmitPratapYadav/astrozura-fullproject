// // lib/screens/astrologer/astrologer_profile_screen.dart
// //
// // UI pixel-matched to the attached design image.
// // Functionality unchanged — all AstrologerModel fields used correctly.

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import '../../core/models/astrologer/astrologer_model.dart';
// import '../../core/services/auth_services.dart';
// import '../../core/services/api_services.dart';
// import '../auth/astrologer_login_screen.dart';

// class AstrologerProfileScreen extends StatefulWidget {
//   final AstrologerModel astrologer;

//   const AstrologerProfileScreen({
//     super.key,
//     required this.astrologer,
//   });

//   @override
//   State<AstrologerProfileScreen> createState() =>
//       _AstrologerProfileScreenState();
// }

// class _AstrologerProfileScreenState
//     extends State<AstrologerProfileScreen> {
//   // ── Controllers ──────────────────────────────────────────────────────────

//   final _formKey = GlobalKey<FormState>();

//   late final TextEditingController _firstNameCtrl;
//   late final TextEditingController _lastNameCtrl;
//   late final TextEditingController _emailCtrl;
//   late final TextEditingController _experienceCtrl;
//   late final TextEditingController _languagesCtrl;
//   late final TextEditingController _specialitiesCtrl;
//   late final TextEditingController _chatPriceCtrl;
//   late final TextEditingController _callPriceCtrl;
//   late final TextEditingController _bioCtrl;

//   // ── State ────────────────────────────────────────────────────────────────

//   bool _isLoading = true;
//   bool _isSaving = false;
//   String _profileImageUrl = '';
//   String _displayName = '';
//   String _heroSubtitle = '';

//   // ── Lifecycle ────────────────────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();

//     final fullName =
//     widget.astrologer.name.trim();

// final parts =
//     fullName.isEmpty
//         ? <String>[]
//         : fullName.split(' ');
//     _firstNameCtrl =
//         TextEditingController(text: parts.isNotEmpty ? parts.first : '');
//     _lastNameCtrl = TextEditingController(
//         text: parts.length > 1 ? parts.sublist(1).join(' ') : '');
//     _emailCtrl =
//         TextEditingController(text: widget.astrologer.email ?? '');
//     _experienceCtrl = TextEditingController(
//         text: widget.astrologer.experienceYears > 0
//             ? widget.astrologer.experienceYears.toString()
//             : '');
//     _languagesCtrl =
//         TextEditingController(text: widget.astrologer.languages);
//     _specialitiesCtrl =
//         TextEditingController(text: widget.astrologer.specialities);
//     _chatPriceCtrl = TextEditingController(
//         text: widget.astrologer.chatPrice > 0
//             ? widget.astrologer.chatPrice.toStringAsFixed(2)
//             : '');
//     _callPriceCtrl = TextEditingController(
//         text: widget.astrologer.callPrice > 0
//             ? widget.astrologer.callPrice.toStringAsFixed(2)
//             : '');
//     _bioCtrl =
//         TextEditingController(text: widget.astrologer.aboutBio);

//     _profileImageUrl = widget.astrologer.profileImage;
//     _displayName = widget.astrologer.name;
//     _heroSubtitle = _deriveSubtitle(widget.astrologer.specialities);

//     _loadFromCache();
//   }

//   @override
//   void dispose() {
//     _firstNameCtrl.dispose();
//     _lastNameCtrl.dispose();
//     _emailCtrl.dispose();
//     _experienceCtrl.dispose();
//     _languagesCtrl.dispose();
//     _specialitiesCtrl.dispose();
//     _chatPriceCtrl.dispose();
//     _callPriceCtrl.dispose();
//     _bioCtrl.dispose();
//     super.dispose();
//   }

//   // ── Helpers ───────────────────────────────────────────────────────────────

//   String _deriveSubtitle(String specialities) {
//     final first = specialities.split(',').first.trim();
//     return first.isNotEmpty ? first : 'Certified Astrologer';
//   }

//   void _showSnack(String msg, {bool isSuccess = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor:
//             isSuccess ? const Color(0xFF059669) : const Color(0xFFEF4444),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }

//   // ── Data ─────────────────────────────────────────────────────────────────

//   Future<void> _loadFromCache() async {
//     setState(() => _isLoading = true);
//     try {
//       final cached = await AuthService.getSavedAstrologer();
//       final cachedName =
//     cached['name']?.toString();

//     debugPrint('CACHE DATA: $cached');
// debugPrint(
//   'CACHE NAME: ${cached['name']}',
// );

// final fullName =
//     (cachedName != null &&
//             cachedName.trim().isNotEmpty)
//         ? cachedName
//         : widget.astrologer.name;
//       final parts = fullName.trim().split(' ');
//       final specialitiesRaw = cached['specialities']?.toString() ?? '';
//       final expRaw = cached['experience_years']?.toString() ?? '';
//       final chatRaw = cached['chat_price']?.toString() ?? '';
//       final callRaw = cached['call_price']?.toString() ?? '';

//       setState(() {
//         if (parts.isNotEmpty &&
//     parts.first.trim().isNotEmpty) {
//   _firstNameCtrl.text = parts.first;
// }
//         _lastNameCtrl.text = parts.length > 1
//             ? parts.sublist(1).join(' ')
//             : _lastNameCtrl.text;
//         _emailCtrl.text =
//             cached['email']?.toString() ?? _emailCtrl.text;
//         if (expRaw.isNotEmpty) _experienceCtrl.text = expRaw;
//         if (cached['languages'] != null)
//           _languagesCtrl.text = cached['languages'].toString();
//         if (specialitiesRaw.isNotEmpty)
//           _specialitiesCtrl.text = specialitiesRaw;
//         if (chatRaw.isNotEmpty) _chatPriceCtrl.text = chatRaw;
//         if (callRaw.isNotEmpty) _callPriceCtrl.text = callRaw;
//         if (cached['about_bio'] != null)
//           _bioCtrl.text = cached['about_bio'].toString();
//         _profileImageUrl =
//             cached['profile_image']?.toString() ?? _profileImageUrl;
//         _displayName = fullName;
//         _heroSubtitle = _deriveSubtitle(
//           specialitiesRaw.isNotEmpty
//               ? specialitiesRaw
//               : widget.astrologer.specialities,
//         );
//         _isLoading = false;
//       });
//     } catch (_) {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _logout() async {
//   final shouldLogout = await showDialog<bool>(
//     context: context,
//     builder: (context) {
//       return AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         title: const Text('Logout'),
//         content: const Text(
//           'Are you sure you want to logout?',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//             ),
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Logout'),
//           ),
//         ],
//       );
//     },
//   );

//   if (shouldLogout != true) return;

//   try {
//     await AuthService.logout();

//     if (!mounted) return;

//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(
//         builder: (_) => const AstrologerLoginScreen(),
//       ),
//       (route) => false,
//     );
//   } catch (e) {
//     _showSnack('Failed to logout');
//   }
// }

//   Future<void> _saveProfile() async {
//   debugPrint(
//     'First Name: "${_firstNameCtrl.text}"',
//   );

//   if (!_formKey.currentState!.validate()) return;
//     setState(() => _isSaving = true);
//     try {
//       final token = await AuthService.getToken();
//       final payload = <String, dynamic>{
//   'first_name': _firstNameCtrl.text.trim(),
//   'last_name': _lastNameCtrl.text.trim(),
//   'name':
//       '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'
//           .trim(),

//   'email': _emailCtrl.text.trim(),

//   'experience_years':
//       _experienceCtrl.text.trim(),

//   'languages':
//       _languagesCtrl.text.trim(),

//   'specialities':
//       _specialitiesCtrl.text.trim(),

//   'chat_price':
//       _chatPriceCtrl.text.trim(),

//   'call_price':
//       _callPriceCtrl.text.trim(),

//   'about_bio':
//       _bioCtrl.text.trim(),
// };
// debugPrint(
//   'PROFILE PAYLOAD => ${jsonEncode(payload)}',
// );
//       final response = await http
//           .post(
//             Uri.parse(
//                 '${ApiService.baseUrl}/astrologer/profile/update'),
//             headers: {
//               'Accept': 'application/json',
//               'Content-Type': 'application/json',
//               if (token != null && token.isNotEmpty)
//                 'Authorization': 'Bearer $token',
//             },
//             body: json.encode(payload),
//           )
//           .timeout(const Duration(seconds: 15));
//       debugPrint(
//   'STATUS CODE => ${response.statusCode}',
// );

// debugPrint(
//   'API RESPONSE => ${response.body}',
// );

// final decoded =
//     jsonDecode(response.body);
//       final ok = decoded['success'] == true ||
//           (response.statusCode >= 200 && response.statusCode < 300);
//       if (ok) {
//         final newName =
//             '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'
//                 .trim();
//         setState(() {
//           _displayName = newName;
//           _heroSubtitle =
//               _deriveSubtitle(_specialitiesCtrl.text.trim());
//         });
//         if (mounted)
//           _showSnack('Profile updated successfully ✓', isSuccess: true);
//       } else {
//         String errorMessage =
//     decoded['message']?.toString() ??
//     'Update failed';

// if (decoded['errors'] != null) {
//   final errors =
//       decoded['errors'] as Map<String, dynamic>;

//   errorMessage = errors.values
//       .expand((e) => e)
//       .join('\n');
// }

// throw Exception(errorMessage);
//       }
//     } catch (e) {
//       if (mounted)
//         _showSnack(e.toString().replaceFirst('Exception: ', ''));
//     } finally {
//       if (mounted) setState(() => _isSaving = false);
//     }
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   // BUILD
//   // ─────────────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//        resizeToAvoidBottomInset: true,
//       backgroundColor: const Color(0xFFF9FAFB),
//       appBar: _buildAppBar(),
//       body: _isLoading ? _buildLoader() : _buildBody(),
//     );
//   }

//   // ── App Bar ───────────────────────────────────────────────────────────────
//   // White bg, centered title in navy, back arrow icon, 1px bottom divider

//   PreferredSizeWidget _buildAppBar() {
//   return AppBar(
//     backgroundColor: Colors.white,
//     elevation: 0,
//     surfaceTintColor: Colors.transparent,
//     centerTitle: true,

//     title: const Text(
//       'Manage Profile',
//       style: TextStyle(
//         fontSize: 18,
//         fontWeight: FontWeight.w800,
//         color: Color(0xFF243B63),
//       ),
//     ),

//     actions: [
//       Padding(
//         padding: const EdgeInsets.only(right: 12),
//         child: GestureDetector(
//           onTap: _logout,
//           child: Container(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 12,
//               vertical: 8,
//             ),
//             decoration: BoxDecoration(
//               color: Colors.red.withOpacity(0.08),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: const Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   Icons.logout_rounded,
//                   size: 18,
//                   color: Colors.red,
//                 ),
//                 SizedBox(width: 4),
//                 Text(
//                   'Logout',
//                   style: TextStyle(
//                     color: Colors.red,
//                     fontWeight: FontWeight.w700,
//                     fontSize: 13,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     ],

//     bottom: PreferredSize(
//       preferredSize: const Size.fromHeight(1),
//       child: Container(
//         height: 1,
//         color: const Color(0xFFE5E7EB),
//       ),
//     ),
//   );
// }

//   // ── Body ──────────────────────────────────────────────────────────────────

//   Widget _buildBody() {
//     return Form(
//       key: _formKey,
//       child: ListView(
//   padding: EdgeInsets.only(
//     bottom: MediaQuery.of(context).viewInsets.bottom + 30,
//   ),
//   keyboardDismissBehavior:
//       ScrollViewKeyboardDismissBehavior.onDrag,
//         children: [
//           // ── Hero card (banner + avatar) ──────────────────────────
//           _buildHeroCard(),

//           // Gap for the avatar that hangs below the card
//           const SizedBox(height: 56),

//           // ── Name + subtitle ──────────────────────────────────────
//           _buildNameDisplay(),

//           const SizedBox(height: 20),

//           // Full-width hairline divider
//           const Divider(
//             height: 1,
//             thickness: 1,
//             color: Color(0xFFE5E7EB),
//           ),

//           const SizedBox(height: 24),

//           // ── Account Details ──────────────────────────────────────
//           _buildSection(
//             title: 'Account Details',
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildField(
//                       label: 'First Name',
//                       isRequired: true,
//                       controller: _firstNameCtrl,
//                       hint: 'Dr. Aruna',
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _buildField(
//                       label: 'Last Name',
//                       controller: _lastNameCtrl,
//                       hint: 'Sharma',
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 14),
//               _buildField(
//                 label: 'Email Address',
//                 isRequired: true,
//                 controller: _emailCtrl,
//                 hint: 'email@example.com',
//                 prefixIcon: Icons.email_outlined,
//                 keyboardType: TextInputType.emailAddress,
//                 validator: (v) {
//                   if (v == null || v.trim().isEmpty)
//                     return 'Email is required';
//                   if (!v.contains('@')) return 'Enter a valid email';
//                   return null;
//                 },
//               ),
//             ],
//           ),

//           const SizedBox(height: 24),

//           // ── Professional Profile ─────────────────────────────────
//           _buildSection(
//             title: 'Professional Profile',
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildField(
//                       label: 'Experience',
//                       isRequired: true,
//                       controller: _experienceCtrl,
//                       hint: '22',
//                       prefixIcon: Icons.access_time_rounded,
//                       keyboardType: TextInputType.number,
//                       inputFormatters: [
//                         FilteringTextInputFormatter.digitsOnly
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _buildField(
//                       label: 'Languages',
//                       controller: _languagesCtrl,
//                       hint: 'English, Hindi',
//                       prefixIcon: Icons.language_rounded,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 14),
//               _buildField(
//                 label: 'Specialities',
//                 isRequired: true,
//                 controller: _specialitiesCtrl,
//                 hint: 'Vedic Astrology & Career Alignment',
//                 prefixIcon: Icons.person_search_rounded,
//               ),
//               const SizedBox(height: 14),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildField(
//                       label: 'Chat Price',
//                       isRequired: true,
//                       controller: _chatPriceCtrl,
//                       hint: '50.00',
//                       prefixIcon: Icons.chat_bubble_outline_rounded,
//                       keyboardType:
//                           const TextInputType.numberWithOptions(
//                               decimal: true),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _buildField(
//                       label: 'Call Price',
//                       isRequired: true,
//                       controller: _callPriceCtrl,
//                       hint: '60.00',
//                       prefixIcon: Icons.phone_outlined,
//                       keyboardType:
//                           const TextInputType.numberWithOptions(
//                               decimal: true),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),

//           const SizedBox(height: 24),

//           // ── About / Bio ──────────────────────────────────────────
//           _buildSection(
//             title: 'About / Bio',
//             children: [
//               const Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   'Personal Biography',
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: Color(0xFF6B7280),
//                     fontWeight: FontWeight.w400,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               TextFormField(
//                 controller: _bioCtrl,
//                 maxLines: 5,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   color: Color(0xFF1F2937),
//                 ),
//                 decoration: InputDecoration(
//                   hintText:
//                       'Tell clients about yourself and your expertise…',
//                   hintStyle: const TextStyle(
//                     fontSize: 14,
//                     color: Color(0xFF9CA3AF),
//                   ),
//                   filled: true,
//                   fillColor: Colors.white,
//                   contentPadding: const EdgeInsets.all(14),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide:
//                         const BorderSide(color: Color(0xFFE5E7EB)),
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide:
//                         const BorderSide(color: Color(0xFFE5E7EB)),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(
//                         color: Color(0xFF243B63), width: 1.5),
//                   ),
//                   errorBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide:
//                         const BorderSide(color: Color(0xFFEF4444)),
//                   ),
//                   focusedErrorBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(
//                         color: Color(0xFFEF4444), width: 1.5),
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 32),

//           // ── Save Changes button ──────────────────────────────────
//           Padding(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 20),
//             child: SizedBox(
//               width: double.infinity,
//               height: 54,
//               child: ElevatedButton(
//                 onPressed: _isSaving ? null : _saveProfile,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFE8A020),
//                   disabledBackgroundColor:
//                       const Color(0xFFE8A020).withOpacity(0.55),
//                   elevation: 0,
//                   shadowColor: Colors.transparent,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                 ),
//                 child: _isSaving
//                     ? const SizedBox(
//                         width: 22,
//                         height: 22,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2.5,
//                         ),
//                       )
//                     : const Text(
//                         'Save Changes',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w800,
//                           color: Colors.white,
//                           letterSpacing: 0.2,
//                         ),
//                       ),
//               ),
//             ),
//           ),

//           const SizedBox(height: 40),
//         ],
//       ),
//     );
//   }

//   // ── Hero Card ─────────────────────────────────────────────────────────────
//   // Rounded card with navy banner inside; avatar overlaps the bottom edge.

//   Widget _buildHeroCard() {
//     return Padding(
//       // 16px horizontal margin — matches the card look in the design
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           // Card: rounded, navy fill = the banner
//           Container(
//             width: double.infinity,
//             height: 110,
//             decoration: BoxDecoration(
//               color: const Color(0xFF243B63),
//               borderRadius: BorderRadius.circular(14),
//             ),
//           ),

//           // Avatar — centred, hangs 48px below the card bottom
//           Positioned(
//             bottom: -48,
//             left: 0,
//             right: 0,
//             child: Center(
//               child: Stack(
//                 clipBehavior: Clip.none,
//                 children: [
//                   // Circle avatar
//                   Container(
//                     width: 96,
//                     height: 96,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: const Color(0xFFE5E7EB),
//                       border: Border.all(
//                           color: Colors.white, width: 3.5),
//                       image: _profileImageUrl.isNotEmpty
//                           ? DecorationImage(
//                               image: NetworkImage(_profileImageUrl),
//                               fit: BoxFit.cover,
//                               onError: (_, __) {},
//                             )
//                           : null,
//                     ),
//                     child: _profileImageUrl.isEmpty
//                         ? const Icon(
//                             Icons.person_rounded,
//                             size: 48,
//                             color: Color(0xFF9CA3AF),
//                           )
//                         : null,
//                   ),

//                   // Amber camera badge — bottom-right of avatar
//                   Positioned(
//                     bottom: 0,
//                     right: 0,
//                     child: GestureDetector(
//                       onTap: () => _showSnack(
//                           'Image upload coming soon…',
//                           isSuccess: true),
//                       child: Container(
//                         width: 28,
//                         height: 28,
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFE8A020),
//                           shape: BoxShape.circle,
//                           border: Border.all(
//                               color: Colors.white, width: 2),
//                         ),
//                         child: const Icon(
//                           Icons.camera_alt_rounded,
//                           size: 14,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Name + Subtitle ───────────────────────────────────────────────────────

//   Widget _buildNameDisplay() {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text(
//           _displayName.isNotEmpty
//               ? _displayName
//               : widget.astrologer.name,
//           textAlign: TextAlign.center,
//           style: const TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w800,
//             color: Color(0xFF243B63),
//             letterSpacing: 0.1,
//           ),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           _heroSubtitle.toUpperCase(),
//           textAlign: TextAlign.center,
//           style: const TextStyle(
//             fontSize: 11,
//             fontWeight: FontWeight.w700,
//             color: Color(0xFFE8A020),
//             letterSpacing: 1.4,
//           ),
//         ),
//       ],
//     );
//   }

//   // ── Section ───────────────────────────────────────────────────────────────
//   // Amber 4px left-bar + bold navy title, then children below

//   Widget _buildSection({
//     required String title,
//     required List<Widget> children,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Title row
//           Row(
//             children: [
//               Container(
//                 width: 4,
//                 height: 20,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFE8A020),
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w800,
//                   color: Color(0xFF243B63),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           ...children,
//         ],
//       ),
//     );
//   }

//   // ── Field ─────────────────────────────────────────────────────────────────
//   // Gray label (+ red * if required), white rounded input with gray icon

//   Widget _buildField({
//     required String label,
//     required TextEditingController controller,
//     bool isRequired = false,
//     String? hint,
//     IconData? prefixIcon,
//     TextInputType? keyboardType,
//     List<TextInputFormatter>? inputFormatters,
//     String? Function(String?)? validator,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // Label row
//         Row(
//           children: [
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//                 color: Color(0xFF6B7280),
//               ),
//             ),
//             if (isRequired)
//               const Text(
//                 ' *',
//                 style: TextStyle(
//                   fontSize: 13,
//                   color: Color(0xFFEF4444),
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//           ],
//         ),
//         const SizedBox(height: 6),
//         TextFormField(
//           controller: controller,
//           keyboardType: keyboardType,
//           inputFormatters: inputFormatters,
//           style: const TextStyle(
//             fontSize: 14,
//             color: Color(0xFF1F2937),
//           ),
//           validator: validator ??
//               (isRequired
//                   ? (v) => (v == null || v.trim().isEmpty)
//                       ? '$label is required'
//                       : null
//                   : null),
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: const TextStyle(
//               fontSize: 14,
//               color: Color(0xFF9CA3AF),
//             ),
//             prefixIcon: prefixIcon != null
//                 ? Padding(
//                     padding: const EdgeInsets.only(left: 12, right: 8),
//                     child: Icon(
//                       prefixIcon,
//                       size: 18,
//                       color: const Color(0xFF9CA3AF),
//                     ),
//                   )
//                 : null,
//             prefixIconConstraints: const BoxConstraints(
//               minWidth: 40,
//               minHeight: 0,
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             isDense: false,
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 14,
//               vertical: 13,
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide:
//                   const BorderSide(color: Color(0xFFE5E7EB)),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide:
//                   const BorderSide(color: Color(0xFFE5E7EB)),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(
//                   color: Color(0xFF243B63), width: 1.5),
//             ),
//             errorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide:
//                   const BorderSide(color: Color(0xFFEF4444)),
//             ),
//             focusedErrorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(
//                   color: Color(0xFFEF4444), width: 1.5),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ── Loader ────────────────────────────────────────────────────────────────

//   Widget _buildLoader() {
//     return const Center(
//       child: CircularProgressIndicator(
//         color: Color(0xFF243B63),
//         strokeWidth: 2.5,
//       ),
//     );
//   }
// }