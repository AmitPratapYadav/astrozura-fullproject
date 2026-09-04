import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/cart_service.dart';
import '../../../core/services/product_wishlist_service.dart';
import '../cart_screen.dart';
import '../wishlist_screen.dart';

class ShopHeader extends StatefulWidget {
  final bool compact;

  const ShopHeader({super.key, this.compact = false});

  @override
  State<ShopHeader> createState() => _ShopHeaderState();
}

class _ShopHeaderState extends State<ShopHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _actionsOffset;
  late final Animation<double> _actionsOpacity;

  final CartService _cart = CartService();
  final ProductWishlistService _wishlist = ProductWishlistService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _actionsOffset = Tween<Offset>(
      begin: const Offset(0, 0.55),
      end: Offset.zero,
    ).animate(curve);
    _actionsOpacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _wishlist.load();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verticalPadding = widget.compact ? 8.0 : 12.0;
    final logoSize = widget.compact ? 48.0 : 56.0;
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.fromLTRB(
        16,
        topInset + verticalPadding,
        16,
        verticalPadding + 2,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF101726), Color(0xFF1E3557)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101726).withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: logoSize,
            width: logoSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.4),
              image: const DecorationImage(
                image: AssetImage('assets/images/logo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Astro Shop',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: widget.compact ? 19 : 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cosmic essentials marketplace',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: widget.compact ? 10.5 : 11.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
          FadeTransition(
            opacity: _actionsOpacity,
            child: SlideTransition(
              position: _actionsOffset,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AnimatedShopAction(
                    listenable: _wishlist,
                    icon: Icons.favorite_border_rounded,
                    activeIcon: Icons.favorite_rounded,
                    countBuilder: () => _wishlist.count,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductWishlistScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AnimatedShopAction(
                    listenable: _cart,
                    icon: Icons.shopping_cart_outlined,
                    countBuilder: () => _cart.totalItems,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedShopAction extends StatelessWidget {
  final ChangeNotifier listenable;
  final IconData icon;
  final IconData? activeIcon;
  final int Function() countBuilder;
  final VoidCallback onTap;

  const _AnimatedShopAction({
    required this.listenable,
    required this.icon,
    this.activeIcon,
    required this.countBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final count = countBuilder();
        final active = count > 0;
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.96, end: active ? 1 : 0.98),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.12),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: SizedBox(
                    height: 39,
                    width: 39,
                    child: Icon(
                      active ? (activeIcon ?? icon) : icon,
                      color: active && activeIcon != null
                          ? const Color(0xFFFFD166)
                          : Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                top: -4,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: active
                      ? Container(
                          key: ValueKey<int>(count),
                          constraints: const BoxConstraints(minWidth: 18),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: const Color(0xFF101726),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF101726),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey<String>('empty')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
