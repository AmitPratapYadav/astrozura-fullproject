// // lib/screens/astrologer/astrologer_home_screen.dart

// import 'package:flutter/material.dart';

// import '../../core/models/astrologer/astrologer_booking_model.dart';
// import '../../core/models/astrologer/astrologer_model.dart';
// import '../../core/models/astrologer/dashboard_stats_model.dart';
// import '../../core/services/astrologer_service.dart';
// import 'widgets/booking_card.dart';
// import 'widgets/astrologer_nav_shell.dart';
// import '../../core/models/astrologer/activity_model.dart';

// class AstrologerHomeScreen extends StatefulWidget {
//   final AstrologerModel astrologer;

//   const AstrologerHomeScreen({
//     super.key,
//     required this.astrologer,
//   });

//   @override
//   State<AstrologerHomeScreen> createState() => _AstrologerHomeScreenState();
// }

// class _AstrologerHomeScreenState extends State<AstrologerHomeScreen> {
//   bool isLoading = true;
//   bool isCompleting = false;

//   DashboardStats? stats;

//   List<AstrologerBookingModel> upcomingBookings = [];

//   @override
//   void initState() {
//     super.initState();
//     loadDashboard();
//   }

//   List<ActivityModel> recentActivities = [];

//   Widget _fallbackProfile() {
//     return Container(
//       color: const Color(
//         0xFFE8EEF9,
//       ),
//       alignment: Alignment.center,
//       child: Text(
//         widget.astrologer.name[0].toUpperCase(),
//         style: const TextStyle(
//           color: Color(0xFF243B63),
//           fontWeight: FontWeight.w800,
//           fontSize: 16,
//         ),
//       ),
//     );
//   }
//   // =====================================================
// // DYNAMIC GREETING
// // =====================================================

//   String _getGreetingMessage() {
//     final hour = DateTime.now().hour;

//     if (hour < 12) {
//       return "Good morning,";
//     } else if (hour < 17) {
//       return "Good afternoon,";
//     } else {
//       return "Good evening,";
//     }
//   }

// // =====================================================
// // FEATURED CHECK
// // =====================================================

//   bool _isFeatured() {
//     // IF YOU HAVE FEATURED FIELD IN API
//     // RETURN THAT HERE

//     // Example:
//     // return widget.astrologer.isFeatured;

//     // TEMP STATIC
//     return true;
//   }

//   String _capitalizeEachWord(String text) {
//     if (text.trim().isEmpty) return "";

//     return text
//         .trim()
//         .split(' ')
//         .map(
//           (word) => word.isEmpty
//               ? ''
//               : word[0].toUpperCase() + word.substring(1).toLowerCase(),
//         )
//         .join(' ');
//   }

// // =====================================================
// // TODAY GROWTH TEXT
// // =====================================================

//   String _todayGrowthText() {
//     if (stats == null) {
//       return "No data";
//     }

//     final growth = stats!.todayGrowth;

//     if (growth > 0) {
//       return "+$growth from yesterday";
//     }

//     if (growth < 0) {
//       return "$growth from yesterday";
//     }

//     return "Same as yesterday";
//   }

// // =====================================================
// // REVENUE GROWTH TEXT
// // =====================================================

//   String _revenueGrowthText() {
//     if (stats == null) {
//       return "No growth data";
//     }

//     final growth = stats!.revenueGrowthPercent;

//     if (growth > 0) {
//       return "${growth.toStringAsFixed(0)}% growth";
//     }

//     if (growth < 0) {
//       return "${growth.toStringAsFixed(0)}% down";
//     }

//     return "No change";
//   }

// // =====================================================
// // FORMAT REVENUE
// // =====================================================

//   String _formatRevenue(double amount) {
//     return amount.toStringAsFixed(0).replaceAllMapped(
//           RegExp(r'\B(?=(\d{3})+(?!\d))'),
//           (match) => ",",
//         );
//   }
//   // =========================================================
//   // LOAD DASHBOARD DATA
//   // =========================================================

//   Future<void> loadDashboard() async {
//     try {
//       setState(() {
//         isLoading = true;
//       });

//       final data = await AstrologerService.getBookings();

//       final loadedBookings =
//           data['upcoming'] as List<AstrologerBookingModel>? ?? [];

//       final loadedStats = data['stats'] as DashboardStats?;

//       final activities = data['activities'] as List<ActivityModel>? ?? [];

//       if (!mounted) return;

