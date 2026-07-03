// lib/pages/my_bookings_page.dart
//
// My Bookings screen – uses the shared AppDrawer from app_drawer.dart
// All private _BookingsSideDrawer / _DrawerLabel / _DrawerTile removed.

import 'package:flutter/material.dart';
import '../../core/contants/app_colors.dart';
import '../../core/services/booking_service.dart';
import '../../core/models/ritual_booking_model.dart';
import '../../core/services/ritual_booking_service.dart';
import './widgets/app_drawer.dart'; // ← shared drawer
import './profile_screen.dart'; // UserProfile
import '../main_navigation.dart'; // MainNavigation

// ── Color palette ─────────────────────────────────────────────────────────────
const _navy = Color(0xFF0d437b);
const _gold = Color(0xFFC9A84C);
const _goldLight = Color(0xFFF5E6C0);
const _goldSoft = Color(0xFFFBF3DC);
const _cardBg = Colors.white;
const _textPrimary = Color(0xFF1A1A2E);
const _textSec = AppColors.subtitleText;

// ═════════════════════════════════════════════════════════════════════════════
// ── MyBookingsPage ────────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class MyBookingsPage extends StatefulWidget {
  final Widget? bottomNavigationBar;
  const MyBookingsPage({super.key, this.bottomNavigationBar});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with SingleTickerProviderStateMixin, AppDrawerMixin {
  UserProfile? _user;
  List<BookingModel> _upcoming = [];
  List<BookingModel> _history = [];
  List<RitualBookingModel> _upcomingRituals = [];
  List<RitualBookingModel> _historyRituals = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    initDrawer(); // ← AppDrawerMixin
    _loadAll();
  }

  @override
  void dispose() {
    drawerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        UserProfile.load(),
        BookingService.getMyBookings(),
        RitualBookingService().getMine(),
      ]);
      final user = results[0] as UserProfile;
      final bookings = results[1] as Map<String, List<BookingModel>>;
      final rituals = results[2] as RitualBookingCollection;
      final allUpcoming = (bookings['upcoming'] ?? []);
      final allHistory = (bookings['history'] ?? []);

      setState(() {
        _user = user;
        _upcoming = allUpcoming;
        _history = allHistory;
        _upcomingRituals = rituals.upcoming;
        _historyRituals = rituals.history;
        _loading = false;
      });
    } catch (e) {
      final user = await UserProfile.load()
          .catchError((_) => const UserProfile(name: 'User', phone: ''));
      setState(() {
        _user = user;
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  bool _isChatConsultation(BookingModel b) =>
      (b.consultationType ?? '').toLowerCase().contains('chat');

  String _formatDate(String dateStr) {
    try {
      // Convert UTC from backend → local timezone
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
        'Dec'
      ];

      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);

      final m = dt.minute.toString().padLeft(2, '0');

      final ampm = dt.hour >= 12 ? 'pm' : 'am';

      return '${dt.day} ${months[dt.month - 1]} '
          '${dt.year}, $h:$m $ampm';
    } catch (_) {
      return dateStr;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      bottomNavigationBar: widget.bottomNavigationBar,
      body: Stack(
        children: [
          // ── Background ────────────────────────────────────────────────────
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
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _gold))
                : RefreshIndicator(
                    color: _gold,
                    onRefresh: _loadAll,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader()),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              if (_error != null) ...[
                                _ErrorBanner(_error!),
                                const SizedBox(height: 12),
                              ],
                              _SectionHeader(
                                label: 'APPOINTMENTS',
                                title: 'My Bookings',
                                icon: Icons.calendar_month_rounded,
                              ),
                              const SizedBox(height: 4),
                              _BookingSection(
                                title: 'Upcoming Consultations',
                                subtitle:
                                    'Your confirmed and scheduled astrologer bookings.',
                                emptyTitle: 'No active bookings',
                                emptySubtitle:
                                    'Book an astrologer to see your upcoming consultations here.',
                                emptyActionLabel: 'Explore Astrologers',
                                onEmptyAction: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const MainNavigation(initialIndex: 1),
                                  ),
                                ),
                                items: _upcoming,
                                isChatFn: _isChatConsultation,
                                formatDate: _formatDate,
                                onOpenChat: (id) => Navigator.pushNamed(
                                  context,
                                  '/chat-session',
                                  arguments: {'bookingId': id},
                                ),
                              ),
                              const SizedBox(height: 20),
                              _RitualBookingSection(
                                title: 'Upcoming Ritual Bookings',
                                subtitle:
                                    'Pooja and anusthan requests submitted for admin confirmation.',
                                emptyTitle: 'No active ritual bookings',
                                emptySubtitle:
                                    'Book a pooja or anusthan to see its scheduling status here.',
                                emptyActionLabel: 'Explore Rituals',
                                onEmptyAction: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const MainNavigation(initialIndex: 7),
                                  ),
                                ),
                                items: _upcomingRituals,
                                formatDate: _formatDate,
                              ),
                              const SizedBox(height: 20),
                              _HistorySection(
                                title: 'Booking History',
                                subtitle:
                                    'Completed and past sessions remain listed for reference.',
                                items: _history,
                                isChatFn: _isChatConsultation,
                                formatDate: _formatDate,
                                onOpenChat: (id) => Navigator.pushNamed(
                                  context,
                                  '/chat-session',
                                  arguments: {'bookingId': id},
                                ),
                              ),
                              const SizedBox(height: 20),
                              _RitualBookingSection(
                                title: 'Ritual Booking History',
                                subtitle:
                                    'Past ritual requests and completed arrangements.',
                                emptyTitle: 'No ritual bookings yet',
                                emptySubtitle:
                                    'Completed and past pooja bookings will appear here.',
                                emptyActionLabel: 'Explore Rituals',
                                onEmptyAction: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const MainNavigation(initialIndex: 7),
                                  ),
                                ),
                                items: _historyRituals,
                                formatDate: _formatDate,
                              ),
                              const SizedBox(height: 24),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // ── Shared drawer overlay ───────────────────────────────────────
          if (_user != null)
            ...buildDrawerOverlay(
              user: _user!,
              activeRoute: AppDrawerRoute.myBookings,
            ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: openDrawer,
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.menu, color: Colors.black, size: 30),
            ),
          ),
          const Expanded(
            child: Text(
              'My Bookings',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _navy,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (_user != null)
            GestureDetector(
                onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MainNavigation(initialIndex: 3),
                      ),
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
                    child: _user!.avatarUrl != null
                        ? Image.network(_user!.avatarUrl!, fit: BoxFit.cover)
                        : Container(
                            color: _navy,
                            alignment: Alignment.center,
                            child: Text(
                              _user!.name.isNotEmpty
                                  ? _user!.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                  ),
                ))
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Section Header ────────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String label;
  final String title;
  final IconData icon;
  const _SectionHeader(
      {required this.label, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _goldSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 12, color: _gold),
                    const SizedBox(width: 5),
                    Text(label,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _gold,
                            letterSpacing: 1.0)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _textPrimary)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Booking Section (Upcoming) ─────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _BookingSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emptyTitle;
  final String emptySubtitle;
  final String emptyActionLabel;
  final VoidCallback onEmptyAction;
  final List<BookingModel> items;
  final bool Function(BookingModel) isChatFn;
  final String Function(String) formatDate;
  final void Function(int) onOpenChat;
  final bool isRitual;

  const _BookingSection({
    required this.title,
    required this.subtitle,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyActionLabel,
    required this.onEmptyAction,
    required this.items,
    required this.isChatFn,
    required this.formatDate,
    required this.onOpenChat,
    this.isRitual = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(fontSize: 12.5, color: _textSec, height: 1.4)),
        const SizedBox(height: 14),
        if (items.isEmpty)
          _EmptyCard(
            title: emptyTitle,
            subtitle: emptySubtitle,
            actionLabel: emptyActionLabel,
            onAction: onEmptyAction,
            isRitual: isRitual,
          )
        else
          ...items.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _BookingCard(
                  bookingId: b.bookingId,
                  astrologerName: b.astrologerName,
                  consultationType: b.consultationType ?? 'Consultation',
                  status: (b.status ?? 'confirmed').toUpperCase(),
                  scheduledFor: formatDate(b.scheduledAt),
                  amount: 'Rs ${b.amount.toStringAsFixed(2)}',
                  paymentStatus: b.paymentStatus ?? 'paid',
                  isChat: isChatFn(b),
                  onAction: () => onOpenChat(b.id),
                  showBirthDetails: false,
                ),
              )),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── History Section ────────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _HistorySection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<BookingModel> items;
  final bool Function(BookingModel) isChatFn;
  final String Function(String) formatDate;
  final void Function(int) onOpenChat;

  const _HistorySection({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.isChatFn,
    required this.formatDate,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(fontSize: 12.5, color: _textSec, height: 1.4)),
        const SizedBox(height: 14),
        ...items.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _BookingCard(
                bookingId: b.bookingId,
                astrologerName: b.astrologerName,
                consultationType: b.consultationType ?? 'Consultation',
                status: (b.status ?? 'confirmed').toUpperCase(),
                scheduledFor: formatDate(b.scheduledAt),
                amount: 'Rs ${b.amount.toStringAsFixed(2)}',
                paymentStatus: b.paymentStatus ?? 'paid',
                isChat: isChatFn(b),
                onAction: () => onOpenChat(b.id),
                showBirthDetails: b.birthDetails != null,
                birthDetails: b.birthDetails,
              ),
            )),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Ritual History Section ─────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _RitualBookingSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emptyTitle;
  final String emptySubtitle;
  final String emptyActionLabel;
  final VoidCallback onEmptyAction;
  final List<RitualBookingModel> items;
  final String Function(String) formatDate;

  const _RitualBookingSection({
    required this.title,
    required this.subtitle,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyActionLabel,
    required this.onEmptyAction,
    required this.items,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: _textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12.5, color: _textSec, height: 1.4),
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          _EmptyCard(
            title: emptyTitle,
            subtitle: emptySubtitle,
            actionLabel: emptyActionLabel,
            onAction: onEmptyAction,
            isRitual: true,
          )
        else
          ...items.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _BookingCard(
                  bookingId: b.reference,
                  astrologerName: b.ritualName,
                  consultationType: 'Pooja Anusthan',
                  status: b.status.toUpperCase(),
                  scheduledFor: [
                    formatDate(b.scheduledDate),
                    b.scheduledTime,
                  ].where((part) => part.trim().isNotEmpty).join(' at '),
                  amount: 'Rs ${b.amount.toStringAsFixed(2)}',
                  paymentStatus: b.paymentStatus,
                  isChat: false,
                  onAction: () {},
                  showBirthDetails: false,
                ),
              )),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Booking Card ───────────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _BookingCard extends StatelessWidget {
  final String bookingId;
  final String astrologerName;
  final String consultationType;
  final String status;
  final String scheduledFor;
  final String amount;
  final String paymentStatus;
  final bool isChat;
  final VoidCallback onAction;
  final bool showBirthDetails;
  final Map<String, dynamic>? birthDetails;

  const _BookingCard({
    required this.bookingId,
    required this.astrologerName,
    required this.consultationType,
    required this.status,
    required this.scheduledFor,
    required this.amount,
    required this.paymentStatus,
    required this.isChat,
    required this.onAction,
    this.showBirthDetails = false,
    this.birthDetails,
  });

  Color get _statusColor {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return const Color(0xFF5B3FD3);
      case 'COMPLETED':
        return Colors.green.shade600;
      case 'CANCELLED':
        return Colors.red.shade500;
      case 'PENDING':
        return Colors.orange.shade600;
      case 'IN_PROGRESS':
      case 'IN PROGRESS':
        return Colors.blue.shade600;
      default:
        return const Color(0xFF5B3FD3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bookingId,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _gold,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      Text(astrologerName,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F0FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(consultationType,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6C4DFF))),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor.withOpacity(0.25)),
                  ),
                  child: Text(
                    status.replaceAll('_', ' '),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor,
                        letterSpacing: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade100, height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _InfoChip(
                    label: 'SCHEDULED FOR',
                    value: scheduledFor,
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoChip(
                    label: 'AMOUNT',
                    value: amount,
                    icon: Icons.currency_rupee,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoChip(
                    label: 'PAYMENT',
                    value: paymentStatus,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
              ],
            ),
            if (showBirthDetails && birthDetails != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _goldSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 13, color: _gold),
                        const SizedBox(width: 5),
                        const Text(
                          'BIRTH DETAILS SHARED',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _gold,
                              letterSpacing: 0.8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (birthDetails!['dob'] != null)
                      _BirthDetailRow(
                          label: 'DOB', value: birthDetails!['dob']),
                    if (birthDetails!['time'] != null)
                      _BirthDetailRow(
                          label: 'Time', value: birthDetails!['time']),
                    if (birthDetails!['gender'] != null)
                      _BirthDetailRow(
                          label: 'Gender', value: birthDetails!['gender']),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(
                  isChat
                      ? Icons.chat_bubble_outline_rounded
                      : Icons.videocam_outlined,
                  size: 17,
                ),
                label: Text(
                  isChat ? 'Open Chat Session' : 'Join Video Session',
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BirthDetailRow extends StatelessWidget {
  final String label;
  final dynamic value;
  const _BirthDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: _textSec),
            ),
            TextSpan(
              text: value.toString(),
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info Chip ─────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoChip(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: const Color(0xFF6C4DFF)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                  height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Empty Card ────────────────────────────────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isRitual;

  const _EmptyCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.isRitual = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECEEF5), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isRitual ? _goldSoft : const Color(0xFFEEEFFE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRitual
                  ? Icons.auto_awesome_rounded
                  : Icons.calendar_today_outlined,
              color: isRitual ? _gold : const Color(0xFF5C5FD4),
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: _textSec, height: 1.5)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              elevation: 0,
            ),
            child: Text(actionLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}

// ─── Error Banner ──────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

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
        ],
      ),
    );
  }
}
