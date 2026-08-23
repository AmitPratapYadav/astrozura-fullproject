// lib/screens/shop/product_details_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/product/product.model.dart';
import '../mainwidgets/header.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/product_wishlist_service.dart';
import '../../core/services/shop_service.dart'; // ← NEW: for fetching related
import './cart_screen.dart';
import './wishlist_screen.dart';
import './widgets/product_chip.dart'; // ← NEW: reuse ProductCard

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  int _selectedTab = 0;

  // ── Related products state ──────────────────────────────────────────────
  final ShopService _shopService = ShopService();
  final ProductWishlistService _wishlist = ProductWishlistService();
  late ProductModel _product;
  List<ProductModel> _relatedProducts = [];
  bool _isLoadingRelated = true;
  bool _isLoadingProduct = false;

  ProductModel get product => _product;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _wishlist.load();
    _fetchProductDetail();
    _fetchRelatedProducts();
  }

  Future<void> _fetchProductDetail() async {
    setState(() => _isLoadingProduct = true);
    try {
      final detailed = await _shopService.getProduct(widget.product.id);
      if (!mounted) return;
      setState(() {
        _product = detailed;
        _isLoadingProduct = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingProduct = false);
    }
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
        related = all.where((p) => p.id != product.id).take(4).toList();
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios),
          ),
          Expanded(
            child: Text(
              'Product Details',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD4AF37),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWishlistButton(),
              ListenableBuilder(
                listenable: CartService(),
                builder: (context, _) {
                  final cart = CartService();
                  return Stack(
                    clipBehavior: Clip.none,
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
            ],
          ),
        ],
      ),
    );
  }

  // ── PRODUCT IMAGE ─────────────────────────────────────────────────────────

  Widget _buildWishlistButton() {
    return ListenableBuilder(
      listenable: _wishlist,
      builder: (context, _) {
        final isSaved = _wishlist.isWishlisted(product.id);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () async {
                try {
                  await _wishlist.toggle(product);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content:
                            Text(e.toString().replaceFirst('Exception: ', '')),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                }
              },
              onLongPress: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProductWishlistScreen()),
              ),
              icon: Icon(
                isSaved
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 25,
                color: isSaved ? const Color(0xFFE1456B) : Colors.black87,
              ),
            ),
            if (_wishlist.count > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 18),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _wishlist.count.toString(),
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
    );
  }

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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                _detailTabs.length,
                (index) => _buildTab(_detailTabs[index], index),
              ),
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
          color: onTap == null ? Colors.grey.shade200 : const Color(0xFFD4AF37),
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

  List<String> get _detailTabs {
    final tabs = <String>['Description'];
    if (_clean(product.benefits).isNotEmpty) tabs.add('Benefits');
    if (_clean(product.specifications).isNotEmpty) tabs.add('Specifications');
    tabs.add('Details');
    if (product.variants.isNotEmpty) tabs.add('Variants');
    if (_clean(product.warningsPrecautions).isNotEmpty) tabs.add('Care');
    if (product.guideBlog != null) tabs.add('Guide Book');
    return tabs;
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.black12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    final tabs = _detailTabs;
    final tab = tabs[_selectedTab.clamp(0, tabs.length - 1)];

    switch (tab) {
      case 'Benefits':
        return _richTextCard(_clean(product.benefits));
      case 'Specifications':
        return _richTextCard(_clean(product.specifications));
      case 'Care':
        return _richTextCard(_clean(product.warningsPrecautions));
      case 'Details':
        return _detailsCard();
      case 'Variants':
        return Column(children: product.variants.map(_variantCard).toList());
      case 'Guide Book':
        return _guideCard();
      case 'Description':
      default:
        final description = _clean(product.description);
        return _richTextCard(
          description.isNotEmpty
              ? description
              : 'No description available for this product.',
        );
    }
  }

  Widget _richTextCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAD9AE)),
      ),
      child: Text(
        text,
        style:
            const TextStyle(height: 1.65, fontSize: 14, color: Colors.black87),
      ),
    );
  }

  Widget _detailsCard() {
    final rows = <MapEntry<String, String>>[
      if (product.category?.isNotEmpty == true)
        MapEntry('Category', product.category!),
      MapEntry(
          'Unit', product.unit?.isNotEmpty == true ? product.unit! : 'Piece'),
      MapEntry('Reviews',
          product.reviews > 0 ? '${product.reviews}' : 'Not rated yet'),
      MapEntry(
          'Rating',
          product.rating > 0
              ? product.rating.toStringAsFixed(1)
              : 'Not rated yet'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAD9AE)),
      ),
      child: Column(children: rows.map(_detailRow).toList()),
    );
  }

  Widget _detailRow(MapEntry<String, String> row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              row.key,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.value,
              style: const TextStyle(
                color: Color(0xFF1E3557),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _variantCard(ProductVariantModel variant) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAD9AE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            variant.title,
            style: const TextStyle(
              color: Color(0xFF1E3557),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniPill('Price', 'Rs.${variant.price.toStringAsFixed(0)}'),
              if (variant.compareAtPrice != null)
                _miniPill(
                    'MRP', 'Rs.${variant.compareAtPrice!.toStringAsFixed(0)}'),
              _miniPill('Stock', '${variant.stockQuantity}'),
              if (variant.sku?.isNotEmpty == true)
                _miniPill('SKU', variant.sku!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAD9AE)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFF1E3557),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _guideCard() {
    final guide = product.guideBlog;
    if (guide == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAD9AE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guide Book',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            guide.title,
            style: const TextStyle(
              color: Color(0xFF1E3557),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          if (_clean(guide.excerpt).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _clean(guide.excerpt),
              style: const TextStyle(
                color: Colors.black87,
                height: 1.55,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _clean(String? value) {
    if (value == null) return '';
    return value
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // RELATED PRODUCTS SECTION ──────────────────────────────────────────────

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
                        content:
                            Text('$_quantity × ${product.name} added to cart'),
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
                  side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
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
