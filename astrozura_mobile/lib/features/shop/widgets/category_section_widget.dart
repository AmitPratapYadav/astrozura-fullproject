// lib/screens/shop/widgets/category_section.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/shop_category/shop_category_model.dart';
import '../../../core/models/product/product.model.dart';
import '../product_listing_page.dart';

class CategorySection extends StatelessWidget {
  final List<ShopCategoryModel> categories;
  final List<ProductModel> allProducts;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  // ── App-wide palette ──────────────────────────────────────────────
  static const Color _navy = Color(0xFF2E2A72);
  static const Color _navyCard = Color(0xFF252B4A);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldSoft = Color(0xFFF0CC60);
  static const Color _white = Color(0xFFFFFFFF);
  // ─────────────────────────────────────────────────────────────────

  const CategorySection({
    super.key,
    required this.categories,
    required this.allProducts,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  int _productCount(ShopCategoryModel cat) {
    if (cat.name == 'All') return allProducts.length;
    return allProducts.where((p) => p.category == cat.name).length;
  }

  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('crystal') || n.contains('stone')) {
      return Icons.diamond_outlined;
    }
    if (n.contains('book') || n.contains('guide')) {
      return Icons.menu_book_outlined;
    }
    if (n.contains('oil') || n.contains('aroma')) {
      return Icons.water_drop_outlined;
    }
    if (n.contains('candle') || n.contains('incense')) {
      return Icons.local_fire_department_outlined;
    }
    if (n.contains('card') || n.contains('tarot')) return Icons.style_outlined;
    if (n.contains('jewel') || n.contains('pendant')) {
      return Icons.circle_outlined;
    }
    if (n.contains('herb') || n.contains('plant')) return Icons.eco_outlined;
    if (n.contains('all')) return Icons.apps_rounded;
    return Icons.auto_awesome_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 154,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategory == cat.name;
          final count = _productCount(cat);

          return GestureDetector(
            onTap: () {
              onCategoryChanged(cat.name);
              if (cat.name != 'All') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductListingPage(
                      categoryName: cat.name,
                      allProducts: allProducts,
                    ),
                  ),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 110,
              margin: const EdgeInsets.only(right: 12, bottom: 10),
              decoration: BoxDecoration(
                // Selected → gold gradient  |  Unselected → white card
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [_gold, Color(0xFFAA8A00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Colors.white, Color(0xFFF5F5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? _goldSoft
                      : _gold.withOpacity(0.3), // subtle gold rim always
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? _gold.withOpacity(0.45)
                        : Colors.black.withOpacity(0.25),
                    blurRadius: isSelected ? 14 : 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Icon bubble ──────────────────────────────────
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : _gold.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconFor(cat.name),
                      size: 24,
                      // Selected → dark navy icon on gold bg
                      // Unselected → gold icon on dark bg
                      color: isSelected ? _white : _navy,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Category name (2 lines, never clipped) ───────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      cat.name,
                      maxLines: 2,
                      overflow: TextOverflow.clip,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: isSelected ? _white : _navy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // ── Count pill ───────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _navy.withOpacity(0.2)
                          : _gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count items',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? _white : _gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
