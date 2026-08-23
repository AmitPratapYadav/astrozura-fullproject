// lib/pages/profile_page.dart
//
// Profile screen – uses the shared AppDrawer from app_drawer.dart
//
// FIX: Data was only visible after a manual refresh because _loadAll() was
// called in initState() synchronously, before the widget tree settled and
// before SharedPreferences had handed back the auth token on cold start.
//
// Solution:
//   1. WidgetsBinding.addPostFrameCallback  → defers first fetch until after
//      the first frame is painted, guaranteeing token + widget are ready.
//   2. WidgetsBindingObserver               → re-fetches when the app resumes
//      from background (AppLifecycleState.resumed).
//   3. RouteAware (didPopNext)              → re-fetches when the user pops
//      back to this screen from a child route (e.g. EditProfilePage).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/contants/app_colors.dart';
import '../../core/services/auth_services.dart';
import '../../core/services/booking_service.dart';
import './widgets/app_drawer.dart';
import './edit_profile_page.dart';
import './my_booking_page.dart';
import './my_orders_page.dart';
import '../main_navigation.dart';
import '../auth/login_screen.dart';
import '../web/in_app_web_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/providers/profile_provider.dart';

// ── Color palette ─────────────────────────────────────────────────────────────
const _navy = Color(0xFF0d437b);
const _gold = Color(0xFFC9A84C);
const _goldLight = Color(0xFFF5E6C0);
const _goldSoft = Color(0xFFFBF3DC);
const _cardBg = Colors.white;
const _textPrimary = Color(0xFF1A1A2E);
const _textSec = AppColors.subtitleText;
const _divider = Color(0xFFEEEFF4);

// ── Global RouteObserver (wire this into MaterialApp.navigatorObservers) ──────
// In your main.dart / MaterialApp:
//   navigatorObservers: [profileRouteObserver]
final RouteObserver<ModalRoute<void>> profileRouteObserver =
    RouteObserver<ModalRoute<void>>();

// ── UserProfile ───────────────────────────────────────────────────────────────
class UserProfile {
  final String name;
  final String phone;
  final String? avatarUrl;
  final String? email;
  final String? gender;
  final String? dob;
  final bool hasBirthDetails;

  const UserProfile({
    required this.name,
    required this.phone,
    this.avatarUrl,
    this.email,
    this.gender,
    this.dob,
    this.hasBirthDetails = false,
  });

  static Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final hasBirthDetails = (prefs.getBool('has_birth_details') ?? false) ||
        ((prefs.getString('user_dob') ?? '').trim().isNotEmpty &&
            (prefs.getString('user_tob') ?? '').trim().isNotEmpty &&
            (prefs.getString('user_pob') ?? '').trim().isNotEmpty &&
            prefs.getDouble('user_pob_lat') != null &&
            prefs.getDouble('user_pob_lng') != null);
    return UserProfile(
      name: prefs.getString('user_name') ?? 'User',
      phone: prefs.getString('user_phone') ?? '',
      avatarUrl: prefs.getString('user_avatar'),
      email: prefs.getString('user_email'),
      gender: prefs.getString('user_gender'),
      dob: prefs.getString('user_dob'),
      hasBirthDetails: hasBirthDetails,
    );
  }
}

