// lib/screens/shop/checkout_screen.dart
//
// Redesigned Checkout – matches app's navy/gold aesthetic
// Features:
//  - Saved addresses with radio selection + add new address
//  - Save address button → POST /api/addresses → shown as saved tile
//  - Order summary with item names, qty, price + arrow → product_details
//  - Payment: Razorpay or Cash on Delivery
//  - Clean border-box section cards (no filled navy headers)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/order_service.dart';
import '../../core/services/razorpay_service.dart';
import '../../core/models/order/order_model.dart';
import '../../core/models/order/place_order_request.dart';
import '../mainwidgets/header.dart';
import './thankyou_screen.dart';
import './product_details_screen.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const _navy = Color(0xFF1E3A5F);
const _gold = Color(0xFFD4AF37);
const _goldLight = Color(0xFFFFF8E7);
const _bgTop = Color(0xFFF8F4ED);
const _cardBg = Colors.white;
const _borderColor = Color(0xFFE8E0D0);
const _textMuted = Color(0xFF8A8A8A);
const _textDark = Color(0xFF1A1A2E);

// ── Saved address model ────────────────────────────────────────────────────
class SavedAddress {
  final String id;
  final String label;
  final String name;
  final String phone;
  final String fullAddress;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.fullAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'name': name,
      'phone': phone,
      'fullAddress': fullAddress,
    };
  }

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'],
      label: json['label'],
      name: json['name'],
      phone: json['phone'],
      fullAddress: json['fullAddress'],
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  final double promoDiscount;
  final String? appliedPromoCode;

  const CheckoutScreen({
    super.key,
    this.promoDiscount = 0,
    this.appliedPromoCode,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final OrderService _orderService = OrderService();
  final RazorpayService _razorpayService = RazorpayService();
  final CartService _cart = CartService();

  late final AnimationController _animCtrl;
  late final Razorpay _razorpay;
  OrderModel? _pendingRazorpayOrder;

  // ── Addresses ────────────────────────────────────────────────────────────
  List<SavedAddress> _savedAddresses = [];
  String? _selectedAddressId;
  bool _showNewAddressForm = false;

  // ── New address controllers ───────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  String _newAddressLabel = 'Home';

  // form key just for the new-address sub-form so we can validate it alone
  final _newAddrFormKey = GlobalKey<FormState>(); // ← NEW

  // ── Payment ──────────────────────────────────────────────────────────────
  String _selectedPayment = 'razorpay';
  // ── Pricing ───────────────────────────────────────────────────────────────
  static const double _gstRate = 0.05;
  static const double _shippingCharge = 100.0;

  double get _subtotal => _cart.totalPrice;
  double get _gstAmount => _subtotal * _gstRate;
  double get _total =>
      _subtotal + _gstAmount + _shippingCharge - widget.promoDiscount;

  bool _isPlacingOrder = false;

  // ══════════════════════════════════════════════════════════════════════════
  // INIT / DISPOSE
  // ══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animCtrl.forward();
    _loadSavedAddresses();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _animCtrl.dispose();
    for (final c in [
      _nameCtrl,
      _phoneCtrl,
      _addressCtrl,
      _cityCtrl,
      _stateCtrl,
      _pincodeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAddressesLocally() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = _savedAddresses.map((e) => jsonEncode(e.toJson())).toList();

    await prefs.setStringList(
      'saved_addresses',
      encoded,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOAD SAVED ADDRESSES  (GET /api/addresses)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _loadSavedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localAddresses = prefs.getStringList('saved_addresses');

      if (localAddresses != null && localAddresses.isNotEmpty) {
        final loaded = localAddresses.map((e) {
          return SavedAddress.fromJson(
            jsonDecode(e),
          );
        }).toList();

        setState(() {
          _savedAddresses = loaded;

          _selectedAddressId = loaded.isNotEmpty ? loaded.first.id : null;

          _showNewAddressForm = loaded.isEmpty;
        });

        return;
      }

      // ── Preferred: dedicated address endpoint ─────────────────────────────
      // If your backend exposes GET /api/addresses, use that instead of
      // scraping past orders.  Uncomment the block below and remove the
      // orders-scraping block.
      //
      // final response = await http.get(
      //   Uri.parse('http://10.0.2.2:8000/api/addresses'),
      //   headers: {
      //     'Accept': 'application/json',
      //     'Authorization': 'Bearer $token',
      //   },
      // );
      // if (response.statusCode == 200) {
      //   final List data = jsonDecode(response.body)['data'];
      //   final loaded = data.map((a) => SavedAddress(
      //     id:          a['id'].toString(),
      //     label:       a['label'] ?? 'Home',
      //     name:        a['name']  ?? '',
      //     phone:       a['phone'] ?? '',
      //     fullAddress: a['full_address'] ?? '',
      //   )).toList();
      //   setState(() {
      //     _savedAddresses   = loaded;
      //     _selectedAddressId = loaded.isNotEmpty ? loaded.first.id : null;
      //     _showNewAddressForm = loaded.isEmpty;
      //   });
      //   return;
      // }

      final orders = await _orderService.getMyOrders();
      final loaded = <SavedAddress>[];
      final seen = <String>{};

      for (final order in orders) {
        final address = order.shippingAddress;
        final phone = order.phone;
        final key = '$address|$phone';
        if (!seen.contains(key) && address.isNotEmpty) {
          seen.add(key);
          loaded.add(
            SavedAddress(
              id: order.id.toString(),
              label: 'Saved',
              name: 'Delivery Address',
              phone: phone,
              fullAddress: address,
            ),
          );
        }
      }

      setState(() {
        _savedAddresses = loaded;
        _selectedAddressId = loaded.isNotEmpty ? loaded.first.id : null;
        _showNewAddressForm = loaded.isEmpty;
      });
    } catch (e) {
      debugPrint('_loadSavedAddresses error: $e');
      setState(() => _showNewAddressForm = true);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SAVE NEW ADDRESS  (POST /api/addresses)  ← NEW
  // ══════════════════════════════════════════════════════════════════════════

  // Future<void> _saveNewAddress() async {
  //   // Validate only the new-address sub-form
  //   if (!(_newAddrFormKey.currentState?.validate() ?? false)) return;

  //   setState(() => _isSavingAddress = true);

  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString('token');

  //     final fullAddress =
  //         '${_addressCtrl.text.trim()}, '
  //         '${_cityCtrl.text.trim()}, '
  //         '${_stateCtrl.text.trim()} - '
  //         '${_pincodeCtrl.text.trim()}';

  //     // ── POST to your backend ─────────────────────────────────────────────
  //     // Adjust the endpoint & payload keys to match your Laravel routes.
  //     final response = await http.post(
  //       Uri.parse('http://10.0.2.2:8000/api'),
  //       headers: {
  //         'Accept': 'application/json',
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //       body: jsonEncode({
  //         'label':        _newAddressLabel,
  //         'name':         _nameCtrl.text.trim(),
  //         'phone':        _phoneCtrl.text.trim(),
  //         'full_address': fullAddress,
  //         // raw fields (optional, store them separately if your schema has columns)
  //         'street':  _addressCtrl.text.trim(),
  //         'city':    _cityCtrl.text.trim(),
  //         'state':   _stateCtrl.text.trim(),
  //         'pincode': _pincodeCtrl.text.trim(),
  //       }),
  //     );

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       final body = jsonDecode(response.body);
  //       // Your API should return the newly created address with its id.
  //       // Adjust the key path if needed (e.g. body['address']['id']).
  //       final newId = (body['data']?['id'] ?? body['id'])?.toString()
  //           ?? DateTime.now().millisecondsSinceEpoch.toString();

  //       final newAddr = SavedAddress(
  //         id:          newId,
  //         label:       _newAddressLabel,
  //         name:        _nameCtrl.text.trim(),
  //         phone:       _phoneCtrl.text.trim(),
  //         fullAddress: fullAddress,
  //       );

  //       setState(() {
  //         _savedAddresses     = [..._savedAddresses, newAddr];
  //         _selectedAddressId  = newId;   // auto-select the just-saved address
  //         _showNewAddressForm = false;   // collapse the form
  //         _isSavingAddress    = false;
  //       });

  //       // Clear form fields
  //       _nameCtrl.clear();
  //       _phoneCtrl.clear();
  //       _addressCtrl.clear();
  //       _cityCtrl.clear();
  //       _stateCtrl.clear();
  //       _pincodeCtrl.clear();
  //       _newAddressLabel = 'Home';

  //       _showSnack('Address saved successfully!');
  //     } else {
  //       final err = jsonDecode(response.body);
  //       throw Exception(err['message'] ?? 'Failed to save address');
  //     }
  //   } catch (e) {
  //     setState(() => _isSavingAddress = false);
  //     _showSnack(e.toString().replaceFirst('Exception: ', ''));
  //   }
  // }

  // ══════════════════════════════════════════════════════════════════════════
  // PLACE ORDER
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _openRazorpay(OrderModel order) async {
    final paymentOrder = await _razorpayService.createProductOrder(order.id);
    if (paymentOrder.keyId.isEmpty || paymentOrder.orderId.isEmpty) {
      throw Exception('Razorpay order initialization failed.');
    }

    final prefs = await SharedPreferences.getInstance();
    _pendingRazorpayOrder = order;

    _razorpay.open({
      'key': paymentOrder.keyId,
      'amount': paymentOrder.amount,
      'currency': paymentOrder.currency,
      'name': 'Astrozura',
      'description': order.orderNumber,
      'order_id': paymentOrder.orderId,
      'prefill': {
        'contact': order.phone,
        'email': prefs.getString('user_email') ?? '',
        'name': prefs.getString('user_name') ?? '',
      },
      'theme': {'color': '#D4AF37'},
    });
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final order = _pendingRazorpayOrder;
    if (order == null) return;

    try {
      await _razorpayService.verifyProductPayment(
        orderId: order.id,
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );
      await _saveAddressesLocally();
      _cart.clearCart();
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ThankYouScreen(order: order)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _pendingRazorpayOrder = null;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _pendingRazorpayOrder = null;
    if (!mounted) return;
    setState(() => _isPlacingOrder = false);
    _showSnack(response.message ?? 'Payment was not completed.');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showSnack('External wallet selected: ${response.walletName ?? ''}');
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cart.items.isEmpty) {
      _showSnack('Your cart is empty!');
      return;
    }
    if (_selectedAddressId == null && !_showNewAddressForm) {
      _showSnack('Please select or add a delivery address');
      return;
    }

    setState(() => _isPlacingOrder = true);

    String address;
    String phone;

    if (_selectedAddressId != null) {
      final a = _savedAddresses.firstWhere((x) => x.id == _selectedAddressId);
      address = a.fullAddress;
      phone = a.phone;
    } else {
      // User hasn't saved yet — use the typed values directly
      address = '${_addressCtrl.text.trim()}, ${_cityCtrl.text.trim()}, '
          '${_stateCtrl.text.trim()} - ${_pincodeCtrl.text.trim()}';
      phone = _phoneCtrl.text.trim();
    }

    final request = PlaceOrderRequest(
      items: _cart.items
          .map(
            (i) => OrderItemRequest(
              productId: i.product.id,
              quantity: i.quantity,
              price: i.product.price,
            ),
          )
          .toList(),
      totalAmount: _total,
      paymentMethod: _selectedPayment == 'cod' ? 'cod' : 'razorpay',
      shippingAddress: address,
      phone: phone,
      promoCode: widget.appliedPromoCode,
      promoDiscount: widget.promoDiscount > 0 ? widget.promoDiscount : null,
      shippingCharge: _shippingCharge,
      gstAmount: _gstAmount,
    );

    try {
      final order = await _orderService.placeOrder(request);
      if (_selectedPayment != 'cod') {
        await _openRazorpay(order);
      } else {
        await _saveAddressesLocally();
        _cart.clearCart();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ThankYouScreen(order: order)),
        );
      }
    } catch (e) {
      setState(() => _isPlacingOrder = false);
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgTop,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(),
            _buildTitleRow(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  child: FadeTransition(
                    opacity: _animCtrl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionBox(
                          title: 'Delivery Address',
                          child: _buildAddressSection(),
                        ),
                        _sectionBox(
                          title: 'Order Summary',
                          child: _buildOrderSummary(),
                        ),
                        _sectionBox(
                          title: 'Payment Method',
                          child: _buildPaymentSection(),
                        ),
                        const SizedBox(height: 8),
                        _buildSecureBadge(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Title row ──────────────────────────────────────────────────────────────
  Widget _buildTitleRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, size: 18, color: _navy),
          ),
          Expanded(
            child: Text(
              'Checkout',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gold.withOpacity(0.4)),
            ),
            child: Text(
              '3 • Review & Pay',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section box ────────────────────────────────────────────────────────────
  Widget _sectionBox({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Container(height: 1, color: _borderColor)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ADDRESS SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildAddressSection() {
    return Column(
      children: [
        // ── Saved address tiles ──────────────────────────────────────────────
        ..._savedAddresses.map((addr) => _buildAddressTile(addr)),

        // ── Add new address toggle ───────────────────────────────────────────
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() {
            _showNewAddressForm = !_showNewAddressForm;
            if (_showNewAddressForm) _selectedAddressId = null;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _showNewAddressForm ? _goldLight : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showNewAddressForm ? _gold : _borderColor,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _showNewAddressForm
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: _showNewAddressForm ? _gold : _textMuted,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.add_location_alt_outlined,
                  color: _showNewAddressForm ? _gold : _textMuted,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add New Address',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _showNewAddressForm ? _navy : _textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── New address form (with Save button) ──────────────────────────────
        if (_showNewAddressForm) ...[
          const SizedBox(height: 16),
          _buildNewAddressForm(),
        ],
      ],
    );
  }

  Widget _buildAddressTile(SavedAddress addr) {
    final isSelected = _selectedAddressId == addr.id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedAddressId = addr.id;
        _showNewAddressForm = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _goldLight : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _gold : _borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? _gold : _textMuted,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _labelChip(addr.label),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          addr.name,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    addr.fullAddress,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    addr.phone,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _navy,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: _gold, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _labelChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _navy.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _navy,
        ),
      ),
    );
  }

  // ── New address form ───────────────────────────────────────────────────────
  // Wrapped in its own Form so validation is scoped to this sub-form only.
  Widget _buildNewAddressForm() {
    return Form(
      key: _newAddrFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label selector
          Row(
            children: ['Home', 'Work', 'Other'].map((lbl) {
              final sel = _newAddressLabel == lbl;
              return GestureDetector(
                onTap: () => setState(() => _newAddressLabel = lbl),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? _gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? _gold : _borderColor,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    lbl,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : _textMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _row2(
            _field(
              _nameCtrl,
              'Full Name',
              Icons.person_outline,
              validator: _required,
            ),
            _field(
              _phoneCtrl,
              'Phone',
              Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: _phone,
            ),
          ),
          const SizedBox(height: 12),
          _field(
            _addressCtrl,
            'Street Address',
            Icons.home_outlined,
            maxLines: 2,
            validator: _required,
          ),
          const SizedBox(height: 12),
          _row2(
            _field(
              _cityCtrl,
              'City',
              Icons.location_city_outlined,
              validator: _required,
            ),
            _field(
              _stateCtrl,
              'State',
              Icons.map_outlined,
              validator: _required,
            ),
          ),
          const SizedBox(height: 12),
          _field(
            _pincodeCtrl,
            'Pincode',
            Icons.pin_drop_outlined,
            keyboardType: TextInputType.number,
            validator: _pincode,
          ),

          // ── SAVE ADDRESS BUTTON ────────────────────────────────────────────
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                // Validate form
                if (!(_newAddrFormKey.currentState?.validate() ?? false)) {
                  return;
                }

                // Create full address
                final fullAddress = '${_addressCtrl.text.trim()}, '
                    '${_cityCtrl.text.trim()}, '
                    '${_stateCtrl.text.trim()} - '
                    '${_pincodeCtrl.text.trim()}';

                // Create temporary address object
                final newAddress = SavedAddress(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  label: _newAddressLabel,
                  name: _nameCtrl.text.trim(),
                  phone: _phoneCtrl.text.trim(),
                  fullAddress: fullAddress,
                );

                setState(() {
                  // Add new address on top
                  _savedAddresses.insert(0, newAddress);

                  // Auto select new address
                  _selectedAddressId = newAddress.id;

                  // Hide form
                  _showNewAddressForm = false;
                });
                _saveAddressesLocally();

                // Clear fields
                _nameCtrl.clear();
                _phoneCtrl.clear();
                _addressCtrl.clear();
                _cityCtrl.clear();
                _stateCtrl.clear();
                _pincodeCtrl.clear();

                _newAddressLabel = 'Home';

                _showSnack('Address selected successfully');
              },
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(
                'Use This Address',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: _textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                'Saved addresses appear every time you check out.',
                style: GoogleFonts.poppins(fontSize: 10.5, color: _textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ORDER SUMMARY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildOrderSummary() {
    return Column(
      children: [
        ..._cart.items.map((item) => _buildOrderItem(item)),
        const SizedBox(height: 12),
        const Divider(color: _borderColor, height: 1),
        const SizedBox(height: 12),
        _priceRow(
          'Subtotal (${_cart.totalItems} items)',
          '₹${_subtotal.toStringAsFixed(2)}',
        ),
        _priceRow('GST (5%)', '₹${_gstAmount.toStringAsFixed(2)}'),
        _priceRow('Shipping', '₹${_shippingCharge.toStringAsFixed(2)}'),
        if (widget.promoDiscount > 0)
          _priceRow(
            'Promo Discount',
            '− ₹${widget.promoDiscount.toStringAsFixed(2)}',
            valueColor: const Color(0xFF2E7D32),
          ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _navy.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payable',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              Text(
                '₹${_total.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _gold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(dynamic item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: item.product),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item.product.images.isNotEmpty ? item.product.images[0] : '',
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _bgTop,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderColor),
                  ),
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: _textMuted,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₹${item.product.price.toStringAsFixed(0)} × ${item.quantity}',
                    style: GoogleFonts.poppins(fontSize: 12, color: _textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '₹${item.totalPrice.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: _textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12.5, color: _textMuted),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: valueColor ?? _textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAYMENT SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPaymentSection() {
    return Column(
      children: [
        _paymentTile(
          value: 'razorpay',
          icon: Icons.account_balance_wallet_outlined,
          label: 'Razorpay',
          subtitle: 'UPI, cards, wallets and net banking',
        ),
        const SizedBox(height: 8),
        _paymentTile(
          value: 'cod',
          icon: Icons.money_outlined,
          label: 'Cash on Delivery',
          subtitle: 'Pay when you receive',
        ),
      ],
    );
  }

  Widget _paymentTile({
    required String value,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _selectedPayment == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _goldLight : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _gold : _borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? _gold.withOpacity(0.18) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? _gold : _borderColor),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? _gold : _textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? _navy : _textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(fontSize: 11, color: _textMuted),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? _gold : _textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ── Secure badge ───────────────────────────────────────────────────────────
  Widget _buildSecureBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_rounded, size: 13, color: _textMuted),
        const SizedBox(width: 5),
        Text(
          'SSL encrypted & 100% secure checkout',
          style: GoogleFonts.poppins(fontSize: 11, color: _textMuted),
        ),
      ],
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Payable',
                  style: GoogleFonts.poppins(fontSize: 11, color: _textMuted),
                ),
                Text(
                  '₹${_total.toStringAsFixed(2)}',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 50,
              width: 200,
              child: ElevatedButton(
                onPressed: _isPlacingOrder ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isPlacingOrder
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _selectedPayment == 'cod'
                            ? 'Place Order'
                            : 'Confirm & Pay',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _row2(Widget a, Widget b) => Row(
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 13, color: _textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 12.5, color: _textMuted),
        prefixIcon: Icon(icon, size: 17, color: _navy.withOpacity(0.5)),
        filled: true,
        fillColor: const Color(0xFFF9F8F5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  // ── Validators ─────────────────────────────────────────────────────────────
  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (v.trim().length < 10) return 'Enter valid phone number';
    return null;
  }

  String? _pincode(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (v.trim().length != 6) return '6-digit pincode required';
    return null;
  }
}