//       setState(() {
//         upcomingBookings = loadedBookings;
//         stats = loadedStats;
//         recentActivities = activities;
//         isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isLoading = false;
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.red.shade400,
//           content: Text(
//             e.toString(),
//           ),
//         ),
//       );
//     }
//   }

//   // =========================================================
//   // MARK BOOKING COMPLETE
//   // =========================================================

//   Future<void> markBookingComplete(
//     AstrologerBookingModel booking,
//   ) async {
//     try {
//       setState(() {
//         isCompleting = true;
//       });

//       await AstrologerService.markComplete(
//         booking.id,
//       );

//       await loadDashboard();

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Booking marked completed"),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.red,
//           content: Text(
//             e.toString(),
//           ),
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           isCompleting = false;
//         });
//       }
//     }
//   }

//   // =========================================================
//   // UI
//   // =========================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F7),

//       body: SafeArea(
//         child: RefreshIndicator(
//           onRefresh: loadDashboard,
//           child: SingleChildScrollView(
//             physics: const AlwaysScrollableScrollPhysics(),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // =====================================================
// // HEADER
// // =====================================================

//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.only(
//                     left: 10,
//                     right: 18,
//                     top: 5,
//                     bottom: 6,
//                   ),
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                     border: Border(
//                       bottom: BorderSide(
//                         color: Color(0xFFE6E8EC),
//                         width: 1,
//                       ),
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       // =================================================
//                       // LOGO + APP NAME
//                       // =================================================

//                       Row(
//                         children: [
//                           Image.asset(
//                             "assets/images/logo.png",
//                             height: 60,
//                             fit: BoxFit.contain,
//                           ),
//                           const SizedBox(width: 2),
//                           const Text(
//                             "Astrozura",
//                             style: TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.w800,
//                               letterSpacing: 0.2,
//                               color: Color(0xFF243B63),
//                             ),
//                           ),
//                         ],
//                       ),

//                       // =================================================
//                       // PROFILE
//                       // =================================================

//                       InkWell(
//                         borderRadius: BorderRadius.circular(50),
//                         onTap: () {
//                           AstrologerNavShell.of(context).goTo(3);
//                         },
//                         child: Container(
//                           width: 44,
//                           height: 44,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             border: Border.all(
//                               color: const Color(0xFFE5E7EB),
//                             ),
//                           ),
//                           child: ClipOval(
//                             child:
//                                 widget.astrologer.profileImage.trim().isNotEmpty
//                                     ? Image.network(
//                                         widget.astrologer.profileImage,
//                                         fit: BoxFit.cover,
//                                         errorBuilder: (
//                                           context,
//                                           error,
//                                           stackTrace,
//                                         ) {
//                                           return _fallbackProfile();
//                                         },
//                                       )
//                                     : _fallbackProfile(),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

// // =====================================================
// // GREETING SECTION
// // =====================================================

//                 Padding(
//                   padding: const EdgeInsets.only(
//                     left: 20,
//                     right: 20,
//                     top: 24,
//                   ),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // LEFT CONTENT
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // DYNAMIC GREETING
//                             Text(
//                               _getGreetingMessage(),
//                               style: const TextStyle(
//                                 fontSize: 24,
//                                 height: 1.25,
//                                 fontWeight: FontWeight.w800,
//                                 color: Color(0xFF243B63),
//                               ),
//                             ),

//                             const SizedBox(height: 2),

//                             // NAME
//                             Text(
//                               _capitalizeEachWord(
//                                 widget.astrologer.name,
//                               ),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(
//                                 fontSize: 35,
//                                 height: 1.25,
//                                 fontWeight: FontWeight.w800,
//                                 color: Color(0xFF243B63),
//                               ),
//                             ),

//                             const SizedBox(height: 10),

//                             // POSITION
//                             const Text(
//                               "ASTROLOGER",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 letterSpacing: 1.5,
//                                 color: Color(0xFF9CA3AF),
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),

//                             const SizedBox(height: 6),

//                             // SPECIALIZATION
//                             // Text(
//                             //   widget.astrologer.specialization
//                             //           .trim()
//                             //           .isEmpty
//                             //       ? "Certified Senior Astrologer"
//                             //       : widget.astrologer.specialization,
//                             //   style: const TextStyle(
//                             //     color: Color(0xFFE8A020),
//                             //     fontSize: 16,
//                             //     fontWeight: FontWeight.w600,
//                             //   ),
//                             // ),
//                           ],
//                         ),
//                       ),

