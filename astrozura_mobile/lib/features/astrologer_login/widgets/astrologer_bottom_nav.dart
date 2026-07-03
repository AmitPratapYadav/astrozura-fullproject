// // lib/widgets/astrologer/astrologer_bottom_nav.dart
// //
// // PURE UI — no navigation logic here.
// // This widget only draws the bar; the shell drives it.

// import 'package:flutter/material.dart';

// class AstrologerBottomNav extends StatelessWidget {
//   final int currentIndex;
//   final ValueChanged<int> onTap;
//   final int bookingsBadge;

//   const AstrologerBottomNav({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//     this.bookingsBadge = 0,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final items = [
//       _AstrologerNavItem(
//         icon: Icons.home_outlined,
//         activeIcon: Icons.home_rounded,
//         label: 'Home',
//       ),
//       _AstrologerNavItem(
//         icon: Icons.calendar_today_outlined,
//         activeIcon: Icons.calendar_today_rounded,
//         label: 'Bookings',
//         badge: bookingsBadge,
//       ),
//       _AstrologerNavItem(
//         icon: Icons.construction_outlined,
//         activeIcon: Icons.history_rounded,
//         label: 'History',
//       ),
//       _AstrologerNavItem(
//         icon: Icons.person_outline_rounded,
//         activeIcon: Icons.person_rounded,
//         label: 'Profile',
//       ),
//     ];

//     return Container(
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
//       ),
//       child: SafeArea(
//         top: false,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           child: Row(
//             children: List.generate(items.length, (index) {
//               final item = items[index];
//               final isActive = currentIndex == index;

//               return Expanded(
//                 child: InkWell(
//                   onTap: () => onTap(index),
//                   splashColor: Colors.transparent,
//                   highlightColor: Colors.transparent,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Stack(
//                         clipBehavior: Clip.none,
//                         children: [
//                           Icon(
//                             isActive ? item.activeIcon : item.icon,
//                             size: 27,
//                             color: isActive
//                                 ? const Color(0xFF243B63)
//                                 : const Color(0xFF6B7280),
//                           ),
//                           if ((item.badge ?? 0) > 0)
//                             Positioned(
//                               top: -6,
//                               right: -7,
//                               child: Container(
//                                 width: 16,
//                                 height: 16,
//                                 decoration: const BoxDecoration(
//                                   color: Color(0xFFEF4444),
//                                   shape: BoxShape.circle,
//                                 ),
//                                 alignment: Alignment.center,
//                                 child: Text(
//                                   item.badge! > 9 ? '9+' : '${item.badge}',
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 9,
//                                     fontWeight: FontWeight.w800,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         item.label,
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight:
//                               isActive ? FontWeight.w800 : FontWeight.w500,
//                           color: isActive
//                               ? const Color(0xFF243B63)
//                               : const Color(0xFF6B7280),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             }),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _AstrologerNavItem {
//   final IconData icon;
//   final IconData activeIcon;
//   final String label;
//   final int? badge;

//   const _AstrologerNavItem({
//     required this.icon,
//     required this.activeIcon,
//     required this.label,
//     this.badge,
//   });
// }