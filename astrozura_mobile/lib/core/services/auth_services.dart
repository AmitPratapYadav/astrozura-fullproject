// lib/core/services/auth_service.dart

import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../contants/api_constants.dart';

class AuthService {
  // ── Change this to your machine's LAN IP when testing on a real device ──
  // Emulator    → 10.0.2.2
  // Real device → 192.168.x.x  (same network as the Laravel server)

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static bool _googleInitialized = false;

  // ── TOKEN / SESSION HELPERS ───────────────────────────────────────────────

  /// Persists the Sanctum token and key user fields to SharedPreferences.
  static Future<void> saveToken(
    String token,
    Map<String, dynamic> user, {
    String fallbackEmail = '',
    String fallbackPhone = '',
    Map<String, dynamic>? astrologer,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_json', jsonEncode(user));
    await prefs.setString('user_id', user['id']?.toString() ?? '');
    await prefs.setString('user_name', user['name']?.toString() ?? '');
    await prefs.setString(
      'user_email',
      user['email']?.toString() ?? fallbackEmail,
    );
    await prefs.setString(
      'user_phone',
      user['phone']?.toString() ?? fallbackPhone,
    );
    // role is 'user' | 'astrologer' | 'admin'
    await prefs.setString('user_role', user['role']?.toString() ?? 'user');
    await prefs.setBool(
        'is_profile_complete', user['is_profile_complete'] == true);
    final avatar = user['profile_image'] ?? user['avatar'];
    if (avatar != null && avatar.toString().trim().isNotEmpty) {
      await prefs.setString(
        'user_avatar',
        ApiConstants.storageUrl(avatar.toString()),
      );
    }

    if (astrologer != null && astrologer.isNotEmpty) {
      await prefs.setString('astrologer_json', jsonEncode(astrologer));
    } else if (user['role']?.toString() == 'astrologer') {
      await prefs.setString('astrologer_json', jsonEncode(user));
    } else {
      await prefs.remove('astrologer_json');
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, dynamic>> getSavedAstrologer() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAstrologer = prefs.getString('astrologer_json');
    final savedUser = prefs.getString('user_json');

    for (final raw in [savedAstrologer, savedUser]) {
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // Ignore bad local cache and fall back to basic saved fields.
      }
    }

    return {
      'id': prefs.getString('user_id') ?? '',
      'name': prefs.getString('user_name') ?? 'Astrologer',
      'email': prefs.getString('user_email') ?? '',
    };
  }

  static Map<String, dynamic> _decodeMap(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  /// Clears all stored session data.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_json');
    await prefs.remove('astrologer_json');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_phone');
    await prefs.remove('user_role');
    await prefs.remove('is_profile_complete');
    await prefs.remove('user_avatar');
    await prefs.remove('has_birth_details');
    await prefs.remove('member_tier');
    await prefs.remove('token');
    await prefs.remove('astrologer_data');
  }

  Future<Map<String, dynamic>> sendOtp(String identifier) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.sendOtp),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'identifier': identifier,
        }),
      );

      print("OTP STATUS : ${response.statusCode}");
      print("OTP BODY : ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'dev_otp': data['dev_otp']?.toString() ?? '',
          'message': data['message'] ?? 'OTP Sent',
        };
      }

      return {
        'success': false,
        'message': 'Server Error ${response.statusCode}',
      };
    } catch (e) {
      print("OTP ERROR : $e");

      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> verifyOtp(
    String identifier,
    String otp,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'identifier': identifier,
          'otp': otp,
        }),
      );

      print("VERIFY STATUS : ${response.statusCode}");
      print("VERIFY BODY : ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = Map<String, dynamic>.from(data['user']);

        await saveToken(
          data['token'],
          user,
          fallbackPhone: identifier,
        );

        return {
          'success': true,
          'role': user['role'],
          'message': data['message'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Invalid OTP',
      };
    } catch (e) {
      print("VERIFY ERROR : $e");

      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // ── PASSWORD LOGIN (user) ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> loginWithPassword(
      String email, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse(ApiConstants.loginPassword),
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && data['success'] == true) {
        final user = _asMap(data['user']);
        final token = data['token']?.toString() ?? '';
        final role = user['role']?.toString() ?? 'user';

        await saveToken(token, user, fallbackEmail: email);

        return {
          'success': true,
          'role': role,
          'astrologer': role == 'astrologer' ? user : null,
          'is_new_user': data['is_new_user'] == true,
          'message': data['message'] ?? 'Logged in successfully',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Invalid email or password.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check connection.'};
    }
  }

  // ── REGISTER ──────────────────────────────────────────────────────────────
  // POST /api/register  →  { firstName, lastName, email, password }
  // New users always get role = 'user' from the backend.
  //
  // Returns:
  //   { success, role, message }
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      await _initializeGoogleSignIn();

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        return {
          'success': false,
          'message': 'Google Sign-In is not supported on this device.',
        };
      }

      final account = await _authenticateGoogle();
      final idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        return {
          'success': false,
          'message':
              'Google did not return an ID token. Add this app package and SHA fingerprints in Google Console.',
        };
      }

      final res = await http
          .post(
            Uri.parse(ApiConstants.googleMobileAuth),
            headers: _headers,
            body: jsonEncode({'id_token': idToken}),
          )
          .timeout(const Duration(seconds: 20));

      final data = _decodeMap(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        final user = _asMap(data['user']);
        final token = data['token']?.toString() ?? '';

        await saveToken(token, user, fallbackEmail: account.email);

        return {
          'success': true,
          'role': user['role']?.toString() ?? 'user',
          'is_new_user': data['is_new_user'] == true,
          'message': data['message'] ?? 'Logged in successfully',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Google login failed.',
      };
    } on GoogleSignInException catch (e) {
      final message = switch (e.code) {
        GoogleSignInExceptionCode.canceled => 'Google login was cancelled.',
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          'Google login is not configured for this app signature.',
        GoogleSignInExceptionCode.uiUnavailable =>
          'Google login could not open on this device.',
        _ => e.description ?? 'Google login failed. Please try again.',
      };
      return {
        'success': false,
        'message': message,
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Google login failed. Check connection and Google setup.',
      };
    }
  }

  static Future<void> _initializeGoogleSignIn() async {
    if (_googleInitialized) return;

    const googleClientId = String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
      defaultValue:
          '293217412841-tdhdv9p3fukeq7137gat8l4nm8u8ijn3.apps.googleusercontent.com',
    );

    await GoogleSignIn.instance.initialize(
      serverClientId:
          googleClientId.trim().isEmpty ? null : googleClientId.trim(),
    );

    _googleInitialized = true;
  }

  static Future<GoogleSignInAccount> _authenticateGoogle() async {
    try {
      return await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
    } on GoogleSignInException catch (error) {
      final retryable = error.code == GoogleSignInExceptionCode.unknownError ||
          error.code == GoogleSignInExceptionCode.interrupted ||
          error.code == GoogleSignInExceptionCode.userMismatch;
      if (!retryable) rethrow;

      await GoogleSignIn.instance.signOut();
      return GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
    }
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse(ApiConstants.register),
            headers: _headers,
            body: jsonEncode({
              'firstName': firstName,
              'lastName': lastName,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          data['success'] == true) {
        final user = _asMap(data['user']);
        final token = data['token']?.toString() ?? '';

        await saveToken(token, user, fallbackEmail: email);

        return {
          'success': true,
          'role': user['role']?.toString() ?? 'user',
          'message': data['message'] ?? 'Registered successfully',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Registration failed.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error. Check connection.'};
    }
  }

  // ── ASTROLOGER LOGIN ──────────────────────────────────────────────────────
  // POST /api/astrologer/login  →  { email, password }
  // Backend enforces role === 'astrologer' and returns 403 otherwise.
  //
  // Returns:
  //   { success, role, message }

  // ── SERVER-SIDE LOGOUT ────────────────────────────────────────────────────
  // POST /api/logout  (requires Bearer token)
  // Revokes the current Sanctum token on the server, then clears local prefs.
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String gender,
    required String dob,
    required String tob,
    required String pob,
    double? latitude,
    double? longitude,
    String? profileImagePath,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'message': 'Please login again to update your profile.',
      };
    }

    final payload = <String, dynamic>{
      'name': name,
    };
    if (email.isNotEmpty) payload['email'] = email;
    if (gender.isNotEmpty) payload['gender'] = gender;
    if (dob.isNotEmpty) {
      payload['date_of_birth'] = dob;
      payload['dob'] = dob;
    }
    if (tob.isNotEmpty) {
      payload['time_of_birth'] = tob;
      payload['tob'] = tob;
    }
    if (pob.isNotEmpty) {
      payload['place_of_birth'] = pob;
      payload['pob'] = pob;
    }
    if (latitude != null) payload['latitude'] = latitude;
    if (longitude != null) payload['longitude'] = longitude;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.updateProfile),
      );
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      payload.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });
      if (profileImagePath != null && profileImagePath.trim().isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            profileImagePath,
          ),
        );
      }

      final streamed =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final data = _decodeMap(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final rawUser = data['data'] ?? data['user'];
        final user =
            rawUser is Map<String, dynamic> ? rawUser : <String, dynamic>{};

        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully.',
          'user': user,
        };
      }

      return {
        'success': false,
        'message': data['message'] ??
            'Profile update failed (${response.statusCode}).',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Cannot reach server. Profile was not updated.',
      };
    }
  }

  Future<void> serverLogout() async {
    try {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        await http.post(
          Uri.parse(ApiConstants.logout),
          headers: {
            ..._headers,
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));
      }
    } catch (_) {
      // Swallow — local logout still proceeds below
    } finally {
      await logout(); // clear SharedPreferences
    }
  }

  Future<void> revokeToken(String token) async {
    try {
      await http.post(
        Uri.parse(ApiConstants.logout),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // Local logout is authoritative when the network is unavailable.
    }
  }
}