//                       // FEATURED BADGE
//                       if (_isFeatured())
//                         Container(
//                           margin: const EdgeInsets.only(
//                             right: 80,
//                             top: 37,
//                           ),
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 7,
//                           ),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFFFFF7E8),
//                             borderRadius: BorderRadius.circular(30),
//                             border: Border.all(
//                               color: const Color(0xFFE8D4A2),
//                             ),
//                           ),
//                           child: const Text(
//                             "FEATURED",
//                             style: TextStyle(
//                               fontSize: 10,
//                               fontWeight: FontWeight.w700,
//                               color: Color(0xFF7C5A00),
//                               letterSpacing: 0.4,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 28),

//                 // =====================================================
// // STATS
// // =====================================================

//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                   ),
//                   child: Row(
//                     children: [
//                       // TODAY BOOKINGS
//                       Expanded(
//                         child: InkWell(
//                           borderRadius: BorderRadius.circular(24),
//                           onTap: () {
//                             AstrologerNavShell.of(context).goTo(1);
//                           },
//                           child: _buildStatCard(
//                             borderColor: const Color(
//                               0xFF243B63,
//                             ),
//                             title: "TODAY'S SESSIONS",
//                             value: "${stats?.todayBookings ?? 0}",
//                             subtitle: _todayGrowthText(),
//                             icon: Icons.calendar_today_outlined,
//                           ),
//                         ),
//                       ),

//                       const SizedBox(width: 14),

//                       // REVENUE
//                       Expanded(
//                         child: InkWell(
//                           borderRadius: BorderRadius.circular(24),
//                           onTap: () {
//                             AstrologerNavShell.of(context).goTo(2);
//                           },
//                           child: _buildStatCard(
//                             borderColor: const Color(
//                               0xFFE8A020,
//                             ),
//                             title: "MONTHLY REVENUE",
//                             value:
//                                 "₹${_formatRevenue(stats?.monthlyRevenue ?? 0)}",
//                             subtitle: _revenueGrowthText(),
//                             icon: Icons.trending_up_rounded,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 24),

//                 // =====================================================
//                 // UPCOMING SESSION HEADER
//                 // =====================================================

//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         "Upcoming Sessions",
//                         style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.w800,
//                           color: Color(0xFF243B63),
//                         ),
//                       ),
//                       InkWell(
//                         onTap: () {
//                           AstrologerNavShell.of(context).goTo(1);
//                         },
//                         child: const Text(
//                           "View All",
//                           style: TextStyle(
//                             color: Color(0xFFE8A020),
//                             fontWeight: FontWeight.w700,
//                             fontSize: 15,
//                           ),
//                         ),
//                       )
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 18),

//                 // =====================================================
//                 // BOOKINGS
//                 // =====================================================

//                 if (isLoading)
//                   const Padding(
//                     padding: EdgeInsets.only(top: 50),
//                     child: Center(
//                       child: CircularProgressIndicator(
//                         color: Color(0xFFE8A020),
//                       ),
//                     ),
//                   ),

//                 if (!isLoading && upcomingBookings.isEmpty)
//                   Padding(
//                     padding: const EdgeInsets.all(20),
//                     child: Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(
//                         30,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(
//                           18,
//                         ),
//                       ),
//                       child: const Column(
//                         children: [
//                           Icon(
//                             Icons.calendar_today,
//                             size: 45,
//                             color: Color(0xFFCBD5E1),
//                           ),
//                           SizedBox(height: 14),
//                           Text(
//                             "No upcoming sessions",
//                             style: TextStyle(
//                               color: Color(0xFF64748B),
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                 if (!isLoading && upcomingBookings.isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                     ),
//                     child: Column(
//                       children: upcomingBookings.map(
//                         (booking) {
//                           return BookingCard(
//                             booking: booking,
//                             onOpenChat: () {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(
//                                   content: Text(
//                                     "Opening chat with ${booking.userName}",
//                                   ),
//                                 ),
//                               );
//                             },
//                             onComplete: isCompleting
//                                 ? null
//                                 : () {
//                                     markBookingComplete(
//                                       booking,
//                                     );
//                                   },
//                           );
//                         },
//                       ).toList(),
//                     ),
//                   ),

//                 const SizedBox(height: 18),

//                 // =====================================================
// // RECENT ACTIVITY
// // =====================================================

