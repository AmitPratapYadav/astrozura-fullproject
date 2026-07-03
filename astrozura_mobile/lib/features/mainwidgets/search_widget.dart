// lib/screens/mainwidgets/global_search_widget.dart
//
// Drop-in replacement for SearchBarWidget on any screen.
// Shows a floating overlay with live results from both
// products AND astrologers. Tapping a result navigates
// to the correct detail screen.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/product/product.model.dart';
import '../../core/models/astrologer/astrologer_model.dart';
import '../../core/services/shop_service.dart';
import '../../core/services/astrologer_service.dart';
import '../../core/contants/app_colors.dart';

import '../shop/product_details_screen.dart';
import '../astrologer/screens/astrologer_detail_screen.dart';

class GlobalSearchWidget extends StatefulWidget {
  final VoidCallback? onFilterTap;
  final String hintText;

  const GlobalSearchWidget({
    super.key,
    this.onFilterTap,
    this.hintText = "Find an expert or product...",
  });

  @override
  State<GlobalSearchWidget> createState() => _GlobalSearchWidgetState();
}

class _GlobalSearchWidgetState extends State<GlobalSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  // ── Data pools ─────────────────────────────────────────────────────────────
  List<ProductModel> _allProducts = [];
  List<AstrologerModel> _allAstrologers = [];
  bool _dataLoaded = false;

  // ── Result state ───────────────────────────────────────────────────────────
  List<_SearchResult> _results = [];
  bool _showOverlay = false;
  bool _isSearching = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
    _preloadData();
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Preload both datasets once ─────────────────────────────────────────────
  Future<void> _preloadData() async {
    try {
      final results = await Future.wait([
        ShopService().getAllProducts(),
        AstrologerService.getAllAstrologers(),
      ]);
      _allProducts = results[0] as List<ProductModel>;
      _allAstrologers = (results[1] as List<Map<String, dynamic>>)
          .map((j) => AstrologerModel.fromJson(j))
          .toList();
      _dataLoaded = true;
    } catch (_) {}
  }

  // ── Focus handler ──────────────────────────────────────────────────────────
  void _onFocusChange() {
    if (_focusNode.hasFocus && _controller.text.isNotEmpty) {
      _showResults();
    } else if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), _hideResults);
    }
  }

  // ── Text change handler ────────────────────────────────────────────────────
  void _onTextChange() {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      _hideResults();
      setState(() => _results = []);
      return;
    }
    _runSearch(query);
  }

  // ── Search logic ───────────────────────────────────────────────────────────
  Future<void> _runSearch(String query) async {
    if (!_dataLoaded) {
      await _preloadData();
    }

    setState(() => _isSearching = true);
    final q = query.toLowerCase();

    final List<_SearchResult> found = [];

    // Products — match name, category, description
    for (final p in _allProducts) {
      if (p.name.toLowerCase().contains(q) ||
          (p.category?.toLowerCase().contains(q) ?? false) ||
          (p.description?.toLowerCase().contains(q) ?? false)) {
        found.add(_SearchResult.product(p));
        if (found.length >= 10) break;
      }
    }

    // Astrologers — match name, specialities, languages
    for (final a in _allAstrologers) {
      if (a.name.toLowerCase().contains(q) ||
          a.specialities.toLowerCase().contains(q) ||
          a.languages.toLowerCase().contains(q)) {
        found.add(_SearchResult.astrologer(a));
        if (found.length >= 15) break;
      }
    }

    setState(() {
      _results = found;
      _isSearching = false;
    });

    if (_focusNode.hasFocus) {
      _showResults();
    }
  }

  // ── Overlay management ─────────────────────────────────────────────────────
  void _showResults() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _showOverlay = true);
  }

  void _hideResults() {
    _removeOverlay();
    setState(() => _showOverlay = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _buildOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: _getSearchBarWidth(context),
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 56), // just below the 50px bar + 6px gap
            child: _SearchDropdown(
              results: _results,
              query: _controller.text.trim(),
              isSearching: _isSearching,
              onTap: _onResultTap,
              allAstrologers: _allAstrologers,
            ),
          ),
        );
      },
    );
  }

  double _getSearchBarWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 32.0; // 16 each side
    return (screenWidth - horizontalPadding).clamp(0, 500);
  }

  // ── Navigation on tap ──────────────────────────────────────────────────────
  void _onResultTap(_SearchResult result) {
    _controller.clear();
    _hideResults();
    _focusNode.unfocus();

    if (result.isProduct) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: result.product!),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AstrologerDetailScreen(
            astrologer: result.astrologer!,
            allAstrologers: _allAstrologers,
          ),
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 🔍 Icon
            const Icon(Icons.search, color: AppColors.accentGold),
            const SizedBox(width: 10),

            // ✍️ Input
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                cursorColor: AppColors.primaryBlue,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle:
                      const TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),

            // ❌ Clear
            if (_controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _controller.clear();
                  _hideResults();
                },
                child: const Icon(Icons.close,
                    color: Colors.grey, size: 18),
              ),

            if (_controller.text.isNotEmpty) const SizedBox(width: 8),

            // ⚙️ Filter
            GestureDetector(
              onTap: widget.onFilterTap,
              child: Icon(
                Icons.tune,
                color: widget.onFilterTap != null
                    ? AppColors.accentGold
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dropdown widget ────────────────────────────────────────────────────────────

class _SearchDropdown extends StatelessWidget {
  final List<_SearchResult> results;
  final String query;
  final bool isSearching;
  final ValueChanged<_SearchResult> onTap;
  final List<AstrologerModel> allAstrologers;

  const _SearchDropdown({
    required this.results,
    required this.query,
    required this.isSearching,
    required this.onTap,
    required this.allAstrologers,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black.withOpacity(0.12),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFFD4AF37).withOpacity(0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isSearching) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFD4AF37),
            ),
          ),
        ),
      );
    }

    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(Icons.search_off, color: Colors.grey.shade300, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No results for "$query"',
                style: const TextStyle(color: Colors.black45, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    // Group into products vs astrologers
    final products = results.where((r) => r.isProduct).toList();
    final astrologers = results.where((r) => !r.isProduct).toList();

    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      children: [
        if (products.isNotEmpty) ...[
          _sectionHeader('Products', Icons.shopping_bag_outlined),
          ...products.map((r) => _ProductTile(result: r, query: query, onTap: onTap)),
        ],
        if (astrologers.isNotEmpty) ...[
          if (products.isNotEmpty) const Divider(height: 1),
          _sectionHeader('Experts', Icons.person_search_outlined),
          ...astrologers.map((r) => _AstrologerTile(result: r, query: query, onTap: onTap)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFFD4AF37)),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: const Color(0xFFD4AF37),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product tile ──────────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  final _SearchResult result;
  final String query;
  final ValueChanged<_SearchResult> onTap;

  const _ProductTile({
    required this.result,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = result.product!;
    return InkWell(
      onTap: () => onTap(result),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 46,
                height: 46,
                child: p.images[0].contains('placeholder')
                    ? Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey, size: 22),
                      )
                    : Image.network(
                        p.images[0],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.image_not_supported,
                              color: Colors.grey, size: 22),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightText(
                      text: p.name, query: query, fontSize: 14),
                  if (p.category != null)
                    Text(
                      p.category!,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black45),
                    ),
                ],
              ),
            ),

            // Price
            Text(
              '₹${p.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD4AF37),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Astrologer tile ───────────────────────────────────────────────────────────

class _AstrologerTile extends StatelessWidget {
  final _SearchResult result;
  final String query;
  final ValueChanged<_SearchResult> onTap;

  const _AstrologerTile({
    required this.result,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final a = result.astrologer!;
    return InkWell(
      onTap: () => onTap(result),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 23,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: a.profileImage.isNotEmpty
                  ? NetworkImage(a.profileImage)
                  : null,
              child: a.profileImage.isEmpty
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightText(
                      text: a.name, query: query, fontSize: 14),
                  Text(
                    a.specialityList.take(2).join(' · '),
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black45),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Rating
            Row(
              children: [
                const Icon(Icons.star,
                    size: 13, color: Colors.orange),
                const SizedBox(width: 2),
                Text(
                  a.rating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Highlight matching text ────────────────────────────────────────────────────

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final double fontSize;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text,
          style: TextStyle(
              fontSize: fontSize, fontWeight: FontWeight.w500));
    }

    final lower = text.toLowerCase();
    final qLower = query.toLowerCase();
    final index = lower.indexOf(qLower);

    if (index == -1) {
      return Text(text,
          style: TextStyle(
              fontSize: fontSize, fontWeight: FontWeight.w500));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: Colors.black87),
        children: [
          if (index > 0)
            TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: const TextStyle(
              backgroundColor: Color(0xFFFFF3CD),
              color: Color(0xFF8B6914),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (index + query.length < text.length)
            TextSpan(
                text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}

// ── Result model ──────────────────────────────────────────────────────────────

class _SearchResult {
  final ProductModel? product;
  final AstrologerModel? astrologer;

  bool get isProduct => product != null;

  const _SearchResult.product(ProductModel p)
      : product = p,
        astrologer = null;

  const _SearchResult.astrologer(AstrologerModel a)
      : astrologer = a,
        product = null;
}