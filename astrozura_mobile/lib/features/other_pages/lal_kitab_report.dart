import 'package:flutter/material.dart';
import '../mainwidgets/header.dart';

class _AC {
  static const Color goldLight = Color(0xFFFFF3D0);
  static const Color gold = Color(0xFFD4A017);
  static const Color maroon = Color(0xFF973B43);
  static const Color afflicted = Color(0xFFE53935);
  static const Color highEnergy = Color(0xFF00ACC1);
  static const Color exalted = Color(0xFF43A047);
  static const Color propitious = Color(0xFF757575);
  static const Color remedyBg = Color(0xFFFFF8E1);
  static const Color remedyBorder = Color(0xFFFFE082);
  static const Color remedyText = Color(0xFFB8860B);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
}

class LalKitabReportScreen extends StatefulWidget {
  const LalKitabReportScreen({super.key});

  @override
  State<LalKitabReportScreen> createState() => _LalKitabReportScreenState();
}

class _LalKitabReportScreenState extends State<LalKitabReportScreen> {
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _tobController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();

  /// Whether the user has tapped "Generate Lal Kitab Report"
  bool _isGenerated = false;

  /// True only when ALL three fields are non-empty
  bool get _hasDetails =>
      _dobController.text.trim().isNotEmpty &&
      _tobController.text.trim().isNotEmpty &&
      _placeController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Rebuild when any field changes so the button / empty-state reacts live
    _dobController.addListener(_onFieldChanged);
    _tobController.addListener(_onFieldChanged);
    _placeController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  void _onGenerate() {
    if (!_hasDetails) return;
    setState(() => _isGenerated = true);
  }