//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                   ),
//                   child: Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(22),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF8F8F8),
//                       borderRadius: BorderRadius.circular(24),
//                       border: Border.all(
//                         color: const Color(
//                           0xFFE5E7EB,
//                         ),
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(
//                             0.02,
//                           ),
//                           blurRadius: 10,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // =================================================
//                         // HEADER
//                         // =================================================

//                         const Row(
//                           children: [
//                             Icon(
//                               Icons.history,
//                               size: 22,
//                               color: Color(0xFFE8A020),
//                             ),
//                             SizedBox(width: 10),
//                             Text(
//                               "Recent Activity",
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.w800,
//                                 color: Color(0xFF243B63),
//                               ),
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 28),

//                         // =================================================
//                         // EMPTY STATE
//                         // =================================================

//                         if (recentActivities.isEmpty)
//                           const Padding(
//                             padding: EdgeInsets.symmetric(
//                               vertical: 30,
//                             ),
//                             child: Center(
//                               child: Text(
//                                 "No recent activity",
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   color: Color(0xFF9CA3AF),
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ),

//                         // =================================================
//                         // ACTIVITIES
//                         // =================================================

//                         if (recentActivities.isNotEmpty)
//                           Column(
//                             children: List.generate(
//                               recentActivities.length,
//                               (index) {
//                                 final activity = recentActivities[index];

//                                 return Column(
//                                   children: [
//                                     _dynamicActivityTile(
//                                       activity,
//                                     ),
//                                     if (index != recentActivities.length - 1)
//                                       _activityDivider(),
//                                   ],
//                                 );
//                               },
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 100),
//               ],
//             ),
//           ),
//         ),
//       ),

//       // =========================================================
//       // BOTTOM NAVIGATION
//       // =========================================================
//     );
//   }

//   // =========================================================
//   // STAT CARD
//   // =========================================================

//   Widget _buildStatCard({
//     required Color borderColor,
//     required String title,
//     required String value,
//     required String subtitle,
//     required IconData icon,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(
//               0.04,
//             ),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 4,
//             height: 90,
//             decoration: BoxDecoration(
//               color: borderColor,
//               borderRadius: BorderRadius.circular(
//                 100,
//               ),
//             ),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         title,
//                         style: const TextStyle(
//                           fontSize: 11,
//                           color: Color(0xFF6B7280),
//                           fontWeight: FontWeight.w800,
//                         ),
//                       ),
//                     ),
//                     Icon(
//                       icon,
//                       size: 16,
//                       color: const Color(0xFF9CA3AF),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 14),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w900,
//                     color: Color(
//                       0xFF243B63,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   subtitle,
//                   style: const TextStyle(
//                     color: Color(0xFF6B7280),
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // =========================================================
//   // QUICK ACTION
//   // =========================================================

//   Widget _quickAction({
//     required IconData icon,
//     required String title,
//   }) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(
//         16,
//       ),
//       onTap: () {},
//       child: Column(
//         children: [
//           Container(
//             width: 58,
//             height: 58,
//             decoration: BoxDecoration(
//               color: const Color(
//                 0xFFF9FAFB,
//               ),
//               borderRadius: BorderRadius.circular(
//                 16,
//               ),
//               border: Border.all(
//                 color: const Color(
//                   0xFFD7DCE3,
//                 ),
//               ),
//             ),
//             child: Icon(
//               icon,
//               color: const Color(
//                 0xFF243B63,
//               ),
//               size: 28,
//             ),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 13,
//               color: Color(0xFF243B63),
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // =========================================================
//   // ACTIVITY TILE
//   // =========================================================

//   Widget _dynamicActivityTile(
//     ActivityModel activity,
//   ) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         vertical: 6,
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // DOT
//           Container(
//             margin: const EdgeInsets.only(
//               top: 8,
//             ),
//             width: 9,
//             height: 9,
//             decoration: const BoxDecoration(
//               color: Color(0xFFE8A020),
//               shape: BoxShape.circle,
//             ),
//           ),

//           const SizedBox(width: 14),

//           // CONTENT
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   activity.title,
//                   style: const TextStyle(
//                     fontSize: 15,
//                     height: 1.45,
//                     fontWeight: FontWeight.w600,
//                     color: Color(
//                       0xFF1F2937,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   activity.time,
//                   style: const TextStyle(
//                     fontSize: 13,
//                     color: Color(
//                       0xFF6B7280,
//                     ),
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _activityDivider() {
//     return Container(
//       margin: const EdgeInsets.symmetric(
//         vertical: 16,
//       ),
//       width: double.infinity,
//       height: 1,
//       color: const Color(0xFFE5E7EB),
//     );
//   }
// }
