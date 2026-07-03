// // lib/screens/astrologer/astrologer_history_screen.dart
// //
// // Past Bookings / Service Record screen for astrologers.
// // – Fetches completed + cancelled bookings from AstrologerService
// // – Self-contained: includes the PastBookingCard widget at the bottom
// // – Embeds a bottom nav bar matching AstrologerNavShell's tab structure

// import 'package:flutter/material.dart';
// import '../../core/models/astrologer/astrologer_booking_model.dart';
// import '../../core/services/astrologer_service.dart';

// // ─── Filter options ────────────────────────────────────────────────────────────

// enum HistoryFilter { allTime, thisMonth, lastMonth }

// extension HistoryFilterLabel on HistoryFilter {
//   String get label {
//     switch (this) {
//       case HistoryFilter.allTime:
//         return 'All Time';
//       case HistoryFilter.thisMonth:
//         return 'This Month';
//       case HistoryFilter.lastMonth:
//         return 'Last Month';
//     }
//   }
// }

// // ─── Screen ───────────────────────────────────────────────────────────────────

// class AstrologerHistoryScreen extends StatefulWidget {
//   const AstrologerHistoryScreen({super.key});

//   @override
//   State<AstrologerHistoryScreen> createState() =>
//       _AstrologerHistoryScreenState();
// }

// class _AstrologerHistoryScreenState
//     extends State<AstrologerHistoryScreen> {
//   // ── state ─────────────────────────────────────────────────────────────────

//   bool _isLoading = true;
//   String? _error;

//   List<AstrologerBookingModel> _allHistory = [];
//   HistoryFilter _activeFilter = HistoryFilter.allTime;
//   String _searchQuery = '';

//   final TextEditingController _searchCtrl = TextEditingController();
//   final FocusNode _searchFocusNode = FocusNode();

//   // ── lifecycle ─────────────────────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();
//     _loadHistory();
//   }

//   @override
//   void dispose() {
//     _searchCtrl.dispose();
//     _searchFocusNode.dispose();
//     super.dispose();
//   }

//   // ── data ──────────────────────────────────────────────────────────────────

//   Future<void> _loadHistory() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//       final result = await AstrologerService.getBookings();

//       // Past bookings = completed + cancelled (not upcoming)
//       final history =
//     (result['history'] as List<AstrologerBookingModel>?) ?? [];

//       // Fallback: if the API returns everything in 'upcoming', filter by status
//       final upcoming =
//           (result['upcoming'] as List<AstrologerBookingModel>?) ?? [];

//       final historyBookings = history.isNotEmpty
//     ? history
//     : upcoming.where((b) {
//         final status = b.status.toLowerCase();

//         return status == 'completed' ||
//             status == 'cancelled' ||
//             status == 'ended';
//       }).toList();

//       // Sort newest first
//       history.sort((a, b) {
//         try {
//           return DateTime.parse(b.bookingDate)
//               .compareTo(DateTime.parse(a.bookingDate));
//         } catch (_) {
//           return 0;
//         }
//       });

//       setState(() {
//         _allHistory = historyBookings;
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
//     var list = _allHistory;

//     final now = DateTime.now();

//     switch (_activeFilter) {
//       case HistoryFilter.thisMonth:
//         list = list.where((b) {
//           try {
//             final d = DateTime.parse(b.bookingDate);
//             return d.year == now.year && d.month == now.month;
//           } catch (_) {
//             return false;
//           }
//         }).toList();
//         break;
//       case HistoryFilter.lastMonth:
//         final lastMonth = DateTime(now.year, now.month - 1);
//         list = list.where((b) {
//           try {
//             final d = DateTime.parse(b.bookingDate);
//             return d.year == lastMonth.year &&
//                 d.month == lastMonth.month;
//           } catch (_) {
//             return false;
//           }
//         }).toList();
//         break;
//       case HistoryFilter.allTime:
//         break;
//     }

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

//   // ── helpers ───────────────────────────────────────────────────────────────

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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF9FAFB),
//       appBar: _buildAppBar(),
//       body: _isLoading
//           ? _buildLoader()
//           : _error != null
//               ? _buildError()
//               : _buildBody(),
//     );
//   }

//   // ── app bar ───────────────────────────────────────────────────────────────

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       backgroundColor: Colors.white,
//       elevation: 0,
//       surfaceTintColor: Colors.transparent,