  Future<void> _pickDate() async {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(_dobController.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => _goldTheme(context, child),
    );
    if (picked != null) {
      _dobController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(_tobController.text) ?? TimeOfDay.now(),
      builder: (context, child) => _goldTheme(context, child),
    );
    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      _tobController.text = '$hour:$minute $period';
    }
  }

  /// Parse dd/MM/yyyy string back to DateTime for initialDate
  DateTime? _parseDate(String text) {
    try {
      final parts = text.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
    return null;
  }

  /// Parse "h:mm AM/PM" string back to TimeOfDay for initialTime
  TimeOfDay? _parseTime(String text) {
    try {
      final parts = text.split(' ');
      if (parts.length == 2) {
        final hm = parts[0].split(':');
        int hour = int.parse(hm[0]);
        final minute = int.parse(hm[1]);
        final isPm = parts[1].toUpperCase() == 'PM';
        if (isPm && hour != 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return null;
  }

  /// Applies gold accent to date/time picker dialogs
  Widget _goldTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: _AC.gold,
          onPrimary: Colors.white,
          onSurface: _AC.textPrimary,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _AC.gold),
        ),
      ),
      child: child!,
    );
  }

  @override
  void dispose() {
    _dobController.dispose();
    _tobController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, _AC.goldLight],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              HeaderWidget(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // ── Banner ──
                      _BannerCard(),

                      const SizedBox(height: 20),

                      // ── Birth Inputs ──
                      _BirthInputsCard(
                        dobController: _dobController,
                        tobController: _tobController,
                        placeController: _placeController,
                        hasDetails: _hasDetails,
                        onGenerate: _onGenerate,
                        onPickDate: _pickDate,
                        onPickTime: _pickTime,
                      ),

                      const SizedBox(height: 20),

                      // ── Analysis Section ──
                      if (!_isGenerated)
                        _ReadyToGenerateCard(hasDetails: _hasDetails)
                      else ...[
                        _GeneratedAnalysisHeader(),
                        const SizedBox(height: 16),
                        _PlanetCard(
                          icon: '☀️',
                          name: 'Sun (Surya)',
                          status: 'Propitious',
                          statusColor: _AC.propitious,
                          description:
                              'Placed in the 10th house. Indicates strong career prospects and paternal support. Your leadership qualities will shine in the public domain.',
                          remedy:
                              '"Pour some milk or water on the roots of a Banyan tree."',
                        ),
                        const SizedBox(height: 12),
                        _PlanetCard(
                          icon: '🌙',
                          name: 'Moon (Chandra)',
                          status: 'Afflicted',
                          statusColor: _AC.afflicted,
                          statusBgColor: const Color(0xFFFFEBEE),
                          description:
                              'Conjunction with Rahu creates mental unrest. Emotional stability may be challenged during specific transits.',
                          remedy:
                              '"Keep a silver square piece in your wallet at all times."',
                        ),
                        const SizedBox(height: 12),
                        _PlanetCard(
                          icon: '⚡',
                          name: 'Mars (Mangal)',
                          status: 'High Energy',
                          statusColor: _AC.highEnergy,
                          statusBgColor: const Color(0xFFE0F7FA),
                          description:
                              'Mars in the 1st house gives immense courage. Avoid impulsive decisions related to property or siblings.',
                          remedy:
                              '"Feed sweet bread (Tandoori Meethi Roti) to dogs."',
                        ),
                        const SizedBox(height: 12),
                        _PlanetCard(
                          icon: '⭐',
                          name: 'Jupiter (Guru)',
                          status: 'Exalted',
                          statusColor: _AC.exalted,
                          statusBgColor: const Color(0xFFE8F5E9),
                          description:
                              'Jupiter provides divine protection. Academic and spiritual pursuits will yield significant rewards this year.',
                          remedy:
                              '"Apply a saffron (Kesar) tilak on your forehead every morning."',
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              'View Detailed Debts & Houses  >',
                              style: TextStyle(
                                color: _AC.maroon,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                    ],
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

// ─────────────────────────────────────────────
// Ready To Generate Empty-State Card
// ─────────────────────────────────────────────
class _ReadyToGenerateCard extends StatelessWidget {
  final bool hasDetails;
  const _ReadyToGenerateCard({required this.hasDetails});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sparkle icon circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('✨', style: TextStyle(fontSize: 30)),
            ),
          ),

          const SizedBox(height: 16),

          // Pill badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _AC.maroon,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  hasDetails ? 'Ready to Generate' : 'Add DOB Details',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _AC.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Ready to Generate',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _AC.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'This standalone Lal Kitab page uses the working Astrology API route directly. Submit birth details to view remedies, planet observations, house patterns, and sign occupancy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _AC.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Banner Card
// ─────────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF973B43),
            Color(0xFFC96A3B),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'LAL KITAB REPORTS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Generate Your Lal Kitab\nGuidance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review planetary tendencies, house-level observations, and practical Lal Kitab-style remedial guidance from your birth details.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Birth Inputs Card
// ─────────────────────────────────────────────
class _BirthInputsCard extends StatelessWidget {
  final TextEditingController dobController;
  final TextEditingController tobController;
  final TextEditingController placeController;
  final bool hasDetails;
  final VoidCallback onGenerate;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  const _BirthInputsCard({
    required this.dobController,
    required this.tobController,
    required this.placeController,
    required this.hasDetails,
    required this.onGenerate,
    required this.onPickDate,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Birth Inputs',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _AC.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter exact birth details for accurate Lal Kitab calculations.',
            style: TextStyle(fontSize: 12, color: _AC.textSecondary),
          ),
          const SizedBox(height: 16),

          _InputField(
            label: 'Date of Birth',
            controller: dobController,
            suffixIcon: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: onPickDate,
            hint: 'DD/MM/YYYY',
          ),
          const SizedBox(height: 12),

          _InputField(
            label: 'Time of Birth',
            controller: tobController,
            suffixIcon: Icons.access_time_outlined,
            readOnly: true,
            onTap: onPickTime,
            hint: 'HH:MM AM/PM',
          ),
          const SizedBox(height: 12),

          _InputField(
            label: 'Birth Place',
            controller: placeController,
            suffixIcon: Icons.location_on_outlined,
            hint: 'City, State, Country',
            helperText: placeController.text.isNotEmpty
                ? 'Coordinates: 28.6138954, 77.2090057'
                : null,
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasDetails ? onGenerate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _AC.gold,
                disabledBackgroundColor: _AC.gold.withValues(alpha: 0.45),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Generate Lal Kitab Report',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData suffixIcon;
  final String? helperText;
  final String? hint;
  final bool readOnly;
  final VoidCallback? onTap;

  const _InputField({
    required this.label,
    required this.controller,
    required this.suffixIcon,
    this.helperText,
    this.hint,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _AC.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          // Show cursor even in readOnly so it looks interactive
          showCursor: true,
          style: const TextStyle(fontSize: 14, color: _AC.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
            suffixIcon: GestureDetector(
              onTap: onTap,
              child: Icon(suffixIcon, size: 18, color: _AC.textSecondary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _AC.gold),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style:
                const TextStyle(fontSize: 11, color: _AC.textSecondary),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Generated Analysis Header
// ─────────────────────────────────────────────
class _GeneratedAnalysisHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generated Analysis',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _AC.textPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Computed on 10 May 2025, 12:45 PM',
              style: TextStyle(fontSize: 11, color: _AC.textSecondary),
            ),
          ],
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.info_outline,
              size: 20, color: _AC.textSecondary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Planet Card
// ─────────────────────────────────────────────
class _PlanetCard extends StatelessWidget {
  final String icon;
  final String name;
  final String status;
  final Color statusColor;
  final Color? statusBgColor;
  final String description;
  final String remedy;

  const _PlanetCard({
    required this.icon,
    required this.name,
    required this.status,
    required this.statusColor,
    this.statusBgColor,
    required this.description,
    required this.remedy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _AC.textPrimary,
                    ),
                  ),
                ],
              ),
              _StatusBadge(
                label: status,
                color: statusColor,
                bgColor: statusBgColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: _AC.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _AC.remedyBg,
              border: Border.all(color: _AC.remedyBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    const Text(
                      'LAL KITAB REMEDY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _AC.remedyText,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  remedy,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _AC.textPrimary,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Status Badge
// ─────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? bgColor;

  const _StatusBadge({
    required this.label,
    required this.color,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}