// lib/pages/my_orders_page.dart
//
// My Orders screen – uses the shared AppDrawer from app_drawer.dart
// All private _OrdersSideDrawer / _DrawerLabel / _DrawerTile removed.

import 'package:flutter/material.dart';
import '../../core/contants/app_colors.dart';
import '../../core/models/order/order_model.dart'; // ← real model
import '../../core/services/order_service.dart'; // ← real service
import './widgets/app_drawer.dart';
import './profile_screen.dart';
import '../main_navigation.dart'; // UserProfile

// ── Color palette ─────────────────────────────────────────────────────────────
const _navy = Color(0xFF0d437b);
const _gold = Color(0xFFC9A84C);
const _goldLight = Color(0xFFF5E6C0);
const _goldSoft = Color(0xFFFBF3DC);
const _textPrimary = Color(0xFF1A1A2E);
const _textSec = AppColors.subtitleText;

// ═════════════════════════════════════════════════════════════════════════════
// ── MyOrdersPage ──────────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class MyOrdersPage extends StatefulWidget {
  final Widget? bottomNavigationBar;
  const MyOrdersPage({super.key, this.bottomNavigationBar});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with SingleTickerProviderStateMixin, AppDrawerMixin {
  final _orderService = OrderService();

  UserProfile? _user;
  List<OrderModel> _allOrders = [];
  bool _loading = true;
  String? _error;
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];

  // Display-friendly label for filter chips
  String _filterLabel(String f) =>
      f == 'All' ? 'All' : f[0].toUpperCase() + f.substring(1);

  @override
  void initState() {
    super.initState();
    initDrawer();
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
        _orderService.getMyOrders(),
      ]);
      setState(() {
        _user = results[0] as UserProfile;
        _allOrders = results[1] as List<OrderModel>;
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

  String _statusOf(OrderModel order) =>
      order.status.trim().toLowerCase().replaceAll(' ', '_');

  bool _isDelivered(OrderModel order) {
    final status = _statusOf(order);
    return status == 'delivered' || status == 'completed';
  }

  bool _isClosed(OrderModel order) {
    final status = _statusOf(order);
    return _isDelivered(order) ||
        status == 'cancelled' ||
        status == 'canceled' ||
        status == 'refunded';
  }

  bool _isInProgress(OrderModel order) => !_isClosed(order);

  bool _canCancelOrder(OrderModel order) {
    final status = _statusOf(order);
    return status == 'pending' ||
        status == 'processing' ||
        status == 'confirmed';
  }

  List<OrderModel> get _filteredHistory {
    if (_selectedFilter == 'All') return _allOrders;
    return _allOrders.where((order) {
      final status = _statusOf(order);
      if (_selectedFilter == 'delivered') return _isDelivered(order);
      if (_selectedFilter == 'cancelled') {
        return status == 'cancelled' || status == 'canceled';
      }
      if (_selectedFilter == 'processing') {
        return status == 'processing' || status == 'confirmed';
      }
      return status == _selectedFilter.toLowerCase();
    }).toList();
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text('Cancel order ${order.orderNumber}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Cancel',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _orderService.cancelOrder(order.id);
      _loadAll(); // refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
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
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
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
                : _error != null
                    ? _buildError()
                    : RefreshIndicator(
                        color: _gold,
                        onRefresh: _loadAll,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(child: _buildHeader()),
                            SliverPadding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 120),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  _buildStatsRow(),
                                  const SizedBox(height: 20),
                                  _buildSectionTitle(
                                    title: 'Order History',
                                    subtitle:
                                        'All placed orders with live status filters.',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFilterBar(),
                                  const SizedBox(height: 14),
                                  if (_filteredHistory.isEmpty)
                                    _EmptyFilterCard(
                                        filter: _filterLabel(_selectedFilter))
                                  else
                                    ..._filteredHistory.map((o) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 14),
                                          child: _OrderCard(
                                            order: o,
                                            formatDate: _formatDate,
                                            isActive: _isInProgress(o),
                                            canCancel: _canCancelOrder(o),
                                            onTrack: () {},
                                            onCancel: () => _cancelOrder(o),
                                          ),
                                        )),
                                  const SizedBox(height: 24),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
          if (_user != null)
            ...buildDrawerOverlay(
              user: _user!,
              activeRoute: AppDrawerRoute.myOrders,
            ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: _gold),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _textPrimary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _navy, foregroundColor: Colors.white),
            ),
          ],
        ),
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
                child: Icon(Icons.menu, color: Colors.black, size: 30)),
          ),
          const Expanded(
            child: Text('My Orders',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: _navy,
                    letterSpacing: 0.3)),
          ),
          if (_user != null)
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MainNavigation(initialIndex: 3))),
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
                        offset: const Offset(0, 2))
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
              ),
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ── Stats Row ────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final total = _allOrders.length;
    final delivered = _allOrders.where(_isDelivered).length;
    final active = _allOrders.where(_isInProgress).length;

    return Row(children: [
      Expanded(
          child: _StatCard(
        value: total.toString().padLeft(2, '0'),
        label: 'Total Orders',
        sublabel: '$active active',
        icon: Icons.shopping_bag_outlined,
        iconBg: _navy.withOpacity(0.09),
        iconColor: _navy,
        accentColor: _navy,
      )),
      const SizedBox(width: 12),
      Expanded(
          child: _StatCard(
        value: delivered.toString().padLeft(2, '0'),
        label: 'Delivered',
        sublabel: 'completed',
        icon: Icons.check_circle_outline_rounded,
        iconBg: Colors.green.shade50,
        iconColor: Colors.green.shade600,
        accentColor: Colors.green.shade600,
      )),
      const SizedBox(width: 12),
      Expanded(
          child: _StatCard(
        value: active.toString().padLeft(2, '0'),
        label: 'In Progress',
        sublabel: 'on the way',
        icon: Icons.local_shipping_outlined,
        iconBg: Colors.orange.shade50,
        iconColor: Colors.orange.shade600,
        accentColor: Colors.orange.shade600,
      )),
    ]);
  }

  Widget _buildSectionTitle({required String title, required String subtitle}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: _textPrimary)),
      const SizedBox(height: 3),
      Text(subtitle,
          style: TextStyle(fontSize: 12.5, color: _textSec, height: 1.4)),
    ]);
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = _filters[i];
          final isSelected = f == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? _navy : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected ? _navy : const Color(0xFFDDE1F0)),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: _navy.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ]
                    : [],
              ),
              child: Text(_filterLabel(f),
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : _textSec)),
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── Order Card ─────────────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final String Function(String) formatDate;
  final bool isActive;
  final bool canCancel;
  final VoidCallback onTrack;
  final VoidCallback onCancel;

  const _OrderCard({
    required this.order,
    required this.formatDate,
    required this.isActive,
    this.canCancel = false,
    required this.onTrack,
    required this.onCancel,
  });

  Color get _statusColor {
    switch (order.status.toLowerCase()) {
      case 'shipped':
        return const Color(0xFF2563EB);
      case 'processing':
        return Colors.orange.shade600;
      case 'delivered':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.red.shade500;
      default:
        return _navy;
    }
  }

  IconData get _statusIcon {
    switch (order.status.toLowerCase()) {
      case 'shipped':
        return Icons.local_shipping_outlined;
      case 'processing':
        return Icons.hourglass_empty_rounded;
      case 'delivered':
        return Icons.check_circle_outline_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    // First item as the "headline" product, rest shown as "+N more"
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final extraCount = order.items.length - 1;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(children: [
        // Status colour stripe
        Container(
            height: 4,
            decoration: BoxDecoration(
                color: _statusColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)))),

        Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Top row: icon + order info + status badge ──────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: firstItem?.productImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(firstItem!.productImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(_statusIcon,
                                color: _statusColor, size: 24)),
                      )
                    : Icon(_statusIcon, color: _statusColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(order.orderNumber,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _gold,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(
                      firstItem?.productName ?? 'Order',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                          height: 1.3),
                    ),
                    if (extraCount > 0)
                      Text('+$extraCount more item${extraCount > 1 ? 's' : ''}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    if (firstItem?.category != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F0FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(firstItem!.category!,
                            style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6C4DFF))),
                      ),
                    ],
                  ])),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withOpacity(0.25)),
                ),
                child: Text(
                  order.status[0].toUpperCase() + order.status.substring(1),
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: _statusColor),
                ),
              ),
            ]),

            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade100, height: 1),
            const SizedBox(height: 14),

            // ── Info chips ─────────────────────────────────────────────────
            Row(children: [
              Expanded(
                  child: _InfoChip2(
                label: 'ORDER DATE',
                value: formatDate(order.createdAt),
                icon: Icons.calendar_today_outlined,
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: _InfoChip2(
                label: 'AMOUNT',
                value: '₹${order.totalAmount.toStringAsFixed(2)}',
                icon: Icons.currency_rupee,
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: _InfoChip2(
                label: 'PAYMENT',
                value: order.paymentMethod.toUpperCase(),
                icon: Icons.payment_outlined,
              )),
            ]),

            // ── Action buttons ─────────────────────────────────────────────
            const SizedBox(height: 14),
            if (isActive)
              Row(children: [
                if (canCancel) ...[
                  Expanded(
                      child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Cancel',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade500,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  )),
                  const SizedBox(width: 12),
                ],
                Expanded(
                    flex: canCancel ? 2 : 1,
                    child: ElevatedButton.icon(
                      onPressed: onTrack,
                      icon: const Icon(Icons.local_shipping_outlined, size: 16),
                      label: const Text('Track Order',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    )),
              ])
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reorder',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(color: _navy),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          Text(
            sublabel,
            style: TextStyle(
              fontSize: 10,
              color: accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Chip ─────────────────────────────────────────────────────────────────
class _InfoChip2 extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoChip2({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: const Color(0xFF6C4DFF)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Empty States ──────────────────────────────────────────────────────────────
class _EmptyFilterCard extends StatelessWidget {
  final String filter;
  const _EmptyFilterCard({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          filter == 'All' ? 'No orders found.' : 'No $filter orders found.',
          style: TextStyle(
            fontSize: 13,
            color: _textSec,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
