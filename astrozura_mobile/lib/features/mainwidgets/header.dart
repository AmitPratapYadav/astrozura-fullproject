import 'package:flutter/material.dart';
import '../../core/contants/app_colors.dart';
import '../../core/models/user_notification_model.dart';
import '../../core/services/user_notification_service.dart';
import '../main_navigation.dart';
import 'package:provider/provider.dart';

import '../../core/providers/profile_provider.dart';
import '../live/native_live_session_screen.dart';
import '../web/in_app_web_page.dart';
import 'package:google_fonts/google_fonts.dart';

class HeaderWidget extends StatefulWidget {
  const HeaderWidget({super.key});

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  final UserNotificationService _notificationService =
      UserNotificationService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final result = await _notificationService.getNotifications(perPage: 1);
      if (!mounted) return;
      setState(() => _unreadCount = result.unreadCount);
    } catch (_) {
      // Header should stay quiet if the user is not logged in or offline.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      height: 72,
                      width: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage("assets/images/logo.png"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "AstroZura",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Your cosmic compass to destiny",
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.subtitleText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () => _showNotifications(context),
                    icon: _NotificationBell(unreadCount: _unreadCount),
                  ),
                  const SizedBox(width: 4),
                  Consumer<ProfileProvider>(
                    builder: (context, profile, _) => InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () {
                        final navigation = MainNavigationState.instance;
                        if (navigation != null) {
                          navigation.switchTab(4);
                          final navigator = Navigator.of(context);
                          if (navigator.canPop()) {
                            navigator.popUntil((route) => route.isFirst);
                          }
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const MainNavigation(initialIndex: 4),
                            ),
                          );
                        }
                      },
                      child: Container(
                        height: 38,
                        width: 38,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: profile.avatarUrl != null
                            ? Image.network(
                                profile.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _ProfileFallback(name: profile.name),
                              )
                            : _ProfileFallback(name: profile.name),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            color: Colors.grey.shade400,
            thickness: 0.5,
            height: 1,
          ),
        ],
      ),
    );
  }

  Future<void> _showNotifications(BuildContext context) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close notifications',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, _, __) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Material(
              color: Colors.transparent,
              child: _NotificationsPanel(
                service: _notificationService,
                onUnreadChanged: (count) {
                  if (!mounted) return;
                  setState(() => _unreadCount = count);
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
    await _loadUnreadCount();
  }
}

class _NotificationBell extends StatelessWidget {
  final int unreadCount;

