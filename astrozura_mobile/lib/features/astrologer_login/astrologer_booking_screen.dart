// // lib/screens/astrologer/bookings_screen.dart

// import 'package:flutter/material.dart';
// import '../../core/models/astrologer/astrologer_booking_model.dart';
// import '../../core/services/astrologer_service.dart';
// import 'widgets/booking_card.dart';
// import 'widgets/astrologer_nav_shell.dart';
// import 'widgets/astrologer_app_bar.dart';

// // ─── Filter options ────────────────────────────────────────────────────────────

// enum BookingFilter { all, today, pending, confirmed }

// extension BookingFilterLabel on BookingFilter {
//   String get label {
//     switch (this) {
//       case BookingFilter.all:
//         return 'All';
//       case BookingFilter.today:
//         return 'Today';
//       case BookingFilter.pending:
//         return 'Pending';
//       case BookingFilter.confirmed:
//         return 'Confirmed';
//     }
//   }
// }

// // ─── Screen ───────────────────────────────────────────────────────────────────

// class BookingsScreen extends StatefulWidget {
//   const BookingsScreen({super.key});

//   @override
//   State<BookingsScreen> createState() => _BookingsScreenState();
// }

// class _BookingsScreenState extends State<BookingsScreen> {
//   // ── state ─────────────────────────────────────────────────────────────────

//   bool _isLoading = true;
//   String? _error;

//   List<AstrologerBookingModel> _allBookings = [];
//   int _tomorrowCount = 0;

//   BookingFilter _activeFilter = BookingFilter.all;
//   String _searchQuery = '';

//   final TextEditingController _searchCtrl = TextEditingController();

//   // ── lifecycle ─────────────────────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();
//     _loadBookings();
//   }

//   @override
//   void dispose() {
//     _searchCtrl.dispose();
//     super.dispose();
//   }

//   // ── data ──────────────────────────────────────────────────────────────────

//   Future<void> _loadBookings() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//       final result = await AstrologerService.getBookings();
//       final upcoming =
//           (result['upcoming'] as List<AstrologerBookingModel>?) ?? [];

//       // Count bookings scheduled for tomorrow
//       final tomorrow = DateTime.now().add(const Duration(days: 1));
//       final tomorrowCount = upcoming.where((b) {
//         try {
//           final d = DateTime.parse(b.bookingDate);
//           return d.year == tomorrow.year &&
//               d.month == tomorrow.month &&
//               d.day == tomorrow.day;
//         } catch (_) {
//           return false;
//         }
//       }).length;

//       setState(() {
//         _allBookings = upcoming;
//         _tomorrowCount = tomorrowCount;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = e.toString().replaceFirst('Exception: ', '');
//         _isLoading = false;
//       });
//     }
//   }

//   // ── filtering ─────────────────────────────────────────────────────────────

//   List<AstrologerBookingModel> get _filtered {
//     var list = _allBookings;

//     // Status filter
//     switch (_activeFilter) {
//       case BookingFilter.today:
//         final today = DateTime.now();
//         list = list.where((b) {
//           try {
//             final d = DateTime.parse(b.bookingDate);
//             return d.year == today.year &&
//                 d.month == today.month &&
//                 d.day == today.day;
//           } catch (_) {
//             return false;
//           }
//         }).toList();
//         break;
//       case BookingFilter.pending:
//         list = list
//             .where((b) => b.status.toLowerCase() == 'pending')
//             .toList();
//         break;
//       case BookingFilter.confirmed:
//         list = list
//             .where((b) =>
//                 b.status.toLowerCase() == 'confirmed' ||
//                 b.status.toLowerCase() == 'in_progress')
//             .toList();
//         break;
//       case BookingFilter.all:
//         break;
//     }

//     // Search filter
//     final q = _searchQuery.trim().toLowerCase();
//     if (q.isNotEmpty) {
//       list = list.where((b) {
//         return b.userName.toLowerCase().contains(q) ||
//             b.bookingId.toLowerCase().contains(q) ||
//             b.userEmail.toLowerCase().contains(q);
//       }).toList();
//     }

//     return list;
//   }

//   // ── actions ───────────────────────────────────────────────────────────────

//   Future<void> _markComplete(AstrologerBookingModel booking) async {
//     final confirmed = await _confirmDialog(
//       title: 'Complete Booking?',
//       message:
//           'Mark the session with ${booking.userName} as completed?',
//       confirmLabel: 'Complete',
//       confirmColor: const Color(0xFFE8A020),
//     );
//     if (!confirmed) return;

//     try {
//       await AstrologerService.markComplete(booking.id);
//       await _loadBookings();
//       if (mounted) {
//         _showSnack('Booking marked as completed ✓', success: true);
//       }
//     } catch (e) {
//       if (mounted) {
//         _showSnack(e.toString().replaceFirst('Exception: ', ''));
//       }
//     }
//   }

