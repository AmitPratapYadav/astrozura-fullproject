// lib/screens/shop/shop_screen.dart
//
// Updated: SearchBarWidget fully wired — searches by name & category.
// Filter icon opens a bottom sheet for category + sort selection.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/contants/app_colors.dart';
import '../../core/models/product/product.model.dart';
import '../../core/models/shop_category/shop_category_model.dart';
import '../../core/services/shop_service.dart';

import '../mainwidgets/search_widget.dart';
import 'widgets/product_chip.dart';
import './widgets/category_section_widget.dart';
import 'widgets/shop_header.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  // ── Service ────────────────────────────────────────────────────────────────
  final ShopService _shopService = ShopService();

  // ── Data ───────────────────────────────────────────────────────────────────
  List<ProductModel> _allProducts = [];
  List<ShopCategoryModel> _categories = [];

  // ── UI State ───────────────────────────────────────────────────────────────
  bool _isLoadingProducts = true;
  bool _isLoadingCategories = true;
  String? _productError;

  String _selectedCategory = 'All';
  String _selectedSort = 'Recommended';
  String _searchQuery = ''; // ← NEW

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchCategories(), _fetchProducts()]);
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productError = null;
    });
    try {
      final products = await _shopService.getAllProducts();
      setState(() {
        _allProducts = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _productError = e.toString();
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });
    try {
      final cats = await _shopService.getCategories();
      setState(() {
        _categories = [
          const ShopCategoryModel(id: 0, name: 'All'),
          ...cats,
        ];
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _categories = [const ShopCategoryModel(id: 0, name: 'All')];
        _isLoadingCategories = false;
      });
    }
  }

  // ── Search Handler ─────────────────────────────────────────────────────────

  void _onSearch(String value) {
    setState(() {
      _searchQuery = value.toLowerCase().trim();
    });
  }

  // ── Filter Bottom Sheet ────────────────────────────────────────────────────

  void _showFilterSheet() {
    // Capture temp state for the sheet
    String tempCategory = _selectedCategory;
    String tempSort = _selectedSort;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Handle ───────────────────────────────────────
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Title ────────────────────────────────────────
                  Text(
                    'Filter Products',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E3A5F),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Category ─────────────────────────────────────
                  Text(
                    'CATEGORY',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _categories.map((cat) {
                      final isSelected = cat.name == tempCategory;
                      return GestureDetector(
                        onTap: () =>
                            setSheetState(() => tempCategory = cat.name),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFD4AF37)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFD4AF37)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // ── Sort ─────────────────────────────────────────
                  Text(
                    'SORT BY',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: [
                      'Recommended',
                      'Trending',
                      'New Arrival',
                      'Old to New',
                      'New to Old',
                      'Price Low to High',
                      'Price High to Low',
                    ].map((sort) {
                      final isSelected = sort == tempSort;
                      return GestureDetector(
                        onTap: () => setSheetState(() => tempSort = sort),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1E3A5F)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            sort,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // ── Actions ───────────────────────────────────────
                  Row(
                    children: [
                      // Reset
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              tempCategory = 'All';
                              tempSort = 'Recommended';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFD4AF37)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(color: Color(0xFFD4AF37)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Apply
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = tempCategory;
                              _selectedSort = tempSort;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Filtering Logic ────────────────────────────────────────────────────────

  List<ProductModel> get _filteredProducts {
    List<ProductModel> list = _selectedCategory == 'All'
        ? [..._allProducts]
        : _allProducts.where((p) => p.category == _selectedCategory).toList();

    // Apply sort
    switch (_selectedSort) {
      case 'Trending':
        list = list.where((p) => p.isTrending).toList();
        break;
      case 'New Arrival':
        list = list.where((p) => p.isNew).toList();
        break;
      case 'Old to New':
        list.sort((a, b) => _compareProductDate(a, b));
        break;
      case 'New to Old':
        list.sort((a, b) => _compareProductDate(b, a));
        break;
      case 'Price Low to High':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price High to Low':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      default:
        break;
    }

    // ── Apply search query ─────────────────────────────────────────────────
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) {
        return p.name.toLowerCase().contains(_searchQuery) ||
            (p.category?.toLowerCase().contains(_searchQuery) ?? false) ||
            (p.description?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    return list;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  int _compareProductDate(ProductModel a, ProductModel b) {
    final aDate = DateTime.tryParse(a.createdAt ?? '');
    final bDate = DateTime.tryParse(b.createdAt ?? '');
    if (aDate != null && bDate != null) return aDate.compareTo(bDate);
    return a.id.compareTo(b.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, AppColors.goldLight],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: _fetchAll,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── SHOP HEADER ───────────────────────────────────────
                  const ShopHeader(),
                  const SizedBox(height: 10),

                  // ── SEARCH ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: GlobalSearchWidget(
                          productsOnly: true,
                          animatedHints: const [
                            'Find Pooja Products',
                            'Find Ritual Kits',
                            'Find Gemstones',
                          ],
                          onChanged: _onSearch,
                          onFilterTap: _showFilterSheet,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── ACTIVE FILTER INDICATOR ───────────────────────────
                  if (_selectedCategory != 'All' ||
                      _selectedSort != 'Recommended')
                    _buildActiveFilterRow(),

                  // ── SECTION HEADER ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Discover Cosmic Essentials',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E3A5F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Curated tools for your spiritual journey.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CATEGORIES',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: const Color(0xFF6C63FF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── CATEGORY SECTION ──────────────────────────────────
                  if (_isLoadingCategories)
                    const SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    )
                  else
                    CategorySection(
                      categories: _categories,
                      allProducts: _allProducts,
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: (name) {
                        setState(() {
                          _selectedCategory = name;
                        });
                      },
                    ),

                  const SizedBox(height: 30),

                  // ── RESULT COUNT + SORT ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isLoadingProducts
                              ? 'Loading…'
                              : '${_filteredProducts.length} result${_filteredProducts.length == 1 ? '' : 's'}${_searchQuery.isNotEmpty ? ' for "$_searchQuery"' : ''}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                        _buildSortDropdown(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── PRODUCTS GRID ─────────────────────────────────────
                  _buildProductsGrid(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Active filter chips row ────────────────────────────────────────────────
  Widget _buildActiveFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 8,
        children: [
          if (_selectedCategory != 'All')
            _filterChip(
              label: _selectedCategory,
              onRemove: () => setState(() => _selectedCategory = 'All'),
            ),
          if (_selectedSort != 'Recommended')
            _filterChip(
              label: _selectedSort,
              onRemove: () => setState(() => _selectedSort = 'Recommended'),
            ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8B6914),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Color(0xFF8B6914)),
          ),
        ],
      ),
    );
  }

  // ── WIDGETS ────────────────────────────────────────────────────────────────

  Widget _buildSortDropdown() {
    return Row(
      children: [
        const Text('Sort by: ', style: TextStyle(fontSize: 13)),
        DropdownButton<String>(
          value: _selectedSort,
          underline: const SizedBox(),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: const [
            DropdownMenuItem(value: 'Recommended', child: Text('Recommended')),
            DropdownMenuItem(value: 'Trending', child: Text('Trending')),
            DropdownMenuItem(value: 'New Arrival', child: Text('New Arrival')),
            DropdownMenuItem(value: 'Old to New', child: Text('Old to New')),
            DropdownMenuItem(value: 'New to Old', child: Text('New to Old')),
            DropdownMenuItem(
                value: 'Price Low to High', child: Text('Price Low to High')),
            DropdownMenuItem(
                value: 'Price High to Low', child: Text('Price High to Low')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _selectedSort = value);
          },
        ),
      ],
    );
  }

  Widget _buildProductsGrid() {
    if (_isLoadingProducts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child:
            Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
      );
    }

    if (_productError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            const Text(
              'Could not load products.\nCheck your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredProducts;

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 52, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No products found for "$_searchQuery"'
                    : 'No products found.',
                style: GoogleFonts.poppins(color: Colors.black45),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filtered.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        itemBuilder: (context, index) {
          return ProductCard(product: filtered[index]);
        },
      ),
    );
  }
}
