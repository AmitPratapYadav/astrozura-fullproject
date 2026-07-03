  // lib/providers/spotlight_provider.dart
  //
  // Usage in main.dart:
  //   ChangeNotifierProvider(create: (_) => SpotlightProvider()),
  //
  // Usage in any widget:
  //   context.read<SpotlightProvider>().init(token);

  import 'package:flutter/foundation.dart';
  import '../models/astrologer/astrologer_model.dart';
  import '../services/astrologer_service.dart';

  class SpotlightProvider extends ChangeNotifier {
    // ── State ──────────────────────────────────────────────────────────────
    List<AstrologerModel> _astrologers = [];
    Set<int> _wishlistedIds = {};
    bool _isLoading = false;
    String? _error;
    String? _token; // Sanctum token; null if guest user

    // ── Getters ────────────────────────────────────────────────────────────
    List<AstrologerModel> get astrologers => _astrologers;
    bool get isLoading => _isLoading;
    String? get error => _error;

    bool isWishlisted(int astrologerId) =>
        _wishlistedIds.contains(astrologerId);

    // ── Init: call once after auth token is known ──────────────────────────
    Future<void> init({String? token}) async {
      _token = token;
      await _loadFeatured();
      if (_token != null) await _loadWishlist();
    }

    // ── Load featured astrologers from GET /astrologers ───────────────────
    Future<void> _loadFeatured() async {
      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        final raw = await AstrologerService.getFeaturedAstrologers();
        _astrologers =
            raw.map((json) => AstrologerModel.fromJson(json)).toList();
      } catch (e) {
        _error = e.toString();
        debugPrint('SpotlightProvider._loadFeatured: $_error');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }

    // ── Load wishlist from GET /dashboard/wishlist ─────────────────────────
    Future<void> _loadWishlist() async {
      try {
        _wishlistedIds =
            await AstrologerService.getWishlistedIds(_token!);
        notifyListeners();
      } catch (e) {
        // Wishlist failure is non-critical; swallow silently
        debugPrint('SpotlightProvider._loadWishlist: $e');
      }
    }

    // ── Toggle wishlist via POST /dashboard/wishlist/toggle ────────────────
    Future<void> toggleWishlist(int astrologerId) async {
      if (_token == null) {
        // Caller should show a "please login" message
        throw Exception('not_authenticated');
      }

      // Optimistic update
      final wasWishlisted = _wishlistedIds.contains(astrologerId);
      if (wasWishlisted) {
        _wishlistedIds.remove(astrologerId);
      } else {
        _wishlistedIds.add(astrologerId);
      }
      notifyListeners();

      try {
        final nowWishlisted = await AstrologerService.toggleWishlist(
          token: _token!,
          astrologerId: astrologerId,
        );

        // Sync with server truth
        if (nowWishlisted) {
          _wishlistedIds.add(astrologerId);
        } else {
          _wishlistedIds.remove(astrologerId);
        }
        notifyListeners();
      } catch (e) {
        // Rollback optimistic update on failure
        if (wasWishlisted) {
          _wishlistedIds.add(astrologerId);
        } else {
          _wishlistedIds.remove(astrologerId);
        }
        notifyListeners();
        rethrow;
      }
    }

    /// Call this when user logs out so wishlist state is cleared
    void clearSession() {
      _token = null;
      _wishlistedIds = {};
      notifyListeners();
    }
  }