//   Future<bool> _confirmDialog({
//     required String title,
//     required String message,
//     required String confirmLabel,
//     required Color confirmColor,
//   }) async {
//     final result = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         title: Text(
//           title,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w800,
//             color: Color(0xFF243B63),
//           ),
//         ),
//         content: Text(
//           message,
//           style: const TextStyle(
//             fontSize: 14,
//             color: Color(0xFF6B7280),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, false),
//             child: const Text(
//               'Cancel',
//               style: TextStyle(color: Color(0xFF6B7280)),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(ctx, true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: confirmColor,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               elevation: 0,
//             ),
//             child: Text(
//               confirmLabel,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//     return result ?? false;
//   }

//   void _showSnack(String msg, {bool success = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: success
//             ? const Color(0xFF059669)
//             : const Color(0xFFEF4444),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//     );
//   }

//   // ── build ─────────────────────────────────────────────────────────────────

// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     backgroundColor: const Color(0xFFF9FAFB),
//     body: Column(
//       children: [
//         const AstrologerAppBar(),

//         Expanded(
//           child: _isLoading
//               ? _buildLoader()
//               : _error != null
//                   ? _buildError()
//                   : _buildBody(),
//         ),
//       ],
//     ),
//   );
// }

//   // ── app bar ───────────────────────────────────────────────────────────────

//   // PreferredSizeWidget _buildAppBar() {
//   //   return AppBar(
//   //     backgroundColor: Colors.white,
//   //     elevation: 0,
//   //     surfaceTintColor: Colors.transparent,
//   //     title: const Text(
//   //       'Incoming Bookings',
//   //       style: TextStyle(
//   //         fontSize: 18,
//   //         fontWeight: FontWeight.w800,
//   //         color: Color(0xFF243B63),
//   //       ),
//   //     ),
//   //     centerTitle: true,
//   //     actions: [
//   //       IconButton(
//   //         onPressed: () {
//   //           // Focus search field
//   //           FocusScope.of(context).requestFocus(_searchFocusNode);
//   //         },
//   //         icon: const Icon(
//   //           Icons.search_rounded,
//   //           size: 24,
//   //           color: Color(0xFF243B63),
//   //         ),
//   //       ),
//   //       const SizedBox(width: 4),
//   //     ],
//   //     bottom: PreferredSize(
//   //       preferredSize: const Size.fromHeight(1),
//   //       child: Container(
//   //         height: 1,
//   //         color: const Color(0xFFE5E7EB),
//   //       ),
//   //     ),
//   //   );
//   // }

//   final FocusNode _searchFocusNode = FocusNode();

//   // ── body ──────────────────────────────────────────────────────────────────

//   Widget _buildBody() {
//     final filtered = _filtered;
//     final activeCount = _allBookings
//         .where((b) =>
//             b.status.toLowerCase() == 'confirmed' ||
//             b.status.toLowerCase() == 'in_progress')
//         .length;

//     return RefreshIndicator(
//       color: const Color(0xFF243B63),
//       onRefresh: _loadBookings,
//       child: CustomScrollView(
//         slivers: [
//           // ── Search + Filters (sticky header) ──────────────────────────
//           SliverToBoxAdapter(
//             child: Container(
//               color: Colors.white,
//               padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildSearchBar(),
//                   const SizedBox(height: 14),
//                   _buildFilterChips(),
//                   const SizedBox(height: 14),
//                 ],
//               ),
//             ),
//           ),

//           // ── Thin separator ────────────────────────────────────────────
//           SliverToBoxAdapter(
//             child: Container(
//               height: 1,
//               color: const Color(0xFFE5E7EB),
//             ),
//           ),

//           // ── Active Sessions header ────────────────────────────────────
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'ACTIVE SESSIONS ($activeCount)',
//                     style: const TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w700,
//                       color: Color(0xFF9CA3AF),
//                       letterSpacing: 1.0,
//                     ),
//                   ),
//                   Row(
//                     children: const [
//                       Icon(
//                         Icons.access_time_rounded,
//                         size: 13,
//                         color: Color(0xFFE8A020),
//                       ),
//                       SizedBox(width: 4),
//                       Text(
//                         'IST TIME',
//                         style: TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFFE8A020),
//                           letterSpacing: 0.8,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // ── Booking Cards ─────────────────────────────────────────────
//           if (filtered.isEmpty)
//             SliverToBoxAdapter(child: _buildEmptyState())
//           else
//             SliverPadding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               sliver: SliverList(
//                 delegate: SliverChildBuilderDelegate(
//                   (ctx, i) => BookingCard(
//                     booking: filtered[i],
//                     onOpenChat: () => _handleOpenChat(filtered[i]),
//                     onComplete: () => _markComplete(filtered[i]),
//                     onTap: () => _handleTap(filtered[i]),
//                   ),
//                   childCount: filtered.length,
//                 ),
//               ),
//             ),

