// lib/screens/astrologer/screens/schedule_session_screen.dart
//
// Integrated with backend BookingController.getAvailability
// GET /api/bookings/availability?astrologer_id=&consultation_type=&duration=&booking_date=
// Allowed durations from backend: [10, 15, 20, 30]

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/contants/app_colors.dart';
import '../../../core/models/astrologer/astrologer_model.dart';
import '../../../core/services/booking_service.dart';
import '../../mainwidgets/header.dart';
import '../widgets/step_indicator.dart';
import './timeslots_screen.dart';

class ScheduleSessionScreen extends StatefulWidget {
  final AstrologerModel astrologer;
  final String preselectedType;
  final int preselectedDuration;

  const ScheduleSessionScreen({
    super.key,
    required this.astrologer,
    this.preselectedType = 'chat',
    this.preselectedDuration = 15,
  });

  @override
  State<ScheduleSessionScreen> createState() => _ScheduleSessionScreenState();
}

class _ScheduleSessionScreenState extends State<ScheduleSessionScreen> {
  late String _selectedType;
  late int _selectedDuration;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _fetchError;

  // Backend only accepts [10, 15, 20, 30] — must match BookingController::$allowedDurations
  final List<int> _durations = [10, 15, 20, 30];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.preselectedType;
    // Clamp preselected duration to a valid backend value
    _selectedDuration = _durations.contains(widget.preselectedDuration)
        ? widget.preselectedDuration
        : 15;
  }

  double get _pricePerMin => _selectedType == 'chat'
      ? widget.astrologer.chatPrice
      : widget.astrologer.callPrice;

  double get _totalPrice => _pricePerMin * _selectedDuration;

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ── Fetch slots from backend ───────────────────────────────────────────────
  Future<void> _goToSlots() async {
    setState(() {
      _isLoading = true;
      _fetchError = null;
    });

    try {
      final result = await BookingService.getAvailability(
        astrologerId: widget.astrologer.id,
        consultationType: _selectedType,
        duration: _selectedDuration,
        bookingDate: _formatDateForApi(_selectedDate),
      );

      final slots = result['slots'] as List<SlotModel>;
      final amount = result['amount'] as double;

      setState(() => _isLoading = false);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TimeSlotScreen(
            astrologer: widget.astrologer,
            duration: _selectedDuration,
            date: _selectedDate,
            type: _selectedType,
            totalPrice: amount,
            // FIX: pass the full SlotModel list so TimeSlotScreen
            // has both the display label AND the isAvailable flag.
            slots: slots,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _fetchError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      bottomNavigationBar: _buildBottomBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, AppColors.goldLight],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const HeaderWidget(),

                // Title
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios, size: 18),
                      ),
                      const Spacer(),
                      Text(
                        'Schedule Session',
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
                StepIndicator(currentStep: 1),
                const SizedBox(height: 20),

                // ── STEP 1: Type ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _stepLabel('1', 'Choose Consultation Type'),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedType = 'chat'),
                              child: AnimatedScale(
                                scale: _selectedType == 'chat' ? 1.0 : 0.95,
                                duration: const Duration(milliseconds: 200),
                                child: _typeCard(
                                  isSelected: _selectedType == 'chat',
                                  icon: Icons.chat_bubble_outline,
                                  title: 'Chat',
                                  desc: 'Instant messaging',

                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedType = 'call'),
                              child: AnimatedScale(
                                scale: _selectedType == 'call' ? 1.0 : 0.95,
                                duration: const Duration(milliseconds: 200),
                                child: _typeCard(
                                  isSelected: _selectedType == 'call',
                                  icon: Icons.call_outlined,
                                  title: 'Audio Call',
                                  desc: 'Voice consultation',

                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── STEP 2: Duration ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _stepLabel('2', 'Select Duration'),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _durations.length,
                          itemBuilder: (context, index) {
                            final mins = _durations[index];
                            final isSelected = _selectedDuration == mins;
                            final cost = _pricePerMin * mins;

                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedDuration = mins),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFFDDC5F6),
                                            Color(0xFF978496),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        )
                                      : null,
                                  color: isSelected ? null : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF2F5AA8)
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                          )
                                        ]
                                      : [],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$mins Mins',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '₹${cost.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isSelected
                                            ? Colors.blue.shade900
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── STEP 3: Date ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _stepLabel('3', 'Select Date'),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: CalendarDatePicker(
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                          onDateChanged: (date) =>
                              setState(() => _selectedDate = date),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── ERROR BANNER ───────────────────────────────────
                if (_fetchError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.red.shade200, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _fetchError!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _fetchError = null),
                            child: const Icon(Icons.close,
                                size: 16, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── WIDGETS ────────────────────────────────────────────────────────────────

  Widget _stepLabel(String number, String title) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: const Color(0xFF2F5AA8),
          child: Text(number,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _typeCard({
    required bool isSelected,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF2F5AA8) : Colors.grey.shade300,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1), blurRadius: 10)
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(colors: [
                      Color(0xFFFFE082),
                      Color(0xFFFFC107),
                    ])
                  : null,
              color: isSelected ? null : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: isSelected ? Colors.black : Colors.grey),
          ),
          const SizedBox(height: 10),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(desc,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),

        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final astrologer = widget.astrologer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Astrologer summary row
            Row(
              children: [
                _avatarWidget(astrologer),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('YOUR ASTROLOGER',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text(
                        astrologer.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4A73A)),
                      ),
                      Text(
                        astrologer.specialities.isNotEmpty
                            ? astrologer.specialities
                            : 'Astrologer',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$_selectedDuration mins'),
                    Text(_formatDate(_selectedDate),
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Amount',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      '₹${_totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E4E8C),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isLoading ? null : _goToSlots,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A73A),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : const Row(
                          children: [
                            Text('Choose Time Slot',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user, size: 14, color: Colors.green),
                SizedBox(width: 6),
                Text(
                  'Secure checkout • 100% Privacy Guaranteed',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarWidget(AstrologerModel astrologer) {
    final imageUrl = astrologer.fullImageUrl;
    if (imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFE8E6F8),
      child: Text(
        astrologer.name.isNotEmpty ? astrologer.name[0].toUpperCase() : 'A',
        style: const TextStyle(
            color: Color(0xFF2E2A72), fontWeight: FontWeight.bold),
      ),
    );
  }
}