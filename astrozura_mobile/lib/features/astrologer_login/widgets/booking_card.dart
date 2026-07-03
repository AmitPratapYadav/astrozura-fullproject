// // lib/widgets/astrologer/booking_card.dart

// import 'package:flutter/material.dart';
// import '../../../core/models/astrologer/astrologer_booking_model.dart';

// class BookingCard extends StatelessWidget {
//   final AstrologerBookingModel booking;
//   final VoidCallback? onOpenChat;
//   final VoidCallback? onComplete;
//   final VoidCallback? onTap;

//   const BookingCard({
//     super.key,
//     required this.booking,
//     this.onOpenChat,
//     this.onComplete,
//     this.onTap,
//   });

//   // ─── derived display values ───────────────────────────────────────────────

//   String get _displayName {
//     final n = booking.userName.trim();
//     return n.isEmpty ? 'Client' : _capitalize(n);
//   }

//   String get _displayId {
//     final id = booking.bookingId.trim();
//     return id.isEmpty ? '#ASTRO-${booking.id}' : id.toUpperCase();
//   }

//   String get _displayStatus {
//     final s = booking.status.trim();
//     return s.isEmpty ? 'pending' : s.toLowerCase();
//   }

//   String get _scheduledFor {
//     final d = booking.bookingDate.trim();
//     final t = booking.bookingTime.trim();
//     if (d.isEmpty && t.isEmpty) return 'Not set';
//     if (d.isEmpty) return t;
//     if (t.isEmpty) return d;
//     return '$d, $t';
//   }

//   String get _formattedAmount {
//     final v = booking.amount;
//     if (v == v.truncateToDouble()) {
//       return '₹ ${v.toStringAsFixed(2)}';
//     }
//     return '₹ ${v.toStringAsFixed(2)}';
//   }

//   // ─── status pill config ───────────────────────────────────────────────────

//   _PillStyle _pillStyle(String status) {
//     switch (status) {
//       case 'confirmed':
//         return _PillStyle(
//           bg: const Color(0xFFF0F4FF),
//           border: const Color(0xFFD0DAF0),
//           text: const Color(0xFF374151),
//           label: 'confirmed',
//         );
//       case 'in_progress':
//       case 'urgent':
//         return _PillStyle(
//           bg: const Color(0xFFFFF0F0),
//           border: const Color(0xFFFFCCCC),
//           text: const Color(0xFFEF4444),
//           label: status == 'in_progress' ? 'urgent' : status,
//         );
//       case 'completed':
//         return _PillStyle(
//           bg: const Color(0xFFF0FFF4),
//           border: const Color(0xFFA7F3D0),
//           text: const Color(0xFF059669),
//           label: 'completed',
//         );
//       case 'cancelled':
//       case 'declined':
//         return _PillStyle(
//           bg: const Color(0xFFFFF7F0),
//           border: const Color(0xFFFFD6B0),
//           text: const Color(0xFFB45309),
//           label: status,
//         );
//       default: // pending
//         return _PillStyle(
//           bg: const Color(0xFFFFFBEB),
//           border: const Color(0xFFFDE68A),
//           text: const Color(0xFFD97706),
//           label: 'pending',
//         );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final pill = _pillStyle(_displayStatus);

//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: const Color(0xFFE5E7EB)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 14,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ── Row 1: Booking ID + Status Pill ──────────────────────────
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     _displayId,
//                     style: const TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w800,
//                       color: Color(0xFFE8A020),
//                       letterSpacing: 0.5,
//                     ),
//                   ),
//                   _StatusPill(style: pill),
//                 ],
//               ),

//               const SizedBox(height: 4),

//               // ── Row 2: Client Name ────────────────────────────────────────
//               Text(
//                 _displayName,
//                 style: const TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.w800,
//                   color: Color(0xFF243B63),
//                   height: 1.15,
//                 ),
//               ),

//               const SizedBox(height: 2),

//               // ── Row 3: Service Name ───────────────────────────────────────
//               Text(
//                 booking.serviceName.isEmpty
//                     ? 'Astrology Consultation'
//                     : booking.serviceName,
//                 style: const TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w400,
//                   color: Color(0xFF6B7280),
//                 ),
//               ),

//               const SizedBox(height: 14),

//               // ── Divider ───────────────────────────────────────────────────
//               Container(
//                 height: 1,
//                 color: const Color(0xFFE5E7EB),
//               ),

