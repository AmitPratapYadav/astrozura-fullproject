import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/contants/api_constants.dart';
import '../../core/models/puja_anusthan/puja_anusthan_model.dart';
import '../../core/services/api_client.dart';
import '../../core/services/astrologer_service.dart';
import '../../core/services/razorpay_service.dart';
import '../shared/widgets/location_search_field.dart';
import 'widgets/puja_card.dart';

class PujaAnusthanDetailScreen extends StatefulWidget {
  final PujaItem item;

  const PujaAnusthanDetailScreen({super.key, required this.item});

  @override
  State<PujaAnusthanDetailScreen> createState() =>
      _PujaAnusthanDetailScreenState();
}

class _PujaAnusthanDetailScreenState extends State<PujaAnusthanDetailScreen> {
  final ApiClient _api = ApiClient();
  late PujaItem _item;
  List<PujaItem> _similar = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _load();
  }

  Future<void> _load() async {
    if (_item.slug.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final response = await _api.get(ApiConstants.ritualDetail(_item.slug));
      final rawRitual = response['ritual'];
      final rawSimilar = response['similar_rituals'];
      if (!mounted) return;
      setState(() {
        if (rawRitual is Map) {
          _item = PujaItem.fromJson(Map<String, dynamic>.from(rawRitual));
        }
        _similar = rawSimilar is List
            ? rawSimilar
                .whereType<Map>()
                .map((item) =>
                    PujaItem.fromJson(Map<String, dynamic>.from(item)))
                .toList()
            : [];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _book() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RitualBookingSheet(item: _item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _item.price > 0 ? '₹${_item.price}' : 'Contact for price',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD4A73C),
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                width: 190,
                child: ElevatedButton(
                  onPressed: _item.price > 0 ? _book : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D437B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Choose Date & Book',
                    maxLines: 1,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'POOJA ANUSTHAN',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_item.imageAsset.isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.network(
                    _item.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _MissingRitualImage(),
                  ),
                )
              else
                const AspectRatio(
                  aspectRatio: 16 / 10,
                  child: _MissingRitualImage(),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _item.tag,
                      style: const TextStyle(
                        color: Color(0xFFD4A73C),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _item.title,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E3557),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_item.durationLabel.isNotEmpty)
                          _InfoChip(
                            icon: Icons.schedule,
                            label: _item.durationLabel,
                          ),
                        if (_item.mode.isNotEmpty)
                          _InfoChip(
                            icon: Icons.place_outlined,
                            label: _item.mode,
                          ),
                        if (_item.idealTiming.isNotEmpty)
                          _InfoChip(
                            icon: Icons.event_available_outlined,
                            label: _item.idealTiming,
                          ),
                      ],
                    ),
                    if (_loading) ...[
                      const SizedBox(height: 24),
                      const Center(child: CircularProgressIndicator()),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 18),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    if (_item.description.isNotEmpty)
                      _TextSection(
                        title: 'About This Ritual',
                        text: _item.description,
                      ),
                    if (_item.benefits.isNotEmpty)
                      _TextSection(
                        title: 'Benefits',
                        text: _item.benefits,
                      ),
                    if (_item.steps.isNotEmpty)
                      _ListSection(title: 'Ritual Steps', items: _item.steps),
                    if (_item.materials.isNotEmpty)
                      _ListSection(
                        title: 'Materials',
                        items: _item.materials,
                      ),
                  ],
                ),
              ),
              if (_similar.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 26, 16, 12),
                  child: Text(
                    'Other Rituals',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E3557),
                    ),
                  ),
                ),
                SizedBox(
                  height: 250,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _similar.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final ritual = _similar[index];
                      return SizedBox(
                        width: 165,
                        child: PujaCard(
                          item: ritual,
                          onBookNow: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PujaAnusthanDetailScreen(item: ritual),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class RitualBookingSheet extends StatefulWidget {
  final PujaItem item;

  const RitualBookingSheet({super.key, required this.item});

  @override
  State<RitualBookingSheet> createState() => _RitualBookingSheetState();
}

class _RitualBookingSheetState extends State<RitualBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _notes = TextEditingController();
  final RazorpayService _paymentService = RazorpayService();
  late final Razorpay _razorpay;

  DateTime? _date;
  TimeOfDay? _time;
  String _venue = 'online';
  bool _expenseAcknowledged = false;
  bool _submitting = false;
  int? _pendingBookingId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _paymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _paymentError);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _name.text = prefs.getString('user_name') ?? '';
      _email.text = prefs.getString('user_email') ?? '';
      _phone.text = prefs.getString('user_phone') ?? '';
      final place = prefs.getString('user_pob') ?? '';
      if (place.isNotEmpty) {
        _city.text = place.split(',').first.trim();
      }
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    for (final controller in [
      _name,
      _email,
      _phone,
      _address,
      _city,
      _state,
      _pincode,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (selected != null) setState(() => _time = selected);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_date == null || _time == null) {
      _snack('Select your preferred date and time.');
      return;
    }
    if (_venue == 'client_place' && !_expenseAcknowledged) {
      _snack('Please acknowledge priest travel and accommodation expenses.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await AstrologerService.bookRitual(
        int.parse(widget.item.id),
        {
          'devotee_name': _name.text.trim(),
          'devotee_email': _email.text.trim(),
          'devotee_phone': _phone.text.trim(),
          'preferred_date':
              '${_date!.year.toString().padLeft(4, '0')}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
          'preferred_time':
              '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
          'venue_type': _venue,
          'location_address': _address.text.trim(),
          'location_city': _city.text.trim(),
          'location_state': _state.text.trim(),
          'location_pincode': _pincode.text.trim(),
          'expense_acknowledged': _expenseAcknowledged,
          'notes': _notes.text.trim(),
          'birth_details': {
            'date_of_birth': prefs.getString('user_dob') ?? '',
            'time_of_birth': prefs.getString('user_tob') ?? '',
            'place_of_birth': prefs.getString('user_pob') ?? '',
          },
        },
      );
      final rawBooking = response['booking'];
      if (rawBooking is! Map) {
        throw const ApiException('Ritual booking response was invalid.');
      }
      final bookingId = int.tryParse(rawBooking['id']?.toString() ?? '');
      if (bookingId == null) {
        throw const ApiException('Ritual booking ID was missing.');
      }
      final payment = await _paymentService.createOrder(
        purpose: 'ritual',
        recordId: bookingId,
      );
      _pendingBookingId = bookingId;
      _razorpay.open({
        'key': payment.keyId,
        'amount': payment.amount,
        'currency': payment.currency,
        'name': 'Astrozura',
        'description': widget.item.title,
        'order_id': payment.orderId,
        'prefill': {
          'contact': _phone.text.trim(),
          'email': _email.text.trim(),
          'name': _name.text.trim(),
        },
        'theme': {'color': '#D4A73C'},
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack(error.toString());
    }
  }

  Future<void> _paymentSuccess(PaymentSuccessResponse response) async {
    final bookingId = _pendingBookingId;
    if (bookingId == null) return;
    try {
      await _paymentService.verifyPayment(
        purpose: 'ritual',
        recordId: bookingId,
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ritual booked successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack(error.toString());
    }
  }

  void _paymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _submitting = false);
    _snack(response.message ?? 'Payment was not completed.');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Book Your Ritual',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E3557),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                children: [
                  _field(_name, 'Devotee name', required: true),
                  _field(_email, 'Email', keyboard: TextInputType.emailAddress),
                  _field(_phone, 'Phone', required: true),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerField(
                          label: _date == null
                              ? 'Select date'
                              : '${_date!.day}/${_date!.month}/${_date!.year}',
                          icon: Icons.calendar_today_outlined,
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PickerField(
                          label: _time?.format(context) ?? 'Select time',
                          icon: Icons.schedule,
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _venue,
                    decoration: _decoration('Venue'),
                    items: const [
                      DropdownMenuItem(
                        value: 'online',
                        child: Text('Online'),
                      ),
                      DropdownMenuItem(
                        value: 'temple',
                        child: Text('Temple'),
                      ),
                      DropdownMenuItem(
                        value: 'client_place',
                        child: Text('My location'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _venue = value ?? 'online'),
                  ),
                  const SizedBox(height: 12),
                  LocationSearchField(
                    controller: _address,
                    hintText: 'Search ritual location',
                    onSelected: (selection) {
                      if (selection == null) return;
                      _address.text = selection.name;
                      if (_city.text.isEmpty) {
                        _city.text = selection.name.split(',').first.trim();
                      }
                    },
                    decoration: _decoration('Location'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(_city, 'City', required: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _field(_state, 'State', required: true)),
                    ],
                  ),
                  _field(_pincode, 'Pincode'),
                  _field(_notes, 'Notes', maxLines: 3),
                  if (_venue == 'client_place')
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _expenseAcknowledged,
                      onChanged: (value) => setState(
                        () => _expenseAcknowledged = value ?? false,
                      ),
                      title: const Text(
                        'I will cover priest travel and accommodation expenses.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D437B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Continue to Payment',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: _decoration(label),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? '$label is required'
                : null
            : null,
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE1E1E1)),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          prefixIcon: Icon(icon, size: 20),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3E7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFFD4A73C)),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class _TextSection extends StatelessWidget {
  final String title;
  final String text;

  const _TextSection({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.black54, height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _ListSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: Color(0xFFD4A73C),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingRitualImage extends StatelessWidget {
  const _MissingRitualImage();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF5EDDA),
      child: Center(
        child: Icon(
          Icons.local_fire_department_outlined,
          size: 56,
          color: Color(0xFFD4A73C),
        ),
      ),
    );
  }
}