//       title: const Text(
//         'Past Bookings',
//         style: TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.w800,
//           color: Color(0xFF243B63),
//         ),
//       ),
//       centerTitle: true,
//       actions: [
//         IconButton(
//           onPressed: () =>
//               FocusScope.of(context).requestFocus(_searchFocusNode),
//           icon: const Icon(
//             Icons.search_rounded,
//             size: 24,
//             color: Color(0xFF243B63),
//           ),
//         ),
//         const SizedBox(width: 4),
//       ],
//       bottom: PreferredSize(
//         preferredSize: const Size.fromHeight(1),
//         child: Container(height: 1, color: const Color(0xFFE5E7EB)),
//       ),
//     );
//   }

//   // ── body ──────────────────────────────────────────────────────────────────

//   Widget _buildBody() {
//     final filtered = _filtered;

//     return RefreshIndicator(
//       color: const Color(0xFF243B63),
//       onRefresh: _loadHistory,
//       child: CustomScrollView(
//         slivers: [
//           // ── Hero header ────────────────────────────────────────────
//           SliverToBoxAdapter(
//             child: Container(
//               color: Colors.white,
//               padding:
//                   const EdgeInsets.fromLTRB(20, 20, 20, 0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'HISTORY',
//                     style: TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w700,
//                       color: Color(0xFFE8A020),
//                       letterSpacing: 1.2,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   const Text(
//                     'Service Record',
//                     style: TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.w800,
//                       color: Color(0xFF243B63),
//                       height: 1.1,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   const Text(
//                     'Review your completed and cancelled\nconsultations.',
//                     style: TextStyle(
//                       fontSize: 13,
//                       color: Color(0xFF6B7280),
//                       height: 1.5,
//                     ),
//                   ),
//                   const SizedBox(height: 18),

//                   // ── Session count + Export row ──────────────────
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 14,
//                       vertical: 10,
//                     ),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF3F4F6),
//                       borderRadius: BorderRadius.circular(30),
//                       border: Border.all(
//                           color: const Color(0xFFE5E7EB)),
//                     ),
//                     child: Row(
//                       children: [
//                         // Filter pill
//                         GestureDetector(
//                           onTap: _showFilterSheet,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 14,
//                               vertical: 6,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius:
//                                   BorderRadius.circular(30),
//                               border: Border.all(
//                                   color:
//                                       const Color(0xFFE5E7EB)),
//                             ),
//                             child: Text(
//                               _activeFilter.label,
//                               style: const TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFF243B63),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Text(
//                           '${filtered.length} Session${filtered.length == 1 ? '' : 's'}',
//                           style: const TextStyle(
//                             fontSize: 13,
//                             color: Color(0xFF6B7280),
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         const Spacer(),
//                         GestureDetector(
//                           onTap: () => _showSnack(
//                               'Export coming soon…',
//                               success: true),
//                           child: Row(
//                             children: const [
//                               Icon(
//                                 Icons.download_rounded,
//                                 size: 15,
//                                 color: Color(0xFF243B63),
//                               ),
//                               SizedBox(width: 4),
//                               Text(
//                                 'Export',
//                                 style: TextStyle(
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.w600,
//                                   color: Color(0xFF243B63),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   // ── Search bar ──────────────────────────────────
//                   _buildSearchBar(),
//                   const SizedBox(height: 16),
//                 ],
//               ),
//             ),
//           ),

//           // ── Separator ──────────────────────────────────────────────
//           SliverToBoxAdapter(
//             child: Container(
//                 height: 1, color: const Color(0xFFE5E7EB)),
//           ),

//           // ── Booking cards or empty state ────────────────────────────
//           if (filtered.isEmpty)
//             SliverToBoxAdapter(child: _buildEmptyState())
//           else
//             SliverPadding(
//               padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//               sliver: SliverList(
//                 delegate: SliverChildBuilderDelegate(
//                   (ctx, i) => PastBookingCard(
//                     booking: filtered[i],
//                     onReceipt: () => _showSnack(
//                       'Opening receipt for ${filtered[i].bookingId}…',
//                       success: true,
//                     ),
//                     onReopenChat: () => _showSnack(
//                       'Reopening chat with ${filtered[i].userName}…',
//                       success: true,
//                     ),
//                     onReview: () => _showReviewDialog(filtered[i]),
//                   ),
//                   childCount: filtered.length,
//                 ),
//               ),
//             ),