//           // ── Tomorrow's Outlook ────────────────────────────────────────
//           SliverToBoxAdapter(
//             child: _buildTomorrowOutlook(),
//           ),

//           const SliverToBoxAdapter(child: SizedBox(height: 24)),
//         ],
//       ),
//     );
//   }

//   // ── search bar ────────────────────────────────────────────────────────────

//   Widget _buildSearchBar() {
//     return Container(
//       height: 46,
//       decoration: BoxDecoration(
//         color: const Color(0xFFF3F4F6),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: TextField(
//         controller: _searchCtrl,
//         focusNode: _searchFocusNode,
//         onChanged: (v) => setState(() => _searchQuery = v),
//         style: const TextStyle(
//           fontSize: 14,
//           color: Color(0xFF1F2937),
//         ),
//         decoration: const InputDecoration(
//           hintText: 'Search Client or ID...',
//           hintStyle: TextStyle(
//             fontSize: 14,
//             color: Color(0xFF9CA3AF),
//           ),
//           prefixIcon: Icon(
//             Icons.search_rounded,
//             size: 20,
//             color: Color(0xFF9CA3AF),
//           ),
//           border: InputBorder.none,
//           contentPadding: EdgeInsets.symmetric(vertical: 13),
//         ),
//       ),
//     );
//   }

//   // ── filter chips ──────────────────────────────────────────────────────────

//   Widget _buildFilterChips() {
//     return Row(
//       children: BookingFilter.values.map((f) {
//         final isActive = _activeFilter == f;
//         return Padding(
//           padding: const EdgeInsets.only(right: 8),
//           child: GestureDetector(
//             onTap: () => setState(() => _activeFilter = f),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 180),
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 8,
//               ),
//               decoration: BoxDecoration(
//                 color: isActive
//                     ? const Color(0xFF243B63)
//                     : Colors.white,
//                 borderRadius: BorderRadius.circular(30),
//                 border: Border.all(
//                   color: isActive
//                       ? const Color(0xFF243B63)
//                       : const Color(0xFFE5E7EB),
//                 ),
//               ),
//               child: Text(
//                 f.label,
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                   color: isActive
//                       ? Colors.white
//                       : const Color(0xFF6B7280),
//                 ),
//               ),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   // ── tomorrow outlook ──────────────────────────────────────────────────────

//   Widget _buildTomorrowOutlook() {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFFE5E7EB)),
//       ),
//       child: Column(
//         children: [
//           const Align(
//             alignment: Alignment.centerLeft,
//             child: Text(
//               "TOMORROW'S OUTLOOK",
//               style: TextStyle(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w700,
//                 color: Color(0xFF9CA3AF),
//                 letterSpacing: 1.0,
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           Icon(
//             _tomorrowCount > 0
//                 ? Icons.calendar_month_outlined
//                 : Icons.calendar_today_outlined,
//             size: 40,
//             color: const Color(0xFFD1D5DB),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             _tomorrowCount == 0
//                 ? 'No appointments tomorrow'
//                 : '$_tomorrowCount Appointment${_tomorrowCount == 1 ? '' : 's'} Scheduled',
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF6B7280),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── empty state ───────────────────────────────────────────────────────────

//   Widget _buildEmptyState() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
//       child: Column(
//         children: [
//           const Icon(
//             Icons.inbox_outlined,
//             size: 56,
//             color: Color(0xFFD1D5DB),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             _searchQuery.isNotEmpty
//                 ? 'No bookings match "$_searchQuery"'
//                 : 'No ${_activeFilter.label.toLowerCase()} bookings',
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF9CA3AF),
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Pull down to refresh',
//             style: TextStyle(
//               fontSize: 13,
//               color: Color(0xFFD1D5DB),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── loader ────────────────────────────────────────────────────────────────

//   Widget _buildLoader() {
//     return const Center(
//       child: CircularProgressIndicator(
//         color: Color(0xFF243B63),
//         strokeWidth: 2.5,
//       ),
//     );
//   }

//   // ── error ─────────────────────────────────────────────────────────────────

//   Widget _buildError() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(
//               Icons.wifi_off_rounded,
//               size: 52,
//               color: Color(0xFFD1D5DB),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               _error ?? 'Something went wrong',
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 fontSize: 14,
//                 color: Color(0xFF6B7280),
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: _loadBookings,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF243B63),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 0,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 28,
//                   vertical: 13,
//                 ),
//               ),
//               child: const Text(
//                 'Try Again',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }



//   // ── navigation ────────────────────────────────────────────────────────────

//   void _handleOpenChat(AstrologerBookingModel booking) {
//     // Navigate to chat screen — wire up your route here
//     // Navigator.pushNamed(context, '/astrologer/chat',
//     //     arguments: {'bookingId': booking.id});
//     _showSnack('Opening chat for ${booking.userName}…', success: true);
//   }

//   void _handleTap(AstrologerBookingModel booking) {
//     // Navigate to booking detail — wire up your route here
//   }
// }