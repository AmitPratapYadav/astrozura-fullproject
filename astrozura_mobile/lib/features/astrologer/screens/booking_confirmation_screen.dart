import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/astrologer/astrologer_model.dart';
import '../../main_navigation.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final String bookingReference;
  final String sessionType;    // 'call' | 'chat'
  final DateTime date;
  final String time;
  final double totalAmount;
  final AstrologerModel astrologer;

  const BookingConfirmationScreen({
    super.key,
    required this.bookingReference,
    required this.sessionType,
    required this.date,
    required this.time,
    required this.totalAmount,
    required this.astrologer,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String get _sessionLabel =>
      widget.sessionType == 'call' ? '1:1 Video Chat' : '1:1 Chat Session';

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDD6),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      _buildConfirmationCard(),
                      const SizedBox(height: 20),
                      _buildDetailsCard(),
                      const SizedBox(height: 28),
                      _buildViewBookingButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Confirmation card ────────────────────────────────────────────────────

  Widget _buildConfirmationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated checkmark circle
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.35),
                  width: 6,
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4CAF50),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Astrologer Booking\nConfirmed',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),

          // Subtitle
          Text(
            'Your session is all set! Get ready for clarity.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 13.5,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 18),

          // CONFIRMED badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD4A73A), width: 1.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'CONFIRMED',
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: const Color(0xFFD4A73A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Details card ─────────────────────────────────────────────────────────

  Widget _buildDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1 — Booking ID + Session
          _buildDetailRow(
            left: _DetailCell(
              icon: Icons.tag,
              label: 'BOOKING ID',
              value: widget.bookingReference,
            ),
            right: _DetailCell(
              icon: Icons.videocam_outlined,
              label: 'SESSION',
              value: _sessionLabel,
            ),
            showBottomDivider: true,
          ),

          // Row 2 — Date + Time
          _buildDetailRow(
            left: _DetailCell(
              icon: Icons.calendar_today_outlined,
              label: 'DATE',
              value: _formatDate(widget.date),
            ),
            right: _DetailCell(
              icon: Icons.access_time_outlined,
              label: 'TIME',
              value: widget.time,
            ),
            showBottomDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required _DetailCell left,
    required _DetailCell right,
    required bool showBottomDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Expanded(child: _buildCell(left)),
              Container(
                width: 1,
                height: 44,
                color: Colors.grey.shade100,
              ),
              Expanded(child: _buildCell(right, alignRight: true)),
            ],
          ),
        ),
        if (showBottomDivider)
          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _buildCell(_DetailCell cell, {bool alignRight = false}) {
    return Padding(
      padding: EdgeInsets.only(
        left: alignRight ? 20 : 0,
        right: alignRight ? 0 : 20,
      ),
      child: Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Label row with icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!alignRight) ...[
                Icon(cell.icon, size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 4),
              ],
              Text(
                cell.label,
                style: GoogleFonts.lato(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.grey.shade400,
                ),
              ),
              if (alignRight) ...[
                const SizedBox(width: 4),
                Icon(cell.icon, size: 12, color: Colors.grey.shade400),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Text(
            cell.value,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  // ── View Booking button ──────────────────────────────────────────────────

  Widget _buildViewBookingButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigation()),
            (route) => false,
          );
        },
        icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.black),
        label: Text(
          'View Booking',
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4A73A),
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ── Helper data class ────────────────────────────────────────────────────────

class _DetailCell {
  final IconData icon;
  final String label;
  final String value;

  const _DetailCell({
    required this.icon,
    required this.label,
    required this.value,
  });
}