// ── ProfileScreen ─────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  final Widget? bottomNavigationBar;
  const ProfileScreen({super.key, this.bottomNavigationBar});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with
        SingleTickerProviderStateMixin,
        AppDrawerMixin,
        WidgetsBindingObserver, // ← app lifecycle (resume from background)
        RouteAware {
  // ← navigation lifecycle (pop back to screen)

  // ── State ──────────────────────────────────────────────────────────────────
  UserProfile? _user;
  List<BookingModel> _upcoming = [];
  List<BookingModel> _history = [];
  bool _profileLoading = true;
  bool _bookingsLoading = true;
  String? _bookingsError;

  // Prevents duplicate in-flight requests
  bool _fetchInProgress = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    initDrawer();
    WidgetsBinding.instance.addObserver(this);

    // KEY FIX: defer until after the first frame so the widget is fully
    // mounted and SharedPreferences can resolve the token synchronously.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAll();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route events so we catch didPopNext
    profileRouteObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    profileRouteObserver.unsubscribe(this);
    drawerCtrl.dispose();
    super.dispose();
  }

  // ── WidgetsBindingObserver: re-fetch when app comes back from background ────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _fetchBookings();
    }
  }

  // ── RouteAware: re-fetch when the user pops back to this screen ─────────────
  @override
  void didPopNext() {
    // Called when a pushed route is popped and this route becomes active again
    if (mounted) _loadAll();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  /// Full reload: user profile + bookings
  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() {
      _profileLoading = true;
      _bookingsError = null;
    });

    await context.read<ProfileProvider>().refresh();

    // Load the synchronized profile cache.
    try {
      final user = await UserProfile.load();
      if (!mounted) return;
      setState(() {
        _user = user;
        _profileLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _user = const UserProfile(name: 'User', phone: '');
        _profileLoading = false;
      });
    }

    // Then load bookings from network
    await _fetchBookings();
  }

  /// Network-only bookings fetch — safe to call independently (e.g. pull-to-refresh)
  Future<void> _fetchBookings() async {
    if (!mounted || _fetchInProgress) return;

    _fetchInProgress = true;
    setState(() {
      _bookingsLoading = true;
      _bookingsError = null;
    });

    try {
      // getMyBookings() reads the token fresh from SharedPreferences each call,
      // so it always has the latest session token.
      final result = await BookingService.getMyBookings();
      if (!mounted) return;
      final normalized = _normalizeBookingLists(
        result['upcoming'] ?? const <BookingModel>[],
        result['history'] ?? const <BookingModel>[],
      );
      setState(() {
        _upcoming = normalized.upcoming;
        _history = normalized.history;
        _bookingsLoading = false;
        _bookingsError = null;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _bookingsLoading = false;
        // Keep previous data if any; don't wipe on timeout
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      // Auth errors → silent empty state (user might just not be logged in yet)
      final isAuthError = msg.toLowerCase().contains('log in') ||
          msg.toLowerCase().contains('unauthenticated') ||
          msg.toLowerCase().contains('401') ||
          msg.toLowerCase().contains('unauthorized');
      setState(() {
        _bookingsLoading = false;
        _bookingsError = isAuthError ? null : msg;
        if (isAuthError) {
          _upcoming = [];
          _history = [];
        }
      });
    } finally {
      _fetchInProgress = false;
    }
  }

  // ── Pull-to-refresh ────────────────────────────────────────────────────────
  Future<void> _onRefresh() async {
    await _loadAll();
  }

  Future<void> _openSupportPage(String path) async {
    final title = switch (path) {
      '/about-us' => 'About Us',
      '/contact-support' => 'Contact Support',
      '/privacy-policy' => 'Privacy Policy',
      '/terms-and-conditions' => 'Terms & Conditions',
      _ => 'AstroZura',
    };
    await InAppWebPage.open(context, title: title, pathOrUrl: path);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Show full-screen loader only on very first load when no user yet
    if (_profileLoading && _user == null) {
      return const Scaffold(
        backgroundColor: _goldSoft,
        body: Center(child: CircularProgressIndicator(color: _gold)),
      );
    }

    final user = _user ?? const UserProfile(name: 'User', phone: '');

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      bottomNavigationBar: widget.bottomNavigationBar,
      body: Stack(
        children: [
          // ── Background gradient ─────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, _goldLight],
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                ),
              ),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              color: _gold,
              onRefresh: _onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _ProfileHeader(
                      user: user,
                      onMenuTap: openDrawer,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _ProfileCard(
                          user: user,
                          onProfileChanged: _loadAll,
                        ),
                        const SizedBox(height: 14),
                        _StatsRow(
                          upcoming: _upcoming.length,
                          totalConsultations:
                              _history.length + _upcoming.length,
                          orders: _history.length,
                        ),
                        const SizedBox(height: 14),
                        _RecentActivitySection(
                          upcoming: _upcoming,
                          history: _history,
                          isLoading: _bookingsLoading,
                          error: _bookingsError,
                          onViewAll: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => MyBookingsPage()),
                          ),
                          onRefresh: _fetchBookings,
                          onOpenChat: (bookingId) => Navigator.pushNamed(
                            context,
                            '/chat-session',
                            arguments: {'bookingId': bookingId},
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (!user.hasBirthDetails) ...[
                          _BirthDetailsCard(
                            onSetup: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfilePage(),
                              ),
                            ).then((_) => _loadAll()),
                          ),
                          const SizedBox(height: 14),
                        ],
                        _MenuCard(onOpen: _openSupportPage),
                        const SizedBox(height: 44),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Shared drawer overlay ───────────────────────────────────────
          ...buildDrawerOverlay(
            user: user,
            activeRoute: AppDrawerRoute.profile,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Header ────────────────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _ProfileHeader extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onMenuTap;
  const _ProfileHeader({required this.user, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          _CircleBtn(
            onTap: onMenuTap,
            child: const Icon(Icons.menu, color: Colors.black, size: 30),
          ),
          Expanded(
            child: Text(
              'My Profile',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _gold, width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: user.avatarUrl != null
                    ? Image.network(user.avatarUrl!, fit: BoxFit.cover)
                    : Container(
                        color: _navy,
                        alignment: Alignment.center,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _CircleBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap, child: SizedBox(width: 40, height: 40, child: child));
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Profile Card ──────────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _ProfileCard extends StatelessWidget {
  final UserProfile user;
  final Future<void> Function() onProfileChanged;

  const _ProfileCard({required this.user, required this.onProfileChanged});

  @override
  Widget build(BuildContext context) {
    final details = [
      if (_clean(user.phone) != null)
        _ProfileInfoItem(
          icon: Icons.call_outlined,
          label: 'Mobile',
          value: _formatIndianMobile(_clean(user.phone)!),
        ),
      if (_clean(user.email) != null)
        _ProfileInfoItem(
          icon: Icons.email_outlined,
          label: 'Email',
          value: _clean(user.email)!,
        ),
      if (_clean(user.dob) != null)
        _ProfileInfoItem(
          icon: Icons.cake_outlined,
          label: 'DOB',
          value: _formatDate(user.dob!),
        ),
      if (_clean(user.gender) != null)
        _ProfileInfoItem(
          icon: Icons.transgender_rounded,
          label: 'Gender',
          value: _clean(user.gender)!,
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Navy banner
          Container(
            height: 88,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_navy, Color(0xFF243B8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Column(
              children: [
                _AvatarWithBadge(user: user),
                const SizedBox(height: 10),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: details
                          .map(
                            (detail) => SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width - 104) / 2,
                              child: detail,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfilePage()),
                    );
                    if (changed == true && context.mounted) {
                      await onProfileChanged();
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 14, color: _gold),
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _gold, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String? _clean(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
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
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  static String _formatIndianMobile(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), '');
    final withoutCountry = compact.replaceFirst(RegExp(r'^\+?91-?'), '');
    return '+91-$withoutCountry';
  }
}

class _ProfileInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _goldSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _goldLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: _gold),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textSec,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: label == 'Email' ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarWithBadge extends StatelessWidget {
  final UserProfile user;
  const _AvatarWithBadge({required this.user});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(3.5),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _gold.withOpacity(0.20),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFF90A4AE),
            backgroundImage:
                user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            width: 24,
            height: 24,
            decoration:
                const BoxDecoration(color: _gold, shape: BoxShape.circle),
            child:
                const Icon(Icons.star_rounded, size: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Stats Row ─────────────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _StatsRow extends StatelessWidget {
  final int upcoming;
  final int totalConsultations;
  final int orders;

  const _StatsRow({
    required this.upcoming,
    required this.totalConsultations,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyBookingsPage(),
                ),
              );
            },
            child: _StatCard(
              value: totalConsultations.toString().padLeft(2, '0'),
              label: 'Total Consultations',
              sublabel: '$upcoming upcoming',
              icon: Icons.person_search_rounded,
              iconBg: _navy.withOpacity(0.09),
              iconColor: _navy,
              accentColor: _navy,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyOrdersPage(),
                ),
              );
            },
            child: _StatCard(
              value: orders.toString().padLeft(2, '0'),
              label: 'Orders',
              sublabel: 'completed',
              icon: Icons.check_circle_outline_rounded,
              iconBg: Colors.green.shade50,
              iconColor: Colors.green.shade600,
              accentColor: Colors.green.shade600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String sublabel;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color accentColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary)),
          const SizedBox(height: 2),
          Text(sublabel,
              style: TextStyle(
                  fontSize: 11,
                  color: accentColor,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Recent Activity Section ───────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _RecentActivitySection extends StatelessWidget {
  final List<BookingModel> upcoming;
  final List<BookingModel> history;
  final bool isLoading;
  final String? error;
  final VoidCallback onViewAll;
  final VoidCallback onRefresh;
  final void Function(int) onOpenChat;

  const _RecentActivitySection({
    required this.upcoming,
    required this.history,
    required this.isLoading,
    required this.onViewAll,
    required this.onRefresh,
    required this.onOpenChat,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final displayItems = upcoming.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Sessions',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: _navy),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: const Text(
                'View All',
                style: TextStyle(
                    color: _gold, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Error banner ────────────────────────────────────────────────
        if (error != null) ...[
          _ErrorBanner(message: error!, onRetry: onRefresh),
          const SizedBox(height: 8),
        ],

        // ── Loading skeleton ────────────────────────────────────────────
        if (isLoading)
          const _BookingsLoadingSkeleton()

        // ── Empty state ─────────────────────────────────────────────────
        else if (displayItems.isEmpty)
          _EmptySessionsCard(
            onExplore: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MainNavigation(initialIndex: 1),
              ),
            ),
          )

        // ── Booking cards ───────────────────────────────────────────────
        else
          ...displayItems.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BookingActivityCard(
                bookingId: b.bookingId,
                astrologerName: b.astrologerName,
                consultationType: b.consultationType,
                status: b.status.toUpperCase(),
                scheduledFor: _formatDate(b.scheduledAt),
                amount: 'Rs ${b.amount.toStringAsFixed(2)}',
                paymentStatus: b.paymentStatus,
                isChat: _isChatConsultation(b),
                onAction: () => onOpenChat(b.id),
              ),
            ),
          ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Loading Skeleton ──────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _BookingsLoadingSkeleton extends StatefulWidget {
  const _BookingsLoadingSkeleton();

  @override
  State<_BookingsLoadingSkeleton> createState() =>
      _BookingsLoadingSkeletonState();
}

class _BookingsLoadingSkeletonState extends State<_BookingsLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Column(
        children: List.generate(
          2,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Opacity(
              opacity: _anim.value,
              child: Container(
                height: 170,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title placeholder
                    Container(
                      height: 14,
                      width: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 10,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Birth Details CTA ──────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _BirthDetailsCard extends StatelessWidget {
  final VoidCallback onSetup;
  const _BirthDetailsCard({required this.onSetup});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, Color(0xFF1A2F7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: _gold, size: 17),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Complete Your Birth Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Help us refine your astrological insights by providing your exact birth time and location.',
            style: TextStyle(
              color: Color(0xFFB0BEC5),
              fontSize: 13,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: const Text(
                'Setup Profile',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Menu Card ──────────────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _MenuCard extends StatelessWidget {
  final ValueChanged<String> onOpen;

  const _MenuCard({required this.onOpen});

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _MenuItem(
            icon: Icons.info_outline_rounded,
            label: 'About Us',
            isFirst: true,
            onTap: () => onOpen('/about-us'),
          ),
          const _Divider(),
          _MenuItem(
            icon: Icons.support_agent_rounded,
            label: 'Contact Support',
            onTap: () => onOpen('/contact-support'),
          ),
          const _Divider(),
          _MenuItem(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () => onOpen('/privacy-policy'),
          ),
          const _Divider(),
          _MenuItem(
            icon: Icons.description_outlined,
            label: 'Terms & Conditions',
            onTap: () => onOpen('/terms-and-conditions'),
          ),
          const _Divider(),
          _MenuItem(
            icon: Icons.logout_rounded,
            label: 'Logout',
            isLast: true,
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        indent: 68,
        endIndent: 16,
        thickness: 0.6,
        color: _divider,
      );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: _textSec),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  )),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: _textSec, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Booking Activity Card ─────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _BookingActivityCard extends StatelessWidget {
  final String bookingId;
  final String astrologerName;
  final String consultationType;
  final String status;
  final String scheduledFor;
  final String amount;
  final String paymentStatus;
  final bool isChat;
  final VoidCallback onAction;

  const _BookingActivityCard({
    required this.bookingId,
    required this.astrologerName,
    required this.consultationType,
    required this.status,
    required this.scheduledFor,
    required this.amount,
    required this.paymentStatus,
    required this.isChat,
    required this.onAction,
  });

  Color get _statusColor {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return const Color(0xFF5B3FD3);
      case 'IN_PROGRESS':
        return Colors.teal.shade600;
      case 'COMPLETED':
        return Colors.green.shade600;
      case 'CANCELLED':
        return Colors.red.shade500;
      case 'PENDING':
        return Colors.orange.shade600;
      default:
        return const Color(0xFF5B3FD3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top ──────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bookingId,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC9A84C),
                            letterSpacing: 0.5)),
                    const SizedBox(height: 10),
                    Text(astrologerName,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F0FF),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        consultationType.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6C4DFF),
                            letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _statusColor.withOpacity(0.3)),
                ),
                child: Text(status,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor,
                        letterSpacing: 0.6)),
              ),
            ],
          ),

          const SizedBox(height: 18),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 18),

          // ── Info tiles ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _InfoTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Scheduled',
                    value: scheduledFor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                    icon: Icons.currency_rupee, label: 'Amount', value: amount),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Action button ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(
                isChat ? Icons.chat_bubble_outline_rounded : Icons.call_rounded,
                size: 18,
              ),
              label: Text(
                isChat ? 'Connect Chat' : 'Connect Call',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C4DFF),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xFF6C4DFF)),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                  height: 1.4)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Empty Sessions Card ───────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _EmptySessionsCard extends StatelessWidget {
  final VoidCallback onExplore;
  const _EmptySessionsCard({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEEF5), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFEEEFFE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today_outlined,
                color: Color(0xFF5C5FD4), size: 30),
          ),
          const SizedBox(height: 18),
          const Text(
            'No Upcoming Sessions',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2A2D4A),
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "You don't have any consultations scheduled yet.\nBook a session with an expert to get started.",
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: Color(0xFF90A4AE), height: 1.55),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Error Banner ──────────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Could not load bookings: $message',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Base Card ─────────────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _BaseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _BaseCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Booking helpers ──────────────────────────────────────────────────────────
bool _isChatConsultation(BookingModel b) =>
    b.consultationType.toLowerCase().contains('chat');

({List<BookingModel> upcoming, List<BookingModel> history})
    _normalizeBookingLists(
  List<BookingModel> backendUpcoming,
  List<BookingModel> backendHistory,
) {
  final seen = <int>{};
  final all = <BookingModel>[];
  for (final booking in [...backendUpcoming, ...backendHistory]) {
    if (seen.add(booking.id)) all.add(booking);
  }

  final upcoming = all.where((booking) => !_isPastBooking(booking)).toList()
    ..sort((a, b) {
      final aDate = _bookingDateTime(a) ?? DateTime(9999);
      final bDate = _bookingDateTime(b) ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });

  final history = all.where(_isPastBooking).toList()
    ..sort((a, b) {
      final aDate = _bookingDateTime(a) ?? DateTime(1900);
      final bDate = _bookingDateTime(b) ?? DateTime(1900);
      return bDate.compareTo(aDate);
    });

  return (upcoming: upcoming, history: history);
}

bool _isPastBooking(BookingModel booking) {
  final status = booking.status.toLowerCase();
  if (status.contains('complete') ||
      status.contains('cancel') ||
      status.contains('closed') ||
      status.contains('expired')) {
    return true;
  }

  final scheduled = _bookingDateTime(booking);
  if (scheduled == null) return false;
  return scheduled
      .isBefore(DateTime.now().subtract(const Duration(minutes: 5)));
}

DateTime? _bookingDateTime(BookingModel booking) {
  DateTime? parsed = _tryParseDateTime(booking.scheduledAt);
  if (parsed != null) return parsed;

  final date = booking.bookingDate.trim();
  final time = booking.bookingTime.trim();
  if (date.isEmpty) return null;
  parsed = _tryParseDateTime('$date $time');
  if (parsed != null) return parsed;
  return _tryParseDateTime(date);
}

DateTime? _tryParseDateTime(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  final normalized = value.contains('T') ? value : value.replaceFirst(' ', 'T');
  try {
    return DateTime.parse(normalized).toLocal();
  } catch (_) {
    final parts = value.split(RegExp(r'\s+'));
    if (parts.isEmpty) return null;
    try {
      final date = DateTime.parse(parts.first);
      if (parts.length == 1) return date;
      final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*([AaPp][Mm])?$')
          .firstMatch(parts.sublist(1).join(' '));
      if (match == null) return date;
      var hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final meridian = match.group(3)?.toLowerCase();
      if (meridian == 'pm' && hour < 12) hour += 12;
      if (meridian == 'am' && hour == 12) hour = 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }
}

String _formatDate(String dateStr) {
  if (dateStr.isEmpty) return '—';
  try {
    final dt = DateTime.parse(dateStr).toLocal();
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
      'Dec',
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m $ampm';
  } catch (_) {
    return dateStr;
  }
}
