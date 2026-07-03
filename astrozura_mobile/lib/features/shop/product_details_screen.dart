// lib/screens/shop/product_details_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/product/product.model.dart';
import '../mainwidgets/header.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/shop_service.dart';        // ← NEW: for fetching related
import './cart_screen.dart';
import './widgets/product_chip.dart';             // ← NEW: reuse ProductCard

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  int _selectedTab = 0; // 0 = Description, 1 = Benefits

  // ── Related products state ──────────────────────────────────────────────
  final ShopService _shopService = ShopService();
  List<ProductModel> _relatedProducts = [];
  bool _isLoadingRelated = true;

  ProductModel get product => widget.product;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchRelatedProducts();
  }

  /// Fetches up to 4 products in the same category, excluding the current one.
  /// If fewer than 1 same-category product is found, falls back to any products
  /// across all categories (still excluding the current product).
  Future<void> _fetchRelatedProducts() async {
    try {
      final all = await _shopService.getAllProducts();

      // 1️⃣ Try same-category first
      List<ProductModel> related = all
          .where((p) =>
              p.id != product.id &&
              p.category != null &&
              p.category == product.category)
          .take(4)
          .toList();

      // 2️⃣ Fallback: not enough same-category → pull from all products
      if (related.isEmpty) {
        related = all
            .where((p) => p.id != product.id)
            .take(4)
            .toList();
      }

      if (mounted) {
        setState(() {
          _relatedProducts = related;
          _isLoadingRelated = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRelated = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── APP HEADER ─────────────────────────────────────────────
            const HeaderWidget(),

            // ── PAGE TITLE + BACK ──────────────────────────────────────
            _buildTitleRow(),

            const SizedBox(height: 10),

            // ── SCROLLABLE BODY ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductImage(),
                    _buildDetails(),

                    // ── RELATED PRODUCTS ─────────────────────────────
                    _buildRelatedProducts(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── FIXED BOTTOM BUTTONS ───────────────────────────────────
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  // ── TITLE ROW ────────────────────────────────────────────────────────────

  Widget _buildTitleRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios),
            ),
          ),
          Text(
            'Product Details',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFD4AF37),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ListenableBuilder(
              listenable: CartService(),
              builder: (context, _) {
                final cart = CartService();
                return Stack(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      ),
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        size: 26,
                        color: Colors.black87,
                      ),
                    ),
                    if (cart.totalItems > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          constraints: const BoxConstraints(minWidth: 18),
                          decoration: const BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            cart.totalItems.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── PRODUCT IMAGE ─────────────────────────────────────────────────────────

  Widget _buildProductImage() {
    final imageUrl = product.images[0];

    return Container(
      height: 260,
      width: double.infinity,
      color: Colors.grey.shade100,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 64,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  // ── DETAILS SECTION ───────────────────────────────────────────────────────

  Widget _buildDetails() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── NAME ────────────────────────────────────────────────────
          Text(
            product.name,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          // ── CATEGORY BADGE ───────────────────────────────────────────
          if (product.category != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0E8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                product.category!,
                style: const TextStyle(
                  color: Color(0xFF8B6914),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // ── RATING ──────────────────────────────────────────────────
          Row(
            children: [
              ...List.generate(
                  5,
                  (i) => Icon(
                        i < product.rating.floor()
                            ? Icons.star
                            : Icons.star_border,
                        size: 16,
                        color: i < product.rating.floor()
                            ? Colors.orange
                            : Colors.grey.shade300,
                      )),
              const SizedBox(width: 6),
              Text(
                '${product.rating} (${product.reviews} reviews)',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── PRICE ────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${product.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37),
                ),
              ),
              if (product.oldPrice != null) ...[
                const SizedBox(width: 10),
                Text(
                  '₹${product.oldPrice!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${(((product.oldPrice! - product.price) / product.oldPrice!) * 100).toStringAsFixed(0)}% OFF',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // ── QUANTITY SELECTOR ────────────────────────────────────────
          Row(
            children: [
              Text(
                'Quantity',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              _buildQuantityButton(
                icon: Icons.remove,
                onTap:
                    _quantity > 1 ? () => setState(() => _quantity--) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onTap: () => setState(() => _quantity++),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── TABS ─────────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                _buildTab('Description', 0),
                _buildTab('Benefits', 1),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── TAB CONTENT ───────────────────────────────────────────────
          _buildTabContent(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.grey.shade200
              : const Color(0xFFD4AF37),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? Colors.grey : Colors.black,
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: isSelected ? const Color(0xFFD4AF37) : Colors.grey.shade200,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.black : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedTab == 0) {
      // ── Dynamic description from database ──────────────────────────
      return Text(
        product.description?.isNotEmpty == true
            ? product.description!
            : 'No description available for this product.',
        style: const TextStyle(
          height: 1.7,
          fontSize: 14,
          color: Colors.black87,
        ),
      );
    } else {
      return const Text(
        '• Enhances spiritual energy and focus\n'
        '• Crafted with authentic materials\n'
        '• Ideal for meditation and rituals\n'
        '• Promotes positive vibrations in your space',
        style: TextStyle(height: 1.8, fontSize: 14, color: Colors.black87),
      );
    }
  }

  // ── RELATED PRODUCTS SECTION ──────────────────────────────────────────────

  Widget _buildRelatedProducts() {
    // Don't render the section at all if there are no related products
    // and we're done loading.
    if (!_isLoadingRelated && _relatedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Divider ──────────────────────────────────────────────────
        const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),

        const SizedBox(height: 20),

        // ── Section header ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Related Products',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E3A5F),
                ),
              ),
              if (product.category != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0E8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    product.category!,
                    style: const TextStyle(
                      color: Color(0xFF8B6914),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Horizontal list ───────────────────────────────────────────
        SizedBox(
          height: 260, // matches ProductCard's approximate rendered height
          child: _isLoadingRelated
              ? _buildRelatedShimmer()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _relatedProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 160, // fixed card width in horizontal scroll
                      child: ProductCard(product: _relatedProducts[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Skeleton loader — 4 placeholder cards while data loads.
  Widget _buildRelatedShimmer() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, __) => _ShimmerCard(),
    );
  }

  // ── BOTTOM BUTTONS ────────────────────────────────────────────────────────

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // ── ADD TO CART ───────────────────────────────────────────
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  CartService().addToCart(product, quantity: _quantity);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                            '$_quantity × ${product.name} added to cart'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: const Color(0xFF2E2A63),
                      ),
                    );
                },
                icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                label: const Text(
                  'Add to Cart',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: const Color(0xFF1E3A5F),
                  side: const BorderSide(
                      color: Color(0xFFD4AF37), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ── BUY NOW ───────────────────────────────────────────────
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  CartService().addToCart(product, quantity: _quantity);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
                icon: const Icon(Icons.bolt, size: 18),
                label: const Text('Buy Now'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer placeholder card ──────────────────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(
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
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Title placeholder
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  height: 12,
                  width: 110,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  height: 10,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
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