// // lib/screens/mainwidgets/astrologer_nav_shell.dart

// import 'package:flutter/material.dart';

// import '../../../core/models/astrologer/astrologer_model.dart';
// import '../astrologer_home_screen.dart';
// import '../astrologer_booking_screen.dart';
// import 'astrologer_bottom_nav.dart';
// import '../astrologer_history_screen.dart';
// import '../astrologer_profile_screen.dart';

// class AstrologerNavShell extends StatefulWidget {
//   final AstrologerModel astrologer;
//   final int initialIndex;

//   const AstrologerNavShell({
//     super.key,
//     required this.astrologer,
//     this.initialIndex = 0,
//   });

//   static _AstrologerNavShellState of(BuildContext context) {
//     final state =
//         context.findAncestorStateOfType<_AstrologerNavShellState>();

//     assert(
//       state != null,
//       'AstrologerNavShell.of(context) called outside shell',
//     );

//     return state!;
//   }

//   @override
//   State<AstrologerNavShell> createState() =>
//       _AstrologerNavShellState();
// }

// class _AstrologerNavShellState
//     extends State<AstrologerNavShell> {
//   late int _currentIndex;

//   int _bookingsBadge = 0;

//   @override
//   void initState() {
//     super.initState();
//     _currentIndex = widget.initialIndex;
//   }

//   void goTo(int index) {
//     setState(() {
//       _currentIndex = index;
//     });
//   }

//   void setBookingsBadge(int count) {
//     setState(() {
//       _bookingsBadge = count;
//     });
//   }

//   late final List<Widget> _pages = [
//   AstrologerHomeScreen(
//     astrologer: widget.astrologer,
//   ),

//   const BookingsScreen(),

//   const AstrologerHistoryScreen(),

//   AstrologerProfileScreen(astrologer: widget.astrologer),  // ← fixed
// ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F7),

//       extendBody: true,

//       body: SafeArea(
//         bottom: false,
//         child: IndexedStack(
//           index: _currentIndex,
//           children: _pages,
//         ),
//       ),

//       bottomNavigationBar: AstrologerBottomNav(
//         currentIndex: _currentIndex,

//         bookingsBadge: _bookingsBadge,

//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//       ),
//     );
//   }
// }

// class _PlaceholderPage extends StatelessWidget {
//   final String label;

//   const _PlaceholderPage({
//     required this.label,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F7),

//       body: Center(
//         child: Text(
//           label,
//           style: const TextStyle(
//             fontSize: 26,
//             fontWeight: FontWeight.w800,
//             color: Color(0xFF243B63),
//           ),
//         ),
//       ),
//     );
//   }
// }