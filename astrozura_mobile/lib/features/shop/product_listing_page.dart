// lib/screens/shop/product_listing_page.dart
//
// Full product listing page for a selected category.
// Matches the gold/white/deep-blue astro aesthetic of the rest of the app.
// Supports sort, search, trending/new filters, and pull-to-refresh via API.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/cart_service.dart';
import '../../core/contants/app_colors.dart';
import '../../core/models/product/product.model.dart';
import '../../core/services/product_wishlist_service.dart';
import '../../core/services/shop_service.dart';
import 'widgets/product_chip.dart';
import './cart_screen.dart';
import './wishlist_screen.dart';

class ProductListingPage extends StatefulWidget {
  final String categoryName;

  /// Pass pre-loaded products to avoid an extra API call,
  /// or leave null to let this page fetch them independently.
  final List<ProductModel>? allProducts;

  const ProductListingPage({
    super.key,
    required this.categoryName,
    this.allProducts,
  });

  @override
  State<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  // ── Service ──────────────────────────────────────────────────────────────
  final ShopService _shopService = ShopService();
  final ProductWishlistService _wishlist = ProductWishlistService();

  // ── Data ─────────────────────────────────────────────────────────────────
  List<ProductModel> _allProducts = [];

  // ── UI State ─────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  String _selectedSort = 'Recommended';
  String _selectedBadge = 'All'; // All | Trending | New Arrival

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _wishlist.load();
    if (widget.allProducts != null) {
      _allProducts = widget.allProducts!;
      _isLoading = false;
    } else {
      _fetchProducts();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final products = await _shopService.getAllProducts();
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Filtering Logic ───────────────────────────────────────────────────────

  List<ProductModel> get _filtered {
    List<ProductModel> list = widget.categoryName == 'All'
        ? [..._allProducts]
        : _allProducts.where((p) => p.category == widget.categoryName).toList();

    // Badge filter
    if (_selectedBadge == 'Trending') {
      list = list.where((p) => p.isTrending).toList();
    } else if (_selectedBadge == 'New Arrival') {
      list = list.where((p) => p.isNew).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }

    // Sort
    switch (_selectedSort) {
      case 'Price Low to High':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price High to Low':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Old to New':
        list.sort((a, b) => _compareProductDate(a, b));
        break;
      case 'New to Old':
        list.sort((a, b) => _compareProductDate(b, a));
        break;
    }

    return list;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  int _compareProductDate(ProductModel a, ProductModel b) {
    final aDate = DateTime.tryParse(a.createdAt ?? '');
    final bDate = DateTime.tryParse(b.createdAt ?? '');
    if (aDate != null && bDate != null) return aDate.compareTo(bDate);
    return a.id.compareTo(b.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, AppColors.goldLight],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchProducts,
            color: const Color(0xFFD4AF37),
            child: Column(
              children: [
                // ── APP BAR ───────────────────────────────────────────
                _buildAppBar(),

                // ── SEARCH ────────────────────────────────────────────
                _buildSearchBar(),

                // ── FILTER CHIPS ──────────────────────────────────────
                _buildFilterChips(),

                // ── RESULT COUNT + SORT ───────────────────────────────
                _buildResultRow(),

                // ── PRODUCTS GRID ─────────────────────────────────────
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── WIDGETS ───────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: Color(0xFF1E3A5F)),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.categoryName,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E3A5F),
                  ),
                ),
                if (!_isLoading)
                  Text(
                    '${_filtered.length} products',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
              ],
            ),
          ),
          // Sort icon button
          GestureDetector(
            onTap: _showSortSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sort_rounded,
                      size: 16, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 4),
                  Text(
                    'Sort',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E3A5F),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildWishlistButton(),
          _buildCartButton(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search in ${widget.categoryName}…',
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black38,
            ),
            prefixIcon: const Icon(Icons.search_rounded,
                size: 18, color: Colors.black38),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 16, color: Colors.black38),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                      _searchFocus.unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final badges = ['All', 'Trending', 'New Arrival'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: badges.map((badge) {
            final isActive = _selectedBadge == badge;
            return GestureDetector(
              onTap: () => setState(() => _selectedBadge = badge),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFD4AF37) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFD4AF37)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (badge == 'Trending')
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.trending_up_rounded,
                          size: 14,
                          color:
                              isActive ? Colors.black : const Color(0xFF6C63FF),
                        ),
                      ),
                    if (badge == 'New Arrival')
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.fiber_new_rounded,
                          size: 14,
                          color:
                              isActive ? Colors.black : const Color(0xFF6C63FF),
                        ),
                      ),
                    Text(
                      badge,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isActive ? Colors.black : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResultRow() {
    if (_isLoading) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${_filtered.length} results',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black45,
            ),
          ),
          if (_selectedSort != 'Recommended')
            GestureDetector(
              onTap: () => setState(() => _selectedSort = 'Recommended'),
              child: Text(
                'Clear sort',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF8B2E2E),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartButton() {
    return ListenableBuilder(
      listenable: CartService(),
      builder: (context, _) {
        final cart = CartService();

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CartScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.shopping_cart_outlined,
                size: 26,
                color: Colors.black87,
              ),
            ),

            // Badge
            if (cart.totalItems > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4AF37),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      cart.totalItems.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildWishlistButton() {
    return ListenableBuilder(
      listenable: _wishlist,
      builder: (context, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProductWishlistScreen()),
              ),
              icon: const Icon(
                Icons.favorite_border_rounded,
                size: 25,
                color: Colors.black87,
              ),
            ),
            if (_wishlist.count > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4AF37),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _wishlist.count.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    // Loading
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
      );
    }

    // Error
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.black26),
              const SizedBox(height: 12),
              Text(
                'Could not load products.\nCheck your connection and try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black45),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchProducts,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filtered;

    // Empty
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results for "$_searchQuery"'
                  : 'No products in this category yet.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black45),
            ),
          ],
        ),
      );
    }

    // Grid
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GridView.builder(
        itemCount: filtered.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        itemBuilder: (context, index) {
          return ProductCard(product: filtered[index]);
        },
      ),
    );
  }

  // ── Sort Bottom Sheet ─────────────────────────────────────────────────────

  void _showSortSheet() {
    final options = [
      ('Recommended', Icons.recommend_outlined),
      ('Old to New', Icons.history_rounded),
      ('New to Old', Icons.new_releases_outlined),
      ('Price Low to High', Icons.arrow_upward_rounded),
      ('Price High to Low', Icons.arrow_downward_rounded),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sort By',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 12),
              ...options.map((opt) {
                final isSelected = _selectedSort == opt.$1;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    opt.$2,
                    size: 20,
                    color:
                        isSelected ? const Color(0xFFD4AF37) : Colors.black45,
                  ),
                  title: Text(
                    opt.$1,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isSelected ? const Color(0xFF1E3A5F) : Colors.black87,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: Color(0xFFD4AF37), size: 20)
                      : null,
                  onTap: () {
                    setState(() => _selectedSort = opt.$1);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