//           // ── End of history footer ───────────────────────────────────
//           if (!_isLoading && _error == null)
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 36),
//                 child: Column(
//                   children: [
//                     Container(
//                       width: 40,
//                       height: 3,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFE5E7EB),
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     const Text(
//                       'END OF HISTORY',
//                       style: TextStyle(
//                         fontSize: 11,
//                         fontWeight: FontWeight.w700,
//                         color: Color(0xFF9CA3AF),
//                         letterSpacing: 1.2,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

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
//           hintText: 'Search client or booking ID…',
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

//   // ── filter bottom sheet ───────────────────────────────────────────────────

//   void _showFilterSheet() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (ctx) => Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Filter by Period',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w800,
//                 color: Color(0xFF243B63),
//               ),
//             ),
//             const SizedBox(height: 16),
//             ...HistoryFilter.values.map(
//               (f) => ListTile(
//                 contentPadding: EdgeInsets.zero,
//                 leading: Icon(
//                   _activeFilter == f
//                       ? Icons.radio_button_checked
//                       : Icons.radio_button_unchecked,
//                   color: _activeFilter == f
//                       ? const Color(0xFF243B63)
//                       : const Color(0xFF9CA3AF),
//                 ),
//                 title: Text(
//                   f.label,
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: _activeFilter == f
//                         ? FontWeight.w700
//                         : FontWeight.w500,
//                     color: _activeFilter == f
//                         ? const Color(0xFF243B63)
//                         : const Color(0xFF6B7280),
//                   ),
//                 ),
//                 onTap: () {
//                   setState(() => _activeFilter = f);
//                   Navigator.pop(ctx);
//                 },
//               ),
//             ),
//             const SizedBox(height: 8),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── review dialog ─────────────────────────────────────────────────────────

//   void _showReviewDialog(AstrologerBookingModel booking) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         title: Text(
//           'Review ${booking.userName}',
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w800,
//             color: Color(0xFF243B63),
//           ),
//         ),
//         content: const Text(
//           'Review functionality coming soon.',
//           style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
//         ),
//         actions: [
//           ElevatedButton(
//             onPressed: () => Navigator.pop(ctx),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFFE8A020),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10)),
//               elevation: 0,
//             ),
//             child: const Text('OK',
//                 style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w700)),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── empty state ───────────────────────────────────────────────────────────

//   Widget _buildEmptyState() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
//       child: Column(
//         children: [
//           const Icon(Icons.history_rounded,
//               size: 56, color: Color(0xFFD1D5DB)),
//           const SizedBox(height: 16),
//           Text(
//             _searchQuery.isNotEmpty
//                 ? 'No bookings match "$_searchQuery"'
//                 : 'No past bookings yet',
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
//             style: TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
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
//             const Icon(Icons.wifi_off_rounded,
//                 size: 52, color: Color(0xFFD1D5DB)),
//             const SizedBox(height: 16),
//             Text(
//               _error ?? 'Something went wrong',
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                   fontSize: 14, color: Color(0xFF6B7280)),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: _loadHistory,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF243B63),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//                 elevation: 0,
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 28, vertical: 13),
//               ),
//               child: const Text(
//                 'Try Again',
//                 style: TextStyle(
//                     color: Colors.white, fontWeight: FontWeight.w700),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─── PastBookingCard Widget ────────────────────────────────────────────────────
// //
// // Self-contained card matching the design in the attached screenshot exactly.
// // Status chip: "Completed" (plain text, right-aligned) or "Cancelled" (pink pill).

// class PastBookingCard extends StatelessWidget {
//   final AstrologerBookingModel booking;
//   final VoidCallback onReceipt;
//   final VoidCallback onReopenChat;
//   final VoidCallback? onReview; // shown only for completed bookings

//   const PastBookingCard({
//     super.key,
//     required this.booking,
//     required this.onReceipt,
//     required this.onReopenChat,
//     this.onReview,
//   });

//   // ── helpers ────────────────────────────────────────────────────────────────

//   bool get _isCompleted =>
//       booking.status.toLowerCase() == 'completed';

//   bool get _isCancelled =>
//       booking.status.toLowerCase() == 'cancelled';

//   /// Format "2026-05-11T20:30:00" → "11 May 2026, 8:30 pm"
//   String _formatDate(String raw) {
//     try {
//       final dt = DateTime.parse(raw);
//       const months = [
//         'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
//       ];
//       final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
//       final minute = dt.minute.toString().padLeft(2, '0');
//       final period = dt.hour < 12 ? 'am' : 'pm';
//       return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $period';
//     } catch (_) {
//       return raw;
//     }
//   }

//   /// Format amount e.g. 750.0 → "Rs 750.00"
//   String _formatAmount(double amount) {
//     return 'Rs ${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
//   }

//   // ── build ──────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFFE5E7EB)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ── Top: booking ID + status ───────────────────────────────
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   booking.bookingId.toUpperCase(),
//                   style: const TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w700,
//                     color: Color(0xFFE8A020),
//                     letterSpacing: 0.4,
//                   ),
//                 ),
//                 _buildStatusChip(),
//               ],
//             ),
//           ),

//           // ── User name + service type ───────────────────────────────
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
//             child: Text(
//               booking.userName,
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w800,
//                 color: Color(0xFF243B63),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
//             child: Text(
//               booking.serviceName.isNotEmpty
//                   ? booking.serviceName
//                   : booking.consultationType,
//               style: const TextStyle(
//                 fontSize: 13,
//                 color: Color(0xFF6B7280),
//               ),
//             ),
//           ),

