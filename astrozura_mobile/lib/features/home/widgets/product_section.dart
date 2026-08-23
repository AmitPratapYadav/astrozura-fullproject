// lib/screens/home/widgets/products_section.dart
//
// Fetches products from the same ShopService used by ShopScreen.
// Shows a horizontal scrollable list of ProductCards.
// Handles loading, error, and empty states.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/contants/app_colors.dart';
import '../../../core/models/product/product.model.dart';
import '../../../core/services/shop_service.dart';
import '../../main_navigation.dart';
import './product_card.dart';

class ProductsSection extends StatefulWidget {
  const ProductsSection({super.key});

  @override
  State<ProductsSection> createState() => _ProductsSectionState();
}

class _ProductsSectionState extends State<ProductsSection> {
  final ShopService _shopService = ShopService();

  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = _products.isEmpty;
      _error = null;
    });
    try {
      final products = await _shopService.getAllProducts();
      if (!mounted) return;
      setState(() {
        // Show first 10 on home screen — user can tap "View All" for more
        _products = products.take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title row ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended For You',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (MainNavigationState.activateIndex(3)) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainNavigation(initialIndex: 3),
                    ),
                  );
                },
                child: Row(
                  children: const [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.black54),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Content area ─────────────────────────────────────────────
        SizedBox(
          height: 226,
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    // ── Loading ──
    if (_isLoading) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: 4,
        itemBuilder: (_, __) => _buildSkeletonCard(),
      );
    }

    // ── Error ──
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 36, color: Colors.black26),
            const SizedBox(height: 8),
            const Text(
              'Could not load products',
              style: TextStyle(color: Colors.black45, fontSize: 13),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _fetchProducts,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Empty ──
    if (_products.isEmpty) {
      return const Center(
        child: Text(
          'No products available.',
          style: TextStyle(color: Colors.black45, fontSize: 13),
        ),
      );
    }

    // ── Products list ──
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ProductCard(product: _products[index]),
        );
      },
    );
  }

  // ── Skeleton loading card ─────────────────────────────────────────────────
  Widget _buildSkeletonCard() {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 155,
            decoration: const BoxDecoration(
              color: Color(0xFFEEEEEE),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
          ),
          // Text placeholder
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2E2A72),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
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
