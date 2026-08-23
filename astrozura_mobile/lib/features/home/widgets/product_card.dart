import 'package:flutter/material.dart';

import '../../../core/models/product/product.model.dart';
import '../../shop/product_details_screen.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: (product.image != null && product.image!.isNotEmpty)
                  ? Image.network(
                      product.image!,
                      height: 145,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultImage(),
                    )
                  : _buildDefaultImage(),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
              decoration: const BoxDecoration(
                color: Color(0xFF2E2A72),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      _ProductRating(rating: product.rating),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      height: 145,
      width: double.infinity,
      color: const Color(0xFFF0EFEA),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: Color(0xFFBBBBBB),
        ),
      ),
    );
  }
}

class _ProductRating extends StatelessWidget {
  final double rating;

  const _ProductRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    final filled = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: 12,
          color: index < filled ? const Color(0xFFD4A84F) : Colors.white54,
        ),
      ),
    );
  }
}
