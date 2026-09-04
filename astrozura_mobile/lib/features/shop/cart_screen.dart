// lib/screens/shop/cart_screen.dart
//
// Cart screen – null-safe, conditional promo, empty-state, auto-dismiss snackbar

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/cart_service.dart';
import './widgets/cartItem_widget.dart';
import './widgets/shop_header.dart';
import './checkout_screen.dart';

// ── Palette (matches app theme) ───────────────────────────────────────────────
const _navy = Color(0xFF1E3A5F);
const _gold = Color(0xFFD4AF37);
const _darkNavy = Color(0xFF2E2A63);

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // ── Services & controllers ─────────────────────────────────────────────────
  final CartService _cart = CartService();
  final TextEditingController _promoCtrl = TextEditingController();

  // ── Promo state ────────────────────────────────────────────────────────────
  double _promoDiscount = 0;
  String _appliedCode = '';
  bool _isPromoApplied = false;

  // ── Pricing constants ──────────────────────────────────────────────────────
  static const double _shippingCharge = 100.0;

  // ── Computed totals ────────────────────────────────────────────────────────
  double get _subtotal => _cart.totalPrice;
  double get _total => _subtotal + _shippingCharge - _promoDiscount;
  int get _itemCount => _cart.totalItems;
  bool get _cartEmpty => _cart.items.isEmpty;

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  // ── Promo logic ────────────────────────────────────────────────────────────
  void _applyPromoCode() {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) {
      _showSnack('Please enter a promo code', isError: true);
      return;
    }

    // Only all-uppercase codes are valid
    if (code == code.toUpperCase()) {
      setState(() {
        _promoDiscount = 50;
        _appliedCode = code;
        _isPromoApplied = true;
      });
      _showSnack('Promo applied! ₹50 discount 🎉');
    } else {
      setState(() {
        _promoDiscount = 0;
        _appliedCode = '';
        _isPromoApplied = false;
      });
      _showSnack('Invalid code. Use uppercase letters only.', isError: true);
    }
  }

  void _removePromo() {
    setState(() {
      _promoDiscount = 0;
      _appliedCode = '';
      _isPromoApplied = false;
      _promoCtrl.clear();
    });
  }

  // ── Auto-dismiss snackbar (2 s) ────────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor:
              isError ? Colors.red.shade600 : Colors.green.shade700,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
  }

  // ── Navigate to checkout ───────────────────────────────────────────────────
  void _proceedToCheckout() {
    if (_cartEmpty) {
      _showSnack('Your cart is empty!', isError: true);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          promoDiscount: _promoDiscount,
          appliedPromoCode: _isPromoApplied ? _appliedCode : null,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const ShopHeader(compact: true),
            _buildTitleRow(),
            Expanded(
              child: _cartEmpty ? _buildEmptyCart() : _buildCartContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _cartEmpty ? null : _buildBottomBar(),
    );
  }

  // ── Title row ──────────────────────────────────────────────────────────────
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
              icon: const Icon(Icons.arrow_back_ios, size: 20),
            ),
          ),
          Text(
            'My Cart',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _gold,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _navy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_itemCount ITEM${_itemCount == 1 ? '' : 'S'}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty cart ─────────────────────────────────────────────────────────────
  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 48,
                color: _gold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Browse our collection and add\nproducts to your cart.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.store_outlined, size: 18),
              label: const Text(
                'Go to Shop',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main cart content (items + promo + summary) ────────────────────────────
  Widget _buildCartContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Cart items ────────────────────────────────────────────────────
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cart.items.length,
            itemBuilder: (context, index) {
              // Guard against index going out of bounds after deletion
              if (index >= _cart.items.length) return const SizedBox.shrink();
              final item = _cart.items[index];

              return CartItemWidget(
                item: item,
                onDelete: () => setState(() => _cart.removeItem(item.product)),
                onIncrease: () => setState(() => item.quantity++),
                onDecrease: () {
                  if (item.quantity > 1) {
                    setState(() => item.quantity--);
                  }
                },
              );
            },
          ),

          const SizedBox(height: 20),

          // ── Promo code (only shown when cart has items) ───────────────────
          _buildPromoSection(),

          const SizedBox(height: 20),

          // ── Order summary ─────────────────────────────────────────────────
          _buildOrderSummary(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Promo section ──────────────────────────────────────────────────────────
  Widget _buildPromoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Row(
            children: [
              const Icon(Icons.local_offer_outlined, size: 16, color: _navy),
              const SizedBox(width: 6),
              const Text(
                'PROMO CODE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Applied banner
          if (_isPromoApplied) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"$_appliedCode" applied!',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          'You save ₹${_promoDiscount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _removePromo,
                    child: Icon(Icons.close_rounded,
                        color: Colors.green.shade600, size: 20),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Input row
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _darkNavy,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer,
                            color: Colors.redAccent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _promoCtrl,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Enter code',
                              hintStyle: TextStyle(
                                  color: Colors.white54, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _applyPromoCode,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    decoration: BoxDecoration(
                      color: _gold,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Center(
                      child: Text(
                        'Apply',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Order summary card ─────────────────────────────────────────────────────
  Widget _buildOrderSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ORDER SUMMARY',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            _summaryRow(
                'Subtotal ($_itemCount item${_itemCount == 1 ? '' : 's'})',
                '₹${_subtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            _summaryRow('Shipping', '₹${_shippingCharge.toStringAsFixed(2)}'),

            if (_isPromoApplied) ...[
              const SizedBox(height: 10),
              _summaryRow(
                'Promo Discount ($_appliedCode)',
                '− ₹${_promoDiscount.toStringAsFixed(2)}',
                isDiscount: true,
              ),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '₹${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _gold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Secure badge
            Row(
              children: const [
                Icon(Icons.security_rounded, size: 13, color: Colors.grey),
                SizedBox(width: 6),
                Text(
                  'Secure SSL encrypted checkout',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDiscount ? Colors.green.shade600 : Colors.black87,
          ),
        ),
      ],
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total + item count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Payment',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '₹${_total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_itemCount ITEM${_itemCount == 1 ? '' : 'S'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Checkout button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _proceedToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Proceed to Checkout',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _navy,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
