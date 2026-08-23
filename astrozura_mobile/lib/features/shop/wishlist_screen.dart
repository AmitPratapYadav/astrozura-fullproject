import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/product/product.model.dart';
import '../../core/services/product_wishlist_service.dart';
import 'product_details_screen.dart';

class ProductWishlistScreen extends StatefulWidget {
  const ProductWishlistScreen({super.key});

  @override
  State<ProductWishlistScreen> createState() => _ProductWishlistScreenState();
}

class _ProductWishlistScreenState extends State<ProductWishlistScreen> {
  final ProductWishlistService _wishlist = ProductWishlistService();

  @override
  void initState() {
    super.initState();
    _wishlist.load(force: true);
  }

  Future<void> _toggle(ProductModel product) async {
    try {
      await _wishlist.toggle(product);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3557),
        elevation: 0,
        title: Text(
          'Wishlist',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E3557),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _wishlist,
        builder: (context, _) {
          if (_wishlist.isLoading && !_wishlist.isLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          }

          final products = _wishlist.products;
          if (products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF3CD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 34,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No wishlist products yet',
                      style: TextStyle(
                        color: Color(0xFF1E3557),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the heart on any product to save it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF607089)),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFFD4AF37),
            onRefresh: () => _wishlist.load(force: true),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = products[index];
                return _WishlistTile(
                  product: product,
                  onOpen: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsScreen(product: product),
                    ),
                  ),
                  onRemove: () => _toggle(product),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _WishlistTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _WishlistTile({
    required this.product,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAD9AE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 82,
                height: 82,
                child: product.image?.isNotEmpty == true
                    ? Image.network(
                        product.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _ImageFallback(),
                      )
                    : const _ImageFallback(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category ?? 'Astro Product',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1E3557),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rs.${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF1E3557),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded),
              color: const Color(0xFFB63D3D),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F0E4),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Color(0xFF9AA6B7),
      ),
    );
  }
}
