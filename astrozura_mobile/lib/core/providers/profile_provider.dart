import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../contants/api_constants.dart';
import '../services/api_client.dart';
import '../services/auth_services.dart';

class ProfileProvider extends ChangeNotifier {
  String name = 'User';
  String phone = '';
  String? avatarUrl;
  bool hasBirthDetails = false;
  bool loading = false;

  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    try {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        final response = await ApiClient().get(
          ApiConstants.getProfile,
          auth: true,
        );
        final raw = response['data'] ?? response['user'];
        if (raw is Map) {
          await _saveServerProfile(
            prefs,
            Map<String, dynamic>.from(raw),
          );
        }
      }
    } catch (_) {
      // Cached profile remains available while offline.
    }
    _readPrefs(prefs);
    loading = false;
    notifyListeners();
  }

  Future<void> applyServerProfile(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveServerProfile(prefs, user);
    _readPrefs(prefs);
    notifyListeners();
  }

  Future<void> _saveServerProfile(
    SharedPreferences prefs,
    Map<String, dynamic> user,
  ) async {
    Future<void> setString(String key, dynamic value) async {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, text);
      }
    }

    await setString('user_name', user['name']);
    await setString('user_phone', user['phone']);
    await setString('user_email', user['email']);
    await setString('user_gender', user['gender']);
    await setString(
      'user_dob',
      user['date_of_birth'] ?? user['dob'],
    );
    await setString(
      'user_tob',
      user['time_of_birth'] ?? user['tob'],
    );
    await setString(
      'user_pob',
      user['place_of_birth'] ?? user['pob'],
    );
    final avatar = user['profile_image'] ?? user['avatar'];
    final avatarValue = avatar?.toString().trim() ?? '';
    if (avatarValue.isNotEmpty) {
      await prefs.setString(
        'user_avatar',
        ApiConstants.storageUrl(avatarValue),
      );
    }

    final lat = double.tryParse(user['latitude']?.toString() ?? '');
    final lng = double.tryParse(user['longitude']?.toString() ?? '');
    if (lat != null) await prefs.setDouble('user_pob_lat', lat);
    if (lng != null) await prefs.setDouble('user_pob_lng', lng);
  }

  void _readPrefs(SharedPreferences prefs) {
    name = (prefs.getString('user_name') ?? '').trim();
    if (name.isEmpty) name = 'User';
    phone = prefs.getString('user_phone') ?? '';
    final avatar = (prefs.getString('user_avatar') ?? '').trim();
    avatarUrl = avatar.isEmpty ? null : avatar;
    hasBirthDetails = (prefs.getString('user_dob') ?? '').trim().isNotEmpty &&
        (prefs.getString('user_tob') ?? '').trim().isNotEmpty &&
        (prefs.getString('user_pob') ?? '').trim().isNotEmpty &&
        prefs.getDouble('user_pob_lat') != null &&
        prefs.getDouble('user_pob_lng') != null;
    prefs.setBool('has_birth_details', hasBirthDetails);
  }
}
