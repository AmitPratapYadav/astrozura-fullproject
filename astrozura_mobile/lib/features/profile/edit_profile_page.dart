// lib/pages/edit_profile_page.dart
//
// Edit Profile – now includes the shared AppDrawer via the menu icon
// in the SliverAppBar leading button. All other logic is unchanged.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/contants/app_colors.dart';
import '../../core/services/auth_services.dart';
import '../shared/widgets/location_search_field.dart';
import './widgets/app_drawer.dart'; // ← shared drawer
import './profile_screen.dart'; // UserProfile
import 'package:provider/provider.dart';

import '../../core/providers/profile_provider.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _navy = Color(0xFF2E2A72);
const _navyDark = Color(0xFF2E2A72);
const _gold = Color(0xFFC9A84C);
const _goldLight = Color(0xFFF5E6C0);
const _goldSoft = Color(0xFFFBF3DC);
const _bg = Color(0xFFF4F6FB);
const _cardBg = Colors.white;
const _textPrimary = Color(0xFF1A1A2E);
const _textSec = AppColors.subtitleText;
const _inputBorder = Color(0xFFE2E8F0);
const _inputFill = Color(0xFFF8FAFC);

const double _avatarRadius = 56.0;
const double _avatarOverlap = _avatarRadius + 4;

