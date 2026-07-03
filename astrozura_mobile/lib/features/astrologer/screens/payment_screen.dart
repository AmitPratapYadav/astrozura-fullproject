import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/razorpay_service.dart';
import '../../shared/widgets/location_search_field.dart';
import '../../mainwidgets/header.dart';
import '../../../core/models/astrologer/astrologer_model.dart';
import './booking_confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final AstrologerModel astrologer;
  final int duration;
  final DateTime date;
  final String time;
  final String type;
  final double totalPrice;

  const PaymentScreen({
    super.key,
    required this.astrologer,
    required this.duration,
    required this.date,
    required this.time,
    required this.type,
    required this.totalPrice,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  final RazorpayService _razorpayService = RazorpayService();
  late final Razorpay _razorpay;
  BookingModel? _pendingBooking;

  // ── Birth Details State ────────────────────────────────────────────────────
  DateTime? _birthDate;
  TimeOfDay? _birthTime;
  String? _birthTimePeriod; // 'AM' | 'PM'  (kept in sync with _birthTime)
  String? _selectedGender; // 'male' | 'female' | 'other'
  final TextEditingController _placeController = TextEditingController();
  LocationSelection? _birthLocation;

  // Birth-details validation error messages
  String? _birthDateError;
  String? _birthTimeError;
  String? _genderError;
  String? _placeError;

  @override
  void dispose() {
    _razorpay.clear();
    _placeController.dispose();
    super.dispose();
  }

  // ── Computed ───────────────────────────────────────────────────────────────
  double get _subtotal => widget.totalPrice;
  double get _total => _subtotal;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  // ── Formatters ─────────────────────────────────────────────────────────────

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

  String _formatTimeWithDuration() {
    return '${widget.time} (${widget.duration} min)';
  }

  String _formatDateForApi(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Format birth date as "YYYY-MM-DD" for API
  String _formatBirthDateForApi(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Format birth time as "h:mm AM/PM" for API  (backend: nullable|string|max:50)
  String _formatBirthTimeForApi(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Display string for the selected birth date field
  String get _birthDateDisplay {
    if (_birthDate == null) return 'Select date';
    return _formatDate(_birthDate!);
  }

  /// Display string for the selected birth time field
  String get _birthTimeDisplay {
    if (_birthTime == null) return 'Select time';
    final hour = _birthTime!.hourOfPeriod == 0 ? 12 : _birthTime!.hourOfPeriod;
    final minute = _birthTime!.minute.toString().padLeft(2, '0');
    final period = _birthTime!.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String get _sessionTypeLabel {
    return widget.type == 'call' ? 'Live Video Chat' : 'Live Chat Session';
  }

  // ── Pickers ────────────────────────────────────────────────────────────────

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) => _datePickerTheme(child),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateError = null;
      });
    }
  }

  Future<void> _pickBirthTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _birthTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => _timePickerTheme(child),
    );
    if (picked != null) {
      setState(() {
        _birthTime = picked;
        _birthTimePeriod = picked.period == DayPeriod.am ? 'AM' : 'PM';
        _birthTimeError = null;
      });
    }
  }

  /// Themed wrapper for the date picker dialog
  Widget _datePickerTheme(Widget? child) {
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF5B3EAC),
          onPrimary: Colors.white,
          surface: Color(0xFFF5EDD6),
          onSurface: Color(0xFF2D2D2D),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF5B3EAC)),
        ),
      ),
      child: child!,
    );
  }

  /// Themed wrapper for the time picker dialog
  Widget _timePickerTheme(Widget? child) {
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF5B3EAC),
          onPrimary: Colors.white,
          surface: Color(0xFFF5EDD6),
          onSurface: Color(0xFF2D2D2D),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF5B3EAC)),
        ),
      ),
      child: child!,
    );
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  bool _validateBirthDetails() {
    bool valid = true;
    setState(() {
      _birthDateError = null;
      _birthTimeError = null;
      _genderError = null;
      _placeError = null;

      if (_birthDate == null) {
        _birthDateError = 'Please select your date of birth';
        valid = false;
      }
      if (_birthTime == null) {
        _birthTimeError = 'Please select your time of birth';
        valid = false;
      }
      if (_selectedGender == null) {
        _genderError = 'Please select your gender';
        valid = false;
      }
      if (_placeController.text.trim().isEmpty) {
        _placeError = 'Please enter your place of birth';
        valid = false;
      } else if (_birthLocation == null) {
        _placeError = 'Please select a place from the search results';
        valid = false;
      }
    });
    return valid;
  }

  // ── API ────────────────────────────────────────────────────────────────────

  Future<void> _createBooking() async {
    // Validate birth details first
    if (!_validateBirthDetails()) {
      // Scroll user's attention — show a snackbar hint
      _showError('Please fill in all birth details to proceed.');
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final booking = _pendingBooking ??
          await BookingService.createBooking(
            astrologerId: widget.astrologer.id,
            consultationType: widget.type == 'call' ? 'call' : 'chat',
            duration: widget.duration,
            bookingDate: _formatDateForApi(widget.date),
            bookingTime: widget.time,
            notes: 'Booked from mobile app',
            birthDetails: {
              'date_of_birth': _formatBirthDateForApi(_birthDate!),
              'time_of_birth': _formatBirthTimeForApi(_birthTime!),
              'place_of_birth': _placeController.text.trim(),
              'latitude': _birthLocation!.latitude,
              'longitude': _birthLocation!.longitude,
              'coordinates': _birthLocation!.coordinates,
              'gender': _selectedGender!,
            },
          );
      _pendingBooking = booking;

      final paymentOrder = await _razorpayService.createOrder(
        purpose: 'consultation',
        recordId: booking.id,
      );
      if (paymentOrder.keyId.isEmpty || paymentOrder.orderId.isEmpty) {
        throw Exception('Razorpay payment could not be initialized.');
      }
      _razorpay.open({
        'key': paymentOrder.keyId,
        'amount': paymentOrder.amount,
        'currency': paymentOrder.currency,
        'order_id': paymentOrder.orderId,
        'name': 'Astrozura',
        'description': '${widget.duration} minute ${widget.type} consultation',
        'theme': {'color': '#0D437B'},
      });
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final booking = _pendingBooking;
    if (booking == null) {
      if (mounted) setState(() => _isLoading = false);
      _showError('Payment received. Please check My Bookings for its status.');
      return;
    }
    try {
      await _razorpayService.verifyPayment(
        purpose: 'consultation',
        recordId: booking.id,
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );
      if (!mounted) return;
      _navigateToConfirmation(booking);
    } catch (error) {
      if (mounted) setState(() => _isLoading = false);
      _showError(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) setState(() => _isLoading = false);
    _showError(
      response.message?.trim().isNotEmpty == true
          ? response.message!
          : 'Payment was not completed. You can retry safely.',
    );
  }

  void _navigateToConfirmation(BookingModel booking) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(
          bookingReference: booking.bookingReference,
          sessionType: widget.type,
          date: widget.date,
          time: widget.time,
          totalAmount: booking.amount,
          astrologer: widget.astrologer,
        ),
      ),
      (route) => false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.lato()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDD6),
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            'Payment Method',
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
                      child: _buildStepIndicator(),
                    ),

                    const SizedBox(height: 20),
                    _buildBookingSummarySection(),
                    const SizedBox(height: 24),

                    // ── Birth Details (NEW) ────────────────────────────────
                    _buildBirthDetailsSection(),
                    const SizedBox(height: 24),

                    _buildSelectMethodSection(),
                    const SizedBox(height: 20),
                    _buildSecurityBanner(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Step indicator ──────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STEP 3 OF 3',
              style: GoogleFonts.lato(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Payment method',
              style: GoogleFonts.lato(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5B3EAC),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 1.0,
            minHeight: 4,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5B3EAC)),
          ),
        ),
      ],
    );
  }

  // ── Booking Summary ─────────────────────────────────────────────────────────

  Widget _buildBookingSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking Summary',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final astro = widget.astrologer;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B56C8), Color(0xFF4A3AA0)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B3EAC).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CONSULTATION DETAILS',
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A73A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Standard Reading',
                    style: GoogleFonts.lato(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: astro.fullImageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            astro.fullImageUrl,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          widget.type == 'call'
                              ? Icons.videocam_outlined
                              : Icons.chat_bubble_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sessionTypeLabel,
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'With ${astro.name ?? "Astrologer"}',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rs ${_subtotal.toStringAsFixed(2)}',
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _dateBadge(
                  icon: Icons.calendar_today_outlined,
                  label: _formatDate(widget.date),
                ),
                const SizedBox(width: 10),
                _dateBadge(
                  icon: Icons.access_time_outlined,
                  label: _formatTimeWithDuration(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: Colors.white.withOpacity(0.15),
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _priceRow('Subtotal', 'Rs ${_subtotal.toStringAsFixed(2)}',
                    isLight: true),
                const SizedBox(height: 12),
                Divider(color: Colors.white.withOpacity(0.15), height: 1),
                const SizedBox(height: 12),
                _priceRow(
                  'Total Amount',
                  'Rs ${_total.toStringAsFixed(2)}',
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.85)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value,
      {bool isLight = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isLight ? Colors.white.withOpacity(0.75) : Colors.white,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: isBold ? const Color(0xFFD4A73A) : Colors.white,
          ),
        ),
      ],
    );
  }

  // ── Birth Details Section (NEW) ─────────────────────────────────────────────

  Widget _buildBirthDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'Birth Details',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Required for your consultation with the astrologer',
          style: GoogleFonts.lato(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Date of Birth + Time of Birth ────────────────────
              Row(
                children: [
                  Expanded(
                    child: _buildBirthDetailField(
                      label: 'Date of Birth',
                      displayValue: _birthDateDisplay,
                      icon: Icons.calendar_today_outlined,
                      hasValue: _birthDate != null,
                      errorText: _birthDateError,
                      onTap: _pickBirthDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBirthDetailField(
                      label: 'Time of Birth',
                      displayValue: _birthTimeDisplay,
                      icon: Icons.access_time_outlined,
                      hasValue: _birthTime != null,
                      errorText: _birthTimeError,
                      onTap: _pickBirthTime,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Row 2: Place of Birth + Gender ───────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Place of Birth — text input
                  Expanded(
                    child: _buildPlaceOfBirthField(),
                  ),
                  const SizedBox(width: 12),
                  // Gender — dropdown
                  Expanded(
                    child: _buildGenderDropdown(),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Disclaimer ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EDD6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFFB38A2E),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'These details are shared with the astrologer and can be used during kundali, birth-chart, matchmaking, tarot, or palmistry guidance.',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tappable field for date/time pickers
  Widget _buildBirthDetailField({
    required String label,
    required String displayValue,
    required IconData icon,
    required bool hasValue,
    required String? errorText,
    required VoidCallback onTap,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color:
                  hasError ? const Color(0xFFFFEEEE) : const Color(0xFFF9F5EC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? Colors.redAccent.withOpacity(0.6)
                    : hasValue
                        ? const Color(0xFF5B3EAC).withOpacity(0.4)
                        : Colors.grey.shade200,
                width: hasValue || hasError ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color:
                      hasValue ? const Color(0xFF5B3EAC) : Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayValue,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: hasValue
                          ? const Color(0xFF2D2D2D)
                          : Colors.grey.shade400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: GoogleFonts.lato(
              fontSize: 10,
              color: Colors.redAccent,
            ),
          ),
        ],
      ],
    );
  }

  /// Text input for Place of Birth
  Widget _buildPlaceOfBirthField() {
    final hasError = _placeError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Place of Birth',
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 6),
        LocationSearchField(
          controller: _placeController,
          hintText: 'City, State, Country',
          onSelected: (selection) {
            setState(() {
              _birthLocation = selection;
              _placeError = null;
            });
          },
          style: GoogleFonts.lato(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D2D2D),
          ),
          decoration: InputDecoration(
            hintText: 'City, State, Country',
            hintStyle: GoogleFonts.lato(
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
            prefixIcon: Icon(
              Icons.location_on_outlined,
              size: 16,
              color: _placeController.text.isNotEmpty
                  ? const Color(0xFF5B3EAC)
                  : Colors.grey.shade400,
            ),
            filled: true,
            fillColor:
                hasError ? const Color(0xFFFFEEEE) : const Color(0xFFF9F5EC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? Colors.redAccent.withOpacity(0.6)
                    : Colors.grey.shade200,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF5B3EAC),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.redAccent.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.5,
              ),
            ),
            isDense: true,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            _placeError!,
            style: GoogleFonts.lato(
              fontSize: 10,
              color: Colors.redAccent,
            ),
          ),
        ],
      ],
    );
  }

  /// Dropdown for Gender selection
  Widget _buildGenderDropdown() {
    final hasError = _genderError != null;
    final hasValue = _selectedGender != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showGenderBottomSheet(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color:
                  hasError ? const Color(0xFFFFEEEE) : const Color(0xFFF9F5EC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? Colors.redAccent.withOpacity(0.6)
                    : hasValue
                        ? const Color(0xFF5B3EAC).withOpacity(0.4)
                        : Colors.grey.shade200,
                width: hasValue || hasError ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color:
                      hasValue ? const Color(0xFF5B3EAC) : Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasValue
                        ? _selectedGender![0].toUpperCase() +
                            _selectedGender!.substring(1)
                        : 'Select gender',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: hasValue
                          ? const Color(0xFF2D2D2D)
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color:
                      hasValue ? const Color(0xFF5B3EAC) : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            _genderError!,
            style: GoogleFonts.lato(
              fontSize: 10,
              color: Colors.redAccent,
            ),
          ),
        ],
      ],
    );
  }

  /// Bottom sheet for gender selection — keeps the page theme
  void _showGenderBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5EDD6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Select Gender',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 16),
              ...['male', 'female', 'other'].map((gender) {
                final isSelected = _selectedGender == gender;
                final label = gender[0].toUpperCase() + gender.substring(1);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGender = gender;
                      _genderError = null;
                    });
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFFEDE6FF) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF5B3EAC)
                            : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          gender == 'male'
                              ? Icons.male
                              : gender == 'female'
                                  ? Icons.female
                                  : Icons.transgender,
                          size: 20,
                          color: isSelected
                              ? const Color(0xFF5B3EAC)
                              : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF5B3EAC)
                                  : const Color(0xFF2D2D2D),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF5B3EAC),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // Payment method

  Widget _buildSelectMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF5B3EAC), width: 1.5),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFD4A73A),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Razorpay',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF5B3EAC),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'UPI, cards, wallets and net banking',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.check_circle, color: Color(0xFF5B3EAC)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Security banner ─────────────────────────────────────────────────────────

  Widget _buildSecurityBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF3B2F7A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD4A73A).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              color: Color(0xFFD4A73A),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your connection is encrypted. Astro Zura does not store full credit card details on our servers.',
              style: GoogleFonts.lato(
                fontSize: 12,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ──────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5EDD6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total to Pay',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Rs ${_total.toStringAsFixed(2)}',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF154C89),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A73A),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Confirm & Pay Rs ${_total.toStringAsFixed(2)}',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
