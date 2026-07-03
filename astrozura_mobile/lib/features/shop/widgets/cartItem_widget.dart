import 'package:flutter/material.dart';
import '../../../core/models/cart/cart_item.dart';


class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final VoidCallback onDelete;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    final product = item.product;

    return Container(
      margin: const EdgeInsets.only(bottom: 14, right: 10, left: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          /// 🔹 IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              product.image ?? '',
              height: 70,
              width: 70,
              fit: BoxFit.cover,

              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;

                return const SizedBox(
                  height: 70,
                  width: 70,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },

              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 70,
                  width: 70,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported),
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          /// 🔹 DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// NAME
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1E3A5F),
                  ),
                ),

                const SizedBox(height: 4),

                /// SUBTITLE (CATEGORY)
                Text(
  product.category ?? 'Spiritual Product',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 6),

                /// PRICE
                Text(
                  "Rs ${product.price}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ],
            ),
          ),

          /// 🔹 RIGHT SIDE (DELETE + QTY)
          Column(
            children: [
              /// DELETE BUTTON
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
              ),

              const SizedBox(height: 6),

              /// QUANTITY BOX
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    /// ➖
                    GestureDetector(
                      onTap: onDecrease,
                      child: const Icon(Icons.remove, size: 16),
                    ),

                    const SizedBox(width: 8),

                    /// QTY
                    Text("${item.quantity}"),

                    const SizedBox(width: 8),

                    /// ➕
                    GestureDetector(
                      onTap: onIncrease,
                      child: const Icon(Icons.add, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