// ═════════════════════════════════════════════════════════════════════════════
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin, AppDrawerMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _tobCtrl = TextEditingController();
  final _pobCtrl = TextEditingController();

  String _selectedGender = 'Male';
  bool _loading = true;
  bool _saving = false;
  UserProfile? _user;
  File? _pickedImage;
  String? _savedAvatarPath;
  LocationSelection? _birthLocation;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    initDrawer(); // ← AppDrawerMixin
    _loadProfile();
  }

  @override
  void dispose() {
    drawerCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _tobCtrl.dispose();
    _pobCtrl.dispose();
    super.dispose();
  }

  // ── Load ─────────────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await UserProfile.load();
    setState(() {
      _user = user;
      _nameCtrl.text = user.name;
      _phoneCtrl.text = prefs.getString('user_phone') ?? user.phone;
      _emailCtrl.text = prefs.getString('user_email') ?? '';
      _selectedGender = prefs.getString('user_gender') ?? 'Male';
      _dobCtrl.text = prefs.getString('user_dob') ?? '';
      _tobCtrl.text = prefs.getString('user_tob') ?? '';
      _pobCtrl.text = prefs.getString('user_pob') ?? '';
      final lat = prefs.getDouble('user_pob_lat');
      final lng = prefs.getDouble('user_pob_lng');
      if (lat != null && lng != null && _pobCtrl.text.trim().isNotEmpty) {
        _birthLocation = LocationSelection(
          name: _pobCtrl.text.trim(),
          latitude: lat,
          longitude: lng,
        );
      }
      _savedAvatarPath = prefs.getString('user_avatar_local');
      _loading = false;
    });
  }

  // ── Save ─────────────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final result = await AuthService().updateProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      gender: _selectedGender,
      dob: _dobCtrl.text.trim(),
      tob: _tobCtrl.text.trim(),
      pob: _pobCtrl.text.trim(),
      latitude: _birthLocation?.latitude,
      longitude: _birthLocation?.longitude,
      profileImagePath: _pickedImage?.path,
    );

    if (!mounted) return;

    if (result['success'] != true) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Profile update failed.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final user = result['user'] as Map<String, dynamic>? ?? {};
    await prefs.setString(
      'user_name',
      user['name']?.toString() ?? _nameCtrl.text.trim(),
    );
    await prefs.setString(
      'user_email',
      user['email']?.toString() ?? _emailCtrl.text.trim(),
    );
    await prefs.setString('user_gender', _selectedGender);
    await prefs.setString('user_dob', _dobCtrl.text.trim());
    await prefs.setString('user_tob', _tobCtrl.text.trim());
    await prefs.setString('user_pob', _pobCtrl.text.trim());
    if (_birthLocation != null) {
      await prefs.setDouble('user_pob_lat', _birthLocation!.latitude);
      await prefs.setDouble('user_pob_lng', _birthLocation!.longitude);
    } else {
      await prefs.remove('user_pob_lat');
      await prefs.remove('user_pob_lng');
    }
    await prefs.remove('user_avatar_local');
    if (_dobCtrl.text.isNotEmpty &&
        _tobCtrl.text.isNotEmpty &&
        _pobCtrl.text.isNotEmpty &&
        _birthLocation != null) {
      await prefs.setBool('has_birth_details', true);
    } else {
      await prefs.setBool('has_birth_details', false);
    }
    await context.read<ProfileProvider>().applyServerProfile(user);
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: const [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text('Profile saved successfully!',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: _navy,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context, true);
  }

  // ── Image Picker ─────────────────────────────────────────────────────────
  Future<void> _showImageSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ImageSourceSheet(
        onCamera: () async {
          Navigator.pop(context);
          final xf = await _picker.pickImage(
              source: ImageSource.camera, imageQuality: 85);
          if (xf != null) setState(() => _pickedImage = File(xf.path));
        },
        onGallery: () async {
          Navigator.pop(context);
          final xf = await _picker.pickImage(
              source: ImageSource.gallery, imageQuality: 85);
          if (xf != null) setState(() => _pickedImage = File(xf.path));
        },
        onRemove: (_pickedImage != null || _savedAvatarPath != null)
            ? () {
                Navigator.pop(context);
                setState(() {
                  _pickedImage = null;
                  _savedAvatarPath = null;
                });
              }
            : null,
      ),
    );
  }

  // ── Date / Time ───────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _navy,
            secondary: _gold,
            onPrimary: Colors.white,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text = '${picked.year.toString().padLeft(4, '0')}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: _navy, secondary: _gold, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _tobCtrl.text = '${picked.hour.toString().padLeft(2, '0')}:'
            '${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Main page content ─────────────────────────────────────────────
          _loading
              ? const Center(child: CircularProgressIndicator(color: _gold))
              : Form(
                  key: _formKey,
                  child: CustomScrollView(
                    slivers: [
                      _buildSliverAppBar(context),
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SizedBox(height: _avatarOverlap + 16),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildNameBadge(),
                                  const SizedBox(height: 28),
                                  _SectionLabel(
                                    icon: Icons.person_outline_rounded,
                                    title: 'Personal Information',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildPersonalCard(),
                                  const SizedBox(height: 24),
                                  _SectionLabel(
                                    icon: Icons.auto_awesome_rounded,
                                    title: 'Astrology & Birth Details',
                                    subtitle:
                                        'Required for kundli, horoscope & compatibility',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildBirthCard(),
                                  const SizedBox(height: 32),
                                  _buildSaveButton(),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

          // ── Shared drawer overlay ─────────────────────────────────────────
          if (_user != null)
            ...buildDrawerOverlay(
              user: _user!,
              activeRoute: AppDrawerRoute.editProfile,
            ),
        ],
      ),
    );
  }

  // ── SliverAppBar ──────────────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    const double visualHeroHeight = 200.0;
    const double expandedHeight = visualHeroHeight + _avatarOverlap;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      backgroundColor: _navy,
      elevation: 0,
      // ── LEADING: hamburger menu (replaces back arrow when drawer is used)
      // We keep both: hamburger opens drawer, back arrow is in actions.
      // Actually the cleanest UX: leading = hamburger, action = Save.
      // Users can still pop with swipe gesture.
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: openDrawer, // ← opens shared drawer
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.28), width: 1),
            ),
            child: const Icon(Icons.menu, color: Colors.white, size: 20),
          ),
        ),
      ),
      actions: [
        // Back / close button
        Padding(
          padding: const EdgeInsets.only(right: 4, top: 10, bottom: 10),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28), width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 17),
            ),
          ),
        ),
        // Save button
        Padding(
          padding: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
          child: GestureDetector(
            onTap: _saving ? null : _saveProfile,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: _gold,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _saving
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              bottom: _avatarOverlap + 10,
              left: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gold.withValues(alpha: 0.07),
                ),
              ),
            ),
            for (final s in [
              [0.12, 0.20, 5.0],
              [0.72, 0.15, 4.0],
              [0.85, 0.55, 6.0],
              [0.35, 0.70, 4.0],
              [0.55, 0.35, 5.0],
              [0.08, 0.60, 7.0],
            ])
              Positioned(
                left: w * (s[0]),
                top: 200.0 * (s[2]),
                child: Icon(Icons.star_rounded,
                    size: s[2], color: Colors.white.withValues(alpha: 0.22)),
              ),
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(child: _buildAvatarSection()),
            ),
          ],
        ),
      ),
    );
  }

  // ── Avatar ────────────────────────────────────────────────────────────────
  Widget _buildAvatarSection() {
    ImageProvider? imgProvider;
    if (_pickedImage != null) {
      imgProvider = FileImage(_pickedImage!);
    } else if (_savedAvatarPath != null) {
      imgProvider = FileImage(File(_savedAvatarPath!));
    } else if (_user?.avatarUrl != null) {
      imgProvider = NetworkImage(_user!.avatarUrl!);
    }

    final initials =
        (_user?.name.isNotEmpty ?? false) ? _user!.name[0].toUpperCase() : 'U';

    const double ringPad = 4.0;
    const double whitePad = 3.0;
    final double outerD = (ringPad + whitePad + _avatarRadius) * 2;

    return SizedBox(
      width: outerD,
      height: outerD,
      child: Stack(
        children: [
          Container(
            width: outerD,
            height: outerD,
            padding: const EdgeInsets.all(ringPad),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFE8C96A), _gold, Color(0xFFB8942A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.40),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Container(
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white),
              padding: const EdgeInsets.all(whitePad),
              child: CircleAvatar(
                radius: _avatarRadius,
                backgroundColor: _navy,
                backgroundImage: imgProvider,
                child: imgProvider == null
                    ? Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 38,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImageSheet,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8C96A), _gold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 17, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameBadge() {
    return Column(
      children: [
        Text(
          _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Your Name',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: _textPrimary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ── Personal Info Card ────────────────────────────────────────────────────
  Widget _buildPersonalCard() {
    return _FormCard(children: [
      _FieldLabel('Full Name'),
      _buildInput(
        controller: _nameCtrl,
        hint: 'Enter your full name',
        icon: Icons.person_outline_rounded,
        onChanged: (_) => setState(() {}),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Name is required' : null,
      ),
      const SizedBox(height: 18),
      _FieldLabel('Gender'),
      _buildGenderSelector(),
      const SizedBox(height: 18),
      _FieldLabel('Email Address'),
      _buildInput(
        controller: _emailCtrl,
        hint: 'Enter your email',
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 18),
      _FieldLabel('Phone Number'),
      _buildInput(
        controller: _phoneCtrl,
        hint: 'Phone number cannot be changed',
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
        readOnly: true,
      ),
    ]);
  }

  // ── Birth Details Card ────────────────────────────────────────────────────
  Widget _buildBirthCard() {
    return _FormCard(children: [
      _FieldLabel('Date of Birth'),
      _buildTappableInput(
        controller: _dobCtrl,
        hint: 'Select date  (YYYY-MM-DD)',
        icon: Icons.calendar_today_outlined,
        onTap: _pickDate,
      ),
      const SizedBox(height: 18),
      _FieldLabel('Time of Birth'),
      _buildTappableInput(
        controller: _tobCtrl,
        hint: 'Select time  (HH:MM)',
        icon: Icons.access_time_rounded,
        onTap: _pickTime,
      ),
      const SizedBox(height: 18),
      _FieldLabel('Place of Birth'),
      LocationSearchField(
        controller: _pobCtrl,
        initialSelection: _birthLocation,
        hintText: 'Search city and select from list',
        onSelected: (selection) => setState(() => _birthLocation = selection),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _goldSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gold.withValues(alpha: 0.32)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.auto_awesome_rounded, color: _gold, size: 17),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Accurate birth details improve your kundli, horoscope, and compatibility readings.',
                style: TextStyle(
                    fontSize: 12.5, color: Color(0xFF7A5C0A), height: 1.5),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  // ── Save Button ───────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _saving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _gold.withValues(alpha: 0.5),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: _saving
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Save Profile Changes',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Input builders ────────────────────────────────────────────────────────
  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
      enableInteractiveSelection: !readOnly,
      style: const TextStyle(
          fontSize: 14.5, color: _textPrimary, fontWeight: FontWeight.w500),
      decoration: _deco(hint: hint, icon: icon, readOnly: readOnly),
    );
  }

  Widget _buildTappableInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          style: const TextStyle(
              fontSize: 14.5, color: _textPrimary, fontWeight: FontWeight.w500),
          decoration: _deco(hint: hint, icon: icon, isSuffix: true),
        ),
      ),
    );
  }

  InputDecoration _deco({
    required String hint,
    required IconData icon,
    bool isSuffix = false,
    bool readOnly = false,
  }) {
    final ico = Icon(
      icon,
      size: 19,
      color: readOnly ? const Color(0xFF94A3B8) : const Color(0xFFB0BEC5),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          color: Color(0xFFBDBDBD),
          fontSize: 13.5,
          fontWeight: FontWeight.w400),
      filled: true,
      fillColor: readOnly ? const Color(0xFFEFF3F8) : _inputFill,
      prefixIcon: isSuffix ? null : ico,
      suffixIcon: readOnly
          ? const Icon(Icons.lock_outline_rounded,
              size: 18, color: Color(0xFF94A3B8))
          : isSuffix
              ? ico
              : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: _ob(),
      enabledBorder: _ob(),
      focusedBorder: _ob(focused: true),
      errorBorder: _ob(error: true),
      focusedErrorBorder: _ob(error: true),
    );
  }

  OutlineInputBorder _ob({bool focused = false, bool error = false}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: error
              ? Colors.red.shade400
              : focused
                  ? _navy
                  : _inputBorder,
          width: (focused || error) ? 1.8 : 1.2,
        ),
      );

  // ── Gender Selector ───────────────────────────────────────────────────────
  Widget _buildGenderSelector() {
    const opts = ['Male', 'Female', 'Other'];
    const icons = [
      Icons.male_rounded,
      Icons.female_rounded,
      Icons.transgender_rounded
    ];
    return Row(
      children: List.generate(opts.length, (i) {
        final sel = opts[i] == _selectedGender;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedGender = opts[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < opts.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: sel ? _navy : _inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: sel ? _navy : _inputBorder,
                  width: 1.4,
                ),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: _navy.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icons[i],
                      size: 17, color: sel ? Colors.white : _textSec),
                  const SizedBox(width: 5),
                  Text(
                    opts[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel ? Colors.white : _textSec,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Image Source Bottom Sheet ─────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _ImageSourceSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onRemove;

  const _ImageSourceSheet({
    required this.onCamera,
    required this.onGallery,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Column(children: [
              const Text('Update Profile Photo',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary)),
              const SizedBox(height: 4),
              Text('Choose how you\'d like to update your photo',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            ]),
          ),
          const SizedBox(height: 16),
          _SheetTile(
            icon: Icons.camera_alt_rounded,
            iconBg: _navy.withValues(alpha: 0.08),
            iconColor: _navy,
            label: 'Take a Photo',
            subtitle: 'Use your camera',
            onTap: onCamera,
          ),
          _Divider(),
          _SheetTile(
            icon: Icons.photo_library_outlined,
            iconBg: _navy.withValues(alpha: 0.08),
            iconColor: _navy,
            label: 'Choose from Gallery',
            subtitle: 'Pick from your photo library',
            onTap: onGallery,
          ),
          if (onRemove != null) ...[
            _Divider(),
            _SheetTile(
              icon: Icons.delete_outline_rounded,
              iconBg: Colors.red.shade50,
              iconColor: Colors.red.shade400,
              label: 'Remove Photo',
              subtitle: 'Revert to initials avatar',
              onTap: onRemove!,
              isDestructive: true,
            ),
          ],
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Text('Cancel',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SheetTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: iconColor, size: 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color:
                            isDestructive ? Colors.red.shade500 : _textPrimary,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12.5, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade300, size: 22),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
      height: 1, indent: 82, endIndent: 20, color: Colors.grey.shade100);
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Shared form widgets ───────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const _SectionLabel({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _navy, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: TextStyle(fontSize: 12, color: _textSec)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: _textSec,
          ),
        ),
      );
}