  const _NotificationBell({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_none, size: 27),
        if (unreadCount > 0)
          Positioned(
            right: -5,
            top: -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE14343),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.4),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationsPanel extends StatefulWidget {
  final UserNotificationService service;
  final ValueChanged<int> onUnreadChanged;

  const _NotificationsPanel({
    required this.service,
    required this.onUnreadChanged,
  });

  @override
  State<_NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<_NotificationsPanel> {
  List<UserNotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _loading = true;
  bool _markingAll = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.service.getNotifications(perPage: 50);
      if (!mounted) return;
      setState(() {
        _notifications = result.items;
        _unreadCount = result.unreadCount;
        _loading = false;
      });
      widget.onUnreadChanged(result.unreadCount);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAll || _unreadCount == 0) return;
    setState(() => _markingAll = true);
    try {
      await widget.service.markAllRead();
      await _load();
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _openNotification(UserNotificationModel notification) async {
    if (notification.isUnread) {
      await widget.service.markRead(notification.id);
      final nextUnread = (_unreadCount - 1).clamp(0, 9999);
      widget.onUnreadChanged(nextUnread);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    _NotificationRouter.open(context, notification);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width.clamp(292, 390).toDouble(),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      margin: const EdgeInsets.only(top: 74, right: 12, left: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
            child: Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7ECD0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primaryBlue,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      Text(
                        '$_unreadCount unread',
                        style: const TextStyle(
                          color: AppColors.subtitleText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed:
                      _unreadCount == 0 || _markingAll ? null : _markAllRead,
                  icon: _markingAll
                      ? const SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text('Read all'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFD7AF4B)),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFFD7AF4B)),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.subtitleText,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              color: Color(0xFF8B88E6),
              size: 42,
            ),
            SizedBox(height: 12),
            Text(
              'No notifications yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Updates about bookings, rituals and orders will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.subtitleText,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _NotificationTile(
          notification: notification,
          onTap: () => _openNotification(notification),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final UserNotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPayment = notification.type == 'ritual_payment_request' &&
        _asDouble(notification.data['amount']) > 0;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isUnread ? const Color(0xFFFFF8E8) : Colors.white,
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: notification.isUnread
                    ? const Color(0xFFE7C76C)
                    : const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconForType(notification.type),
                size: 19,
                color: notification.isUnread
                    ? AppColors.primaryBlue
                    : AppColors.subtitleText,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (notification.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8, top: 5),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE14343),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (notification.message.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      notification.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _formatNotificationDate(notification.createdAt),
                        style: const TextStyle(
                          color: Color(0xFF98A2B3),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isPayment)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD7AF4B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Pay Rs ${_asDouble(notification.data['amount']).toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF98A2B3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationRouter {
  static void open(BuildContext context, UserNotificationModel notification) {
    final bookingId = _asInt(notification.data['booking_id']);
    final action = (notification.actionUrl ?? '').trim();
    final type = notification.type.toLowerCase();

    if (action.startsWith('/session/') || action.startsWith('/chat')) {
      final idFromPath = _lastIntSegment(action);
      final id = bookingId > 0 ? bookingId : idFromPath;
      if (id > 0) {
        Navigator.pushNamed(context, '/chat-session', arguments: {
          'bookingId': id,
        });
        return;
      }
    }

    final lower = action.toLowerCase();
    if (lower.contains('/live') ||
        lower.contains('live-session') ||
        type.contains('live')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const NativeLiveSessionScreen(),
        ),
      );
      return;
    }
    if (lower.contains('my-bookings') ||
        lower.contains('booking') ||
        type.contains('booking') ||
        type.contains('ritual')) {
      _switchOrPush(context, 6);
      return;
    }
    if (lower.contains('orders') || type.contains('order')) {
      _switchOrPush(context, 5);
      return;
    }
    if (lower.contains('profile') || lower.contains('dashboard')) {
      _switchOrPush(context, 4);
      return;
    }
    if (lower.contains('astrologer')) {
      _switchOrPush(context, 1);
      return;
    }
    if (lower.contains('ritual')) {
      _switchOrPush(context, 7);
      return;
    }
    if (lower.contains('shop') || lower.contains('product')) {
      _switchOrPush(context, 3);
      return;
    }
    if (lower.contains('panchang')) {
      _switchOrPush(context, 8);
      return;
    }
    if (lower.contains('rashifal') || lower.contains('horoscope')) {
      _switchOrPush(context, 11);
      return;
    }
    if (lower.contains('detailed-kundali')) {
      _switchOrPush(context, 30);
      return;
    }
    if (lower.contains('detailed-matchmaking') || lower.contains('matching')) {
      _switchOrPush(context, 32);
      return;
    }
    if (lower.contains('blog')) {
      InAppWebPage.open(context, title: 'Blogs', pathOrUrl: action);
      return;
    }

    if (action.isNotEmpty) {
      InAppWebPage.open(context, title: notification.title, pathOrUrl: action);
      return;
    }

    _switchOrPush(context, 4);
  }

  static void _switchOrPush(BuildContext context, int index) {
    if (MainNavigationState.activateIndex(index)) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MainNavigation(initialIndex: index)),
    );
  }

  static int _lastIntSegment(String path) {
    for (final segment in path.split('/').reversed) {
      final value = int.tryParse(segment);
      if (value != null) return value;
    }
    return 0;
  }
}

IconData _iconForType(String type) {
  final lower = type.toLowerCase();
  if (lower.contains('payment')) return Icons.payments_outlined;
  if (lower.contains('ritual')) return Icons.auto_awesome_outlined;
  if (lower.contains('booking')) return Icons.calendar_month_outlined;
  if (lower.contains('order')) return Icons.shopping_bag_outlined;
  if (lower.contains('profile')) return Icons.person_outline_rounded;
  if (lower.contains('offer')) return Icons.local_offer_outlined;
  return Icons.notifications_outlined;
}

String _formatNotificationDate(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  if (diff.inDays < 7) {
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
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
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class _ProfileFallback extends StatelessWidget {
  final String name;

  const _ProfileFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
