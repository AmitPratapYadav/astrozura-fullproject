import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/puja_anusthan/puja_anusthan_model.dart';
import '../../core/services/api_services.dart';
import '../main_navigation.dart';
import '../mainwidgets/header.dart';
import 'puja_anusthan_detail_screen.dart';
import 'widgets/puja_card.dart';

class PoojaAnusthanScreen extends StatefulWidget {
  const PoojaAnusthanScreen({super.key});

  @override
  State<PoojaAnusthanScreen> createState() => _PoojaAnusthanScreenState();
}

class _PoojaAnusthanScreenState extends State<PoojaAnusthanScreen> {
  List<PujaItem> _rituals = [];
  bool _loading = true;
  String? _error;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.getRituals();
      final rituals = response
          .whereType<Map>()
          .map((item) => PujaItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      if (!mounted) return;
      setState(() {
        _rituals = rituals;
        if (_selectedCategory != 'All' &&
            !rituals.any((item) => _categoryOf(item) == _selectedCategory)) {
          _selectedCategory = 'All';
        }
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _precacheInitialImages(rituals);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _goBack() {
    MainNavigationState.returnHome(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFFF5EDDA)],
                begin: Alignment.topCenter,
                end: Alignment.center,
              ),
            ),
            child: Column(
              children: [
                const HeaderWidget(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _goBack,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      Expanded(
                        child: Text(
                          'Sacred Pooja Anusthan',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E3557),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _buildBody(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        children: const [
          SizedBox(height: 180),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.black26),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }
    if (_rituals.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 160),
          Center(child: Text('No rituals are available right now.')),
        ],
      );
    }

    final rituals = _filteredRituals;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _categoryFilters()),
        if (rituals.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No rituals found in this category.')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            sliver: SliverGrid.builder(
              itemCount: rituals.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                childAspectRatio: 0.70,
              ),
              itemBuilder: (context, index) {
                final item = rituals[index];
                return PujaCard(
                  item: item,
                  onBookNow: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PujaAnusthanDetailScreen(item: item),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  List<PujaItem> get _filteredRituals {
    if (_selectedCategory == 'All') return _rituals;
    return _rituals
        .where((item) => _categoryOf(item) == _selectedCategory)
        .toList();
  }

  List<String> get _categories {
    final values = _rituals
        .map(_categoryOf)
        .where((item) => item.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...values];
  }

  String _categoryOf(PujaItem item) {
    final tag = item.tag.trim();
    return tag.isEmpty ? 'Pooja' : tag;
  }

  Widget _categoryFilters() {
    final categories = _categories;
    if (categories.length <= 1) return const SizedBox(height: 4);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final active = category == _selectedCategory;
          return ChoiceChip(
            label: Text(category),
            selected: active,
            onSelected: (_) => setState(() => _selectedCategory = category),
            selectedColor: const Color(0xFFD4A84F),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: active ? const Color(0xFFD4A84F) : const Color(0xFFE5D8B8),
            ),
            labelStyle: TextStyle(
              color: active ? const Color(0xFF1E3557) : Colors.black87,
              fontWeight: FontWeight.w800,
            ),
          );
        },
      ),
    );
  }

  void _precacheInitialImages(List<PujaItem> rituals) {
    for (final ritual in rituals.take(8)) {
      final image = ritual.imageAsset.trim();
      if (image.startsWith('http://') || image.startsWith('https://')) {
        precacheImage(NetworkImage(image), context).catchError((_) {});
      }
    }
  }
}
