import 'package:flutter/material.dart';
import '../../core/contants/app_colors.dart';
import '../main_navigation.dart';
import 'package:provider/provider.dart';

import '../../core/providers/profile_provider.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        // ✅ FIX: Column instead of Row
        mainAxisSize: MainAxisSize.min,
        children: [
          /// 🔹 TOP CONTENT
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// LEFT SECTION
              Row(
                children: [
                  /// LOGO
                  Container(
                    height: 55,
                    width: 55,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage("assets/images/logo.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  /// TEXT
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "AstroZura",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      Text(
                        "Your cosmic compass to destiny",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.subtitleText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              /// RIGHT SECTION
              Row(
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () => _showNotifications(context),
                    icon: const Icon(Icons.notifications_none, size: 26),
                  ),

                  const SizedBox(width: 4),

                  /// PROFILE
                  Consumer<ProfileProvider>(
                    builder: (context, profile, _) => InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () {
                        final navigation = MainNavigationState.instance;
                        if (navigation != null) {
                          navigation.switchTab(4);
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

          /// 🔥 FULL WIDTH DIVIDER (VISIBLE NOW)
          Divider(
            color: Colors.grey.shade400,
            thickness: 0.5,
            height: 1,
          ),
        ],
      ),
    );
  }

  static Future<void> _showNotifications(BuildContext context) {
    return showGeneralDialog<void>(
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
              child: Container(
                width: MediaQuery.sizeOf(dialogContext)
                    .width
                    .clamp(280, 360)
                    .toDouble(),
                margin: const EdgeInsets.only(top: 72, right: 14, left: 14),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 18),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F0FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_off_outlined,
                        color: Color(0xFF8B88E6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No new notifications yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3557),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Updates about bookings and orders will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.subtitleText,
                      ),
                    ),
                  ],
                ),
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
  }
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
