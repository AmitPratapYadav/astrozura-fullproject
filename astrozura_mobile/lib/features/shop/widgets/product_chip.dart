// lib/screens/shop/widgets/product_chip.dart  (ProductCard)
//
// Works with the updated ProductModel:
//   • price is now double  → no .toStringAsFixed() issues
//   • images getter        → always returns at least a placeholder
//   • Navigates to cart after add, but can be toggled off

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/contants/app_colors.dart';
import '../../../core/models/product/product.model.dart';
import '../../../core/services/product_wishlist_service.dart';
import '../product_details_screen.dart';
import '../../../core/services/cart_service.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── PRODUCT IMAGE ──────────────────────────────────────────
            Stack(
              children: [
                _ProductImage(imageUrl: product.images[0]),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _WishlistToggle(product: product),
                ),
              ],
            ),

            // ── CARD CONTENT ───────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ⭐ RATING ROW
                    _RatingRow(
                      rating: product.rating,
                      reviews: product.reviews,
                    ),

                    const SizedBox(height: 4),

                    // 🧾 PRODUCT NAME
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // 💰 PRICE ROW
                    _PriceRow(
                      price: product.price,
                      oldPrice: product.oldPrice,
                    ),

                    const Spacer(),

                    // 🛒 ADD TO CART BUTTON
                    _AddToCartButton(product: product),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SUB WIDGETS ──────────────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  final String imageUrl;

  const _ProductImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.grey.shade100,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade100,
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: Colors.grey,
                size: 36,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WishlistToggle extends StatefulWidget {
  final ProductModel product;

  const _WishlistToggle({required this.product});

  @override
  State<_WishlistToggle> createState() => _WishlistToggleState();
}

class _WishlistToggleState extends State<_WishlistToggle> {
  final ProductWishlistService _wishlist = ProductWishlistService();

  @override
  void initState() {
    super.initState();
    _wishlist.load();
  }

  Future<void> _toggle() async {
    try {
      await _wishlist.toggle(widget.product);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _wishlist,
      builder: (context, _) {
        final isSaved = _wishlist.isWishlisted(widget.product.id);
        return Material(
          color: Colors.white.withOpacity(0.92),
          shape: const CircleBorder(),
          elevation: 3,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Icon(
                isSaved
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 18,
                color: isSaved ? const Color(0xFFE1456B) : Colors.black54,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final int reviews;

  const _RatingRow({required this.rating, required this.reviews});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < rating.floor() ? Icons.star : Icons.star_border,
            size: 13,
            color:
                index < rating.floor() ? Colors.orange : Colors.grey.shade300,
          );
        }),
        const SizedBox(width: 4),
        Text(
          '($reviews)',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final double price;
  final double? oldPrice;

  const _PriceRow({required this.price, this.oldPrice});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Rs.${price.toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        if (oldPrice != null) ...[
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Rs.${oldPrice!.toStringAsFixed(0)}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  final ProductModel product;

  const _AddToCartButton({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        CartService().addToCart(product);

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                '${product.name} added to cart',
              ),
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFD4AF37),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 14, color: Colors.black),
            SizedBox(width: 5),
            Text(
              'Add to Cart',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