//           // ── Divider ───────────────────────────────────────────────
//           const Padding(
//             padding: EdgeInsets.symmetric(vertical: 14),
//             child: Divider(height: 1, color: Color(0xFFE5E7EB)),
//           ),

//           // ── Date + Amount row ─────────────────────────────────────
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
//             child: Row(
//               children: [
//                 // Scheduled for
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: const [
//                           Icon(
//                             Icons.calendar_today_rounded,
//                             size: 12,
//                             color: Color(0xFF9CA3AF),
//                           ),
//                           SizedBox(width: 4),
//                           Text(
//                             'SCHEDULED FOR',
//                             style: TextStyle(
//                               fontSize: 10,
//                               fontWeight: FontWeight.w700,
//                               color: Color(0xFF9CA3AF),
//                               letterSpacing: 0.8,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         _formatDate(booking.bookingDate),
//                         style: const TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF243B63),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 // Amount
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: const [
//                         Icon(
//                           Icons.attach_money_rounded,
//                           size: 12,
//                           color: Color(0xFF9CA3AF),
//                         ),
//                         SizedBox(width: 2),
//                         Text(
//                           'AMOUNT',
//                           style: TextStyle(
//                             fontSize: 10,
//                             fontWeight: FontWeight.w700,
//                             color: Color(0xFF9CA3AF),
//                             letterSpacing: 0.8,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       _formatAmount(booking.amount),
//                       style: const TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w700,
//                         color: Color(0xFF243B63),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // ── Divider ───────────────────────────────────────────────
//           const Padding(
//             padding: EdgeInsets.only(top: 14),
//             child: Divider(height: 1, color: Color(0xFFE5E7EB)),
//           ),

//           // ── Action buttons row ────────────────────────────────────
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
//             child: Row(
//               children: [
//                 // Receipt
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: onReceipt,
//                     icon: const Icon(
//                       Icons.receipt_long_rounded,
//                       size: 16,
//                       color: Color(0xFF243B63),
//                     ),
//                     label: const Text(
//                       'Receipt',
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xFF243B63),
//                       ),
//                     ),
//                     style: OutlinedButton.styleFrom(
//                       side: const BorderSide(
//                           color: Color(0xFFE5E7EB)),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       padding:
//                           const EdgeInsets.symmetric(vertical: 11),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 // Reopen Chat
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: onReopenChat,
//                     icon: const Icon(
//                       Icons.chat_bubble_outline_rounded,
//                       size: 16,
//                       color: Colors.white,
//                     ),
//                     label: const Text(
//                       'Reopen Chat',
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF243B63),
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       padding:
//                           const EdgeInsets.symmetric(vertical: 11),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // ── Review button (completed only) ────────────────────────
//           if (_isCompleted && onReview != null)
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
//               child: SizedBox(
//                 width: double.infinity,
//                 child: OutlinedButton.icon(
//                   onPressed: onReview,
//                   icon: const Icon(
//                     Icons.star_outline_rounded,
//                     size: 16,
//                     color: Color(0xFFE8A020),
//                   ),
//                   label: const Text(
//                     'Review',
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFFE8A020),
//                     ),
//                   ),
//                   style: OutlinedButton.styleFrom(
//                     side: const BorderSide(
//                         color: Color(0xFFE8A020), width: 1.5),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     padding:
//                         const EdgeInsets.symmetric(vertical: 11),
//                   ),
//                 ),
//               ),
//             )
//           else
//             const SizedBox(height: 16),
//         ],
//       ),
//     );
//   }

//   // ── status chip ────────────────────────────────────────────────────────────

//   Widget _buildStatusChip() {
//     if (_isCancelled) {
//       return Container(
//         padding:
//             const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//         decoration: BoxDecoration(
//           color: const Color(0xFFFEE2E2),
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: const Text(
//           'Cancelled',
//           style: TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w600,
//             color: Color(0xFFEF4444),
//           ),
//         ),
//       );
//     }

//     if (_isCompleted) {
//       return const Text(
//         'Completed',
//         style: TextStyle(
//           fontSize: 13,
//           fontWeight: FontWeight.w600,
//           color: Color(0xFF1F2937),
//         ),
//       );
//     }

//     // Fallback for any other status
//     return Container(
//       padding:
//           const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF3F4F6),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         booking.status,
//         style: const TextStyle(
//           fontSize: 12,
//           fontWeight: FontWeight.w600,
//           color: Color(0xFF6B7280),
//         ),
//       ),
//     );
//   }
// }