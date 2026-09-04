// lib/features/profile/widgets/app_drawer.dart

import 'dart:async';

import 'package:flutter/material.dart';
import '../profile_screen.dart';
import '../edit_profile_page.dart';
import '../../main_navigation.dart';
import '../../web/in_app_web_page.dart';
import '../../../core/contants/app_colors.dart';
import '../../../core/services/auth_services.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _navy = Color(0xFF0d437b);
const _gold = Color(0xFFC9A84C);
const _textPrimary = Color(0xFF1A1A2E);
const _textSec = AppColors.subtitleText;

// ── Active route enum ─────────────────────────────────────────────────────────
enum AppDrawerRoute { profile, editProfile, myBookings, myOrders, settings }

mixin AppDrawerMixin<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late final AnimationController drawerCtrl;
  late final Animation<Offset> drawerSlide;
  late final Animation<double> scrimOpacity;
  bool drawerOpen = false;

  void initDrawer() {
    drawerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    drawerSlide = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: drawerCtrl, curve: Curves.easeOutCubic));

    scrimOpacity = Tween<double>(begin: 0.0, end: 0.50)
        .animate(CurvedAnimation(parent: drawerCtrl, curve: Curves.easeOut));
  }

  void openDrawer() {
    setState(() => drawerOpen = true);
    drawerCtrl.forward();
  }

  void closeDrawer() {
    drawerCtrl.reverse().then((_) {
      if (mounted) setState(() => drawerOpen = false);
    });
  }

  /// Returns the scrim + sliding panel to be spread inside a Stack.
  List<Widget> buildDrawerOverlay({
    required UserProfile user,
    required AppDrawerRoute activeRoute,
  }) {
    if (!drawerOpen) return [];
    return [
      // Scrim
      AnimatedBuilder(
        animation: scrimOpacity,
        builder: (_, __) => GestureDetector(
          onTap: closeDrawer,
          behavior: HitTestBehavior.opaque,
          child: Container(color: Colors.black.withOpacity(scrimOpacity.value)),
        ),
      ),
      // Drawer panel
      Positioned.fill(
        child: Align(
          alignment: Alignment.centerLeft,
          child: SlideTransition(
            position: drawerSlide,
            child: Material(
              color: Colors.transparent,
              child: AppDrawer(
                user: user,
                activeRoute: activeRoute,
                onClose: closeDrawer,
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

class AppDrawer extends StatelessWidget {
  final UserProfile user;
  final AppDrawerRoute activeRoute;
  final VoidCallback onClose;

  const AppDrawer({
    super.key,
    required this.user,
    required this.activeRoute,
    required this.onClose,
  });

  /// Push a completely new route (for pages outside the IndexedStack).
  void _pushPage(BuildContext context, Widget page) {
    onClose();
    Future.delayed(const Duration(milliseconds: 220), () {
      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      }
    });
  }

  void _switchTab(BuildContext context, int tabIndex) {
    onClose();
    Future.delayed(const Duration(milliseconds: 220), () {
      // 1️⃣ Static instance — most reliable, always set while app is running
      final instance = MainNavigationState.instance;
      if (instance != null) {
        instance.switchTab(tabIndex);
        return;
      }

      // 2️⃣ GlobalKey
      final keyState = MainNavigation.navigatorKey.currentState;
      if (keyState != null) {
        keyState.switchTab(tabIndex);
        return;
      }

      if (!context.mounted) return;

      // 3️⃣ Walk full ancestor tree (works from pushed routes)
      final treeState =
          context.findRootAncestorStateOfType<MainNavigationState>();
      if (treeState != null) {
        treeState.switchTab(tabIndex);
        return;
      }

      // 4️⃣ Pop back to root then switch
      Navigator.of(context).popUntil((route) => route.isFirst);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        MainNavigationState.instance?.switchTab(tabIndex);
      });
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  Future<void> _openWeb(
    BuildContext context, {
    required String title,
    required String path,
  }) async {
    onClose();
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!context.mounted) return;
      InAppWebPage.open(context, title: title, pathOrUrl: path);
    });
  }

  Future<void> _logout(BuildContext context) async {
    final token = await AuthService.getToken();
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    if (token != null && token.isNotEmpty) {
      unawaited(AuthService().revokeToken(token));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Container(
      width: sw * 0.84,
      height: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 40,
            offset: Offset(8, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DrawerLabel('MAIN MENU'),

                  // Dashboard → ProfileScreen tab (index 3)
                  // My Profile → EditProfilePage (pushed, not in IndexedStack)
                  _DrawerTile(
                    icon: Icons.person_outline_rounded,
                    label: 'My Profile',
                    isActive: activeRoute == AppDrawerRoute.editProfile,
                    onTap: () => _pushPage(context, const EditProfilePage()),
                  ),

                  // My Bookings → IndexedStack index 5
                  _DrawerTile(
                    icon: Icons.calendar_month_rounded,
                    label: 'My Bookings',
                    isActive: activeRoute == AppDrawerRoute.myBookings,
                    onTap: () => _switchTab(context, 6),
                  ),

                  // My Orders → IndexedStack index 4
                  _DrawerTile(
                    icon: Icons.shopping_bag_outlined,
                    label: 'My Orders',
                    isActive: activeRoute == AppDrawerRoute.myOrders,
                    onTap: () => _switchTab(context, 5),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Divider(thickness: 0.8, color: Colors.grey.shade100),
                  ),
                  const _DrawerLabel('SUPPORT'),
                  _DrawerTile(
                    icon: Icons.info_outline_rounded,
                    label: 'About Us',
                    onTap: () => _openWeb(
                      context,
                      title: 'About Us',
                      path: '/about-us',
                    ),
                  ),
                  _DrawerTile(
                    icon: Icons.support_agent_rounded,
                    label: 'Contact Support',
                    onTap: () => _openWeb(
                      context,
                      title: 'Contact Support',
                      path: '/contact-support',
                    ),
                  ),
                  _DrawerTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () => _openWeb(
                      context,
                      title: 'Privacy Policy',
                      path: '/privacy-policy',
                    ),
                  ),
                  _DrawerTile(
                    icon: Icons.description_outlined,
                    label: 'Terms & Conditions',
                    onTap: () => _openWeb(
                      context,
                      title: 'Terms & Conditions',
                      path: '/terms-and-conditions',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5C5FD4), Color(0xFF6C6FD8), Color(0xFF7B7EE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(topRight: Radius.circular(28)),
      ),
      child: Row(
        children: [
          // Avatar with gold ring
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _gold.withOpacity(0.75), width: 2),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF90A4AE),
              backgroundImage:
                  user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 13),

          // Name / phone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  user.phone,
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // Close button
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.exit_to_app, size: 16),
              label: const Text(
                'Logout',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    letterSpacing: 0.2),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 13),
          GestureDetector(
            onTap: () => _openWeb(
              context,
              title: 'Contact Support',
              path: '/contact-support',
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.help_outline_rounded, size: 15, color: _textSec),
                SizedBox(width: 5),
                Text(
                  'Help & Support',
                  style: TextStyle(
                      color: _textSec,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'v2.4.0 · Astrozura Cosmic Tech',
            style: TextStyle(color: Color(0xFFC5CFD6), fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _DrawerLabel extends StatelessWidget {
  final String label;
  const _DrawerLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w700,
          color: _textSec,
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF7F1E1) : const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: isActive ? _gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      isActive ? _navy.withOpacity(0.08) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: isActive ? _gold : const Color(0xFF9A8D72),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? _textPrimary : _textSec,
                  ),
                ),
              ),
              if (isActive)
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: _textSec),
            ],
          ),
        ),
      ),
    );
  }
}
