// lib/services/address_service.dart
//
// Persists delivery addresses locally in SharedPreferences under the
// logged-in user's ID so each user sees only their own saved addresses.
//
// Key used:  "addresses_<userId>"  →  JSON array of SavedAddress objects
//
// No backend address table exists; the selected address string is sent
// to the orders table via shipping_address on order placement.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ── Model ─────────────────────────────────────────────────────────────────────
class SavedAddress {
  final String id;        // local UUID
  final String label;     // Home | Work | Other
  final String name;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String pincode;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
  });

  /// Full single-line address string stored in orders.shipping_address
  String get fullAddress =>
      '$street, $city, $state - $pincode';

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'name': name,
        'phone': phone,
        'street': street,
        'city': city,
        'state': state,
        'pincode': pincode,
      };

  factory SavedAddress.fromJson(Map<String, dynamic> j) => SavedAddress(
        id: j['id'] as String,
        label: j['label'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String,
        street: j['street'] as String,
        city: j['city'] as String,
        state: j['state'] as String,
        pincode: j['pincode'] as String,
      );

  SavedAddress copyWith({
    String? id,
    String? label,
    String? name,
    String? phone,
    String? street,
    String? city,
    String? state,
    String? pincode,
  }) =>
      SavedAddress(
        id: id ?? this.id,
        label: label ?? this.label,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        street: street ?? this.street,
        city: city ?? this.city,
        state: state ?? this.state,
        pincode: pincode ?? this.pincode,
      );
}

// ── Service ───────────────────────────────────────────────────────────────────
class AddressService {
  static const String _keyPrefix = 'addresses_';

  /// SharedPreferences key scoped to the current user.
  Future<String> _key() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'guest';
    return '$_keyPrefix$userId';
  }

  // ── Load all saved addresses for this user ───────────────────────────────
  Future<List<SavedAddress>> loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => SavedAddress.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Save (add or update) a single address ────────────────────────────────
  Future<List<SavedAddress>> saveAddress(SavedAddress address) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key();
    final list = await loadAddresses();

    final idx = list.indexWhere((a) => a.id == address.id);
    if (idx >= 0) {
      list[idx] = address;
    } else {
      list.add(address);
    }

    await prefs.setString(key, jsonEncode(list.map((e) => e.toJson()).toList()));
    return list;
  }

  // ── Delete an address by id ──────────────────────────────────────────────
  Future<List<SavedAddress>> deleteAddress(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key();
    final list = await loadAddresses();
    list.removeWhere((a) => a.id == id);
    await prefs.setString(key, jsonEncode(list.map((e) => e.toJson()).toList()));
    return list;
  }

  // ── Generate a simple local unique ID ────────────────────────────────────
  static String generateId() =>
      'addr_${DateTime.now().millisecondsSinceEpoch}';
}