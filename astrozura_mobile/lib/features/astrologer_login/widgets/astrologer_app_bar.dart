// import 'package:flutter/material.dart';

// import '../widgets/astrologer_nav_shell.dart';

// class AstrologerAppBar extends StatelessWidget {
//   final String? profileImage;

//   const AstrologerAppBar({
//     super.key,
//     this.profileImage,
//   });

//   Widget _fallbackProfile() {
//     return const Icon(
//       Icons.person_rounded,
//       color: Color(0xFF243B63),
//       size: 22,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.only(
//         left: 10,
//         right: 18,
//         top: 5,
//         bottom: 6,
//       ),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         border: Border(
//           bottom: BorderSide(
//             color: Color(0xFFE6E8EC),
//             width: 1,
//           ),
//         ),
//       ),
//       child: SafeArea(
//         bottom: false,
//         child: Row(
//           mainAxisAlignment:
//               MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               children: [
//                 Image.asset(
//                   "assets/images/logo.png",
//                   height: 60,
//                   fit: BoxFit.contain,
//                 ),
//                 const SizedBox(width: 2),
//                 const Text(
//                   "Astrozura",
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.w800,
//                     letterSpacing: 0.2,
//                     color: Color(0xFF243B63),
//                   ),
//                 ),
//               ],
//             ),

//             InkWell(
//               borderRadius:
//                   BorderRadius.circular(50),
//               onTap: () {
//                 AstrologerNavShell.of(context)
//                     .goTo(3);
//               },
//               child: Container(
//                 width: 44,
//                 height: 44,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color:
//                         const Color(0xFFE5E7EB),
//                   ),
//                 ),
//                 child: ClipOval(
//                   child: profileImage != null &&
//                           profileImage!
//                               .trim()
//                               .isNotEmpty
//                       ? Image.network(
//                           profileImage!,
//                           fit: BoxFit.cover,
//                           errorBuilder: (
//                             context,
//                             error,
//                             stackTrace,
//                           ) {
//                             return _fallbackProfile();
//                           },
//                         )
//                       : _fallbackProfile(),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }