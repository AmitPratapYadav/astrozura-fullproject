// lib/screens/astrologer/screens/timeslots_screen.dart

import 'package:astrozura_application/features/astrologer/screens/payment_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/models/astrologer/astrologer_model.dart';
import '../../../core/services/booking_service.dart';
import '../../mainwidgets/header.dart';
import 'package:google_fonts/google_fonts.dart';

class TimeSlotScreen extends StatefulWidget {
  final AstrologerModel astrologer;
  final int duration;
  final DateTime date;
  final String type;
  final double totalPrice;
  final List<SlotModel> slots;

  const TimeSlotScreen({
    super.key,
    required this.astrologer,
    required this.duration,
    required this.date,
    required this.type,
    required this.totalPrice,
    required this.slots,
  });

  @override
  State<TimeSlotScreen> createState() => _TimeSlotScreenState();
}

class _TimeSlotScreenState extends State<TimeSlotScreen> {
  String selectedTime = '';

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Returns true when `slotLabel` represents a time that has already passed
  /// (only applies when the chosen date is today).
  bool _isPastTime(String slotLabel) {
    final now = DateTime.now();
    if (widget.date.year != now.year ||
        widget.date.month != now.month ||
        widget.date.day != now.day) {
      return false;
    }
    try {
      int hour;
      int minute = 0;
      final label = slotLabel.trim().toUpperCase();
      if (label.contains('AM') || label.contains('PM')) {
        final isPm = label.contains('PM');
        final timePart = label.replaceAll('AM', '').replaceAll('PM', '').trim();
        final parts = timePart.split(':');
        hour = int.parse(parts[0]);
        if (parts.length > 1) minute = int.parse(parts[1]);
        if (isPm && hour != 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;
      } else {
        final parts = label.split(':');
        hour = int.parse(parts[0]);
        if (parts.length > 1) minute = int.parse(parts[1]);
      }
      final slotDateTime = DateTime(now.year, now.month, now.day, hour, minute);
      return slotDateTime.isBefore(now);
    } catch (_) {
      return false;
    }
  }

  /// Parses a slot label into a comparable hour value (0–23).
  int _toHour(String label) {
    try {
      final upper = label.trim().toUpperCase();
      if (upper.contains('AM') || upper.contains('PM')) {
        final isPm = upper.contains('PM');
        final timePart = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
        int hour = int.parse(timePart.split(':')[0]);
        if (isPm && hour != 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;
        return hour;
      } else {
        return int.parse(upper.split(':')[0]);
      }
    } catch (_) {
      return 0;
    }
  }

  // ── Slot grouping ───────────────────────────────────────────────────────────

  /// Groups slots into Morning (< 12), Afternoon (12–16), Evening (≥ 17).
  Map<String, List<SlotModel>> _groupSlots() {
    final Map<String, List<SlotModel>> groups = {
      'MORNING': [],
      'AFTERNOON': [],
      'EVENING': [],
    };
    for (final slot in widget.slots) {
      final h = _toHour(slot.label);
      if (h < 12) {
        groups['MORNING']!.add(slot);
      } else if (h < 17) {
        groups['AFTERNOON']!.add(slot);
      } else {
        groups['EVENING']!.add(slot);
      }
    }
    // Remove empty groups so we don't render empty sections
    groups.removeWhere((_, v) => v.isEmpty);
    return groups;
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDD6), // warm cream background
      bottomNavigationBar: _buildBottomBar(),
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title ──────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back_ios, size: 18),
                          ),
                          const Spacer(),
                          Text(
                            'Initialize Booking',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFB38A2E),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Step indicator ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildStepHeader(),
                    ),

                    const SizedBox(height: 20),

                    // ── Slots ──────────────────────────────────────────────
                    if (widget.slots.isEmpty)
                      _buildEmptyState()
                    else
                      _buildSlotSections(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step header (matches design: "STEP 2 OF 3 ... Select Time Slot") ───────

  Widget _buildStepHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STEP 2 OF 3',
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Select Time Slot',
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5B3EAC),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Progress bar – step 2 of 3 ≈ 66 %
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 2 / 3,
            minHeight: 4,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5B3EAC)),
          ),
        ),
      ],
    );
  }

  // ── Slot sections ───────────────────────────────────────────────────────────

  Widget _buildSlotSections() {
    final groups = _groupSlots();

    final sectionIcons = {
      'MORNING': Icons.wb_sunny_outlined,
      'AFTERNOON': Icons.wb_cloudy_outlined,
      'EVENING': Icons.nights_stay_outlined,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groups.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section label
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      sectionIcons[entry.key] ?? Icons.schedule,
                      size: 18,
                      color: const Color(0xFF8B6914),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.key,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: const Color(0xFF8B6914),
                      ),
                    ),
                  ],
                ),
              ),
              // Slot grid
              _buildSlotGrid(entry.value),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSlotGrid(List<SlotModel> slots) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: slots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 3.2,
      ),
      itemBuilder: (context, index) {
        final slot = slots[index];
        final label = slot.label;
        final isDisabled = !slot.isAvailable || _isPastTime(label);
        final isSelected = selectedTime == label;

        return GestureDetector(
          onTap: isDisabled ? null : () => setState(() => selectedTime = label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF5B3EAC)
                  : isDisabled
                      ? const Color(0xFFF0EBD8)
                      : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF5B3EAC)
                    : isDisabled
                        ? Colors.grey.shade300
                        : Colors.grey.shade300,
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF5B3EAC).withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : isDisabled
                        ? Colors.grey.shade400
                        : Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No slots available for this date.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ──────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final astro = widget.astrologer;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6EFD9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// MAIN CARD
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    /// TOP PROFILE ROW
                    Row(
                      children: [
                        /// PROFILE IMAGE
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE7D9B8),
                              width: 1.5,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: astro.fullImageUrl.isNotEmpty
                                ? NetworkImage(astro.fullImageUrl)
                                : null,
                            child: astro.fullImageUrl.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                        ),

                        const SizedBox(width: 14),

                        /// NAME + SPECIALITY
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      astro.name,
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF374B63),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Verified",
                                    style: GoogleFonts.lato(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF5B4DB1),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                astro.specialities,
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: const Color(0xFFC3A54B),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// SESSION DETAILS
                    Row(
                      children: [
                        Expanded(
                          child: _premiumDetailItem(
                            icon: widget.type == 'call'
                                ? Icons.videocam_outlined
                                : Icons.chat_bubble_outline,
                            title: 'SESSION',
                            value: widget.type == 'call'
                                ? 'Video Call'
                                : 'Chat Session',
                          ),
                        ),
                        Expanded(
                          child: _premiumDetailItem(
                            icon: Icons.access_time,
                            title: 'DURATION',
                            value: '${widget.duration} Minutes',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _premiumDetailItem(
                            icon: Icons.calendar_today_outlined,
                            title: 'DATE',
                            value: _formatDate(widget.date),
                          ),
                        ),
                        Expanded(
                          child: _premiumDetailItem(
                            icon: Icons.schedule,
                            title: 'TIME',
                            value:
                                selectedTime.isEmpty ? '--:--' : selectedTime,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    /// BOTTOM PRICE + BUTTON
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        /// PRICE
                        Flexible(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL PAYABLE',
                                style: GoogleFonts.lato(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '₹${widget.totalPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.lato(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF154C89),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        /// PAYMENT BUTTON
                        Expanded(
                          flex: 6,
                          child: ElevatedButton(
                            onPressed: selectedTime.isEmpty
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PaymentScreen(
                                          astrologer: astro,
                                          duration: widget.duration,
                                          date: widget.date,
                                          time: selectedTime,
                                          type: widget.type,
                                          totalPrice: widget.totalPrice,
                                        ),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4A73A),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              disabledBackgroundColor: Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Proceed to Payment',
                                    style: GoogleFonts.lato(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              /// SECURITY FOOTER
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 14,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Secure checkout & 100% Privacy Guaranteed',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _premiumDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFFD4A73A),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3C3C3C),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Helper: single detail tile ──────────────────────────────────────────────

  Widget _detailTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 9,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