//               const SizedBox(height: 14),

//               // ── Row 4: Scheduled For + Amount ─────────────────────────────
//               Row(
//                 children: [
//                   // Scheduled
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'SCHEDULED FOR',
//                           style: TextStyle(
//                             fontSize: 10,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF9CA3AF),
//                             letterSpacing: 0.8,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Row(
//                           children: [
//                             const Icon(
//                               Icons.calendar_today_outlined,
//                               size: 14,
//                               color: Color(0xFF6B7280),
//                             ),
//                             const SizedBox(width: 5),
//                             Flexible(
//                               child: Text(
//                                 _scheduledFor,
//                                 style: const TextStyle(
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.w600,
//                                   color: Color(0xFF1F2937),
//                                 ),
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(width: 16),

//                   // Amount
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'AMOUNT',
//                         style: TextStyle(
//                           fontSize: 10,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF9CA3AF),
//                           letterSpacing: 0.8,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Row(
//                         children: [
//                           const Icon(
//                             Icons.currency_rupee,
//                             size: 14,
//                             color: Color(0xFF6B7280),
//                           ),
//                           const SizedBox(width: 2),
//                           Text(
//                             _formattedAmount,
//                             style: const TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.w700,
//                               color: Color(0xFF1F2937),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 12),

//               // ── Row 5: Client Contact ──────────────────────────────────────
//               if (booking.userEmail.trim().isNotEmpty) ...[
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'CLIENT CONTACT',
//                       style: TextStyle(
//                         fontSize: 10,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xFF9CA3AF),
//                         letterSpacing: 0.8,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       children: [
//                         const Icon(
//                           Icons.email_outlined,
//                           size: 14,
//                           color: Color(0xFF6B7280),
//                         ),
//                         const SizedBox(width: 5),
//                         Flexible(
//                           child: Text(
//                             booking.userEmail.trim(),
//                             style: const TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.w500,
//                               color: Color(0xFF374151),
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//               ] else
//                 const SizedBox(height: 4),

//               // ── Buttons ───────────────────────────────────────────────────
//               Row(
//                 children: [
//                   // Open Chat
//                   Expanded(
//                     child: SizedBox(
//                       height: 46,
//                       child: ElevatedButton.icon(
//                         onPressed: onOpenChat,
//                         style: ElevatedButton.styleFrom(
//                           elevation: 0,
//                           backgroundColor: const Color(0xFF243B63),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         icon: const Icon(
//                           Icons.chat_bubble_outline,
//                           size: 17,
//                           color: Colors.white,
//                         ),
//                         label: const Text(
//                           'Open Chat',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 13,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(width: 12),

//                   // Complete
//                   Expanded(
//                     child: SizedBox(
//                       height: 46,
//                       child: OutlinedButton.icon(
//                         onPressed: onComplete,
//                         style: OutlinedButton.styleFrom(
//                           side: const BorderSide(
//                             color: Color(0xFFE8A020),
//                             width: 1.5,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         icon: const Icon(
//                           Icons.check_circle_outline,
//                           size: 17,
//                           color: Color(0xFFE8A020),
//                         ),
//                         label: const Text(
//                           'Complete',
//                           style: TextStyle(
//                             color: Color(0xFFE8A020),
//                             fontSize: 13,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   String _capitalize(String text) {
//     return text
//         .trim()
//         .split(' ')
//         .map((w) => w.isEmpty
//             ? ''
//             : w[0].toUpperCase() + w.substring(1).toLowerCase())
//         .join(' ');
//   }
// }

// // ─── Status Pill ──────────────────────────────────────────────────────────────

// class _PillStyle {
//   final Color bg;
//   final Color border;
//   final Color text;
//   final String label;
//   const _PillStyle({
//     required this.bg,
//     required this.border,
//     required this.text,
//     required this.label,
//   });
// }

// class _StatusPill extends StatelessWidget {
//   final _PillStyle style;
//   const _StatusPill({required this.style});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
//       decoration: BoxDecoration(
//         color: style.bg,
//         borderRadius: BorderRadius.circular(30),
//         border: Border.all(color: style.border),
//       ),
//       child: Text(
//         style.label,
//         style: TextStyle(
//           fontSize: 11,
//           fontWeight: FontWeight.w700,
//           color: style.text,
//         ),
//       ),
//     );
//   }
// }