// lib/screens/astrologer/astrologer_screen.dart
//
// Updated: SearchBarWidget wired for live search + filter bottom sheet.
// Filter sheet lets user pick speciality AND sort (rating / experience).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/contants/app_colors.dart';
import '../../../core/services/astrologer_service.dart';
import '../../../core/models/astrologer/astrologer_model.dart';
import '../../mainwidgets/header.dart';
import '../../mainwidgets/search_widget.dart';
import '../widgets/astrologer_card.dart';
import '../widgets/spotlight_section.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/spotlight_provider.dart';

class AstrologerScreen extends StatefulWidget {
  const AstrologerScreen({super.key});

  @override
  State<AstrologerScreen> createState() => _AstrologerScreenState();
}

class _AstrologerScreenState extends State<AstrologerScreen> {
  final AstrologerService _service = AstrologerService();

  List<AstrologerModel> _allAstrologers = [];
  List<AstrologerModel> _filteredList = [];

  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All'; // speciality chip filter
  String _searchQuery = '';
  String _selectedSort = 'Default'; // ← NEW: sort option from filter sheet
  int _currentPage = 1;
  static const int _itemsPerPage = 3;

  final List<String> _filters = ['All', 'Vedic', 'Tarot', 'Palmist'];

  // All unique specialities extracted from loaded astrologers — used in sheet
  List<String> get _allSpecialities {
    final Set<String> specs = {'All'};
    for (final a in _allAstrologers) {
      specs.addAll(a.specialityList);
    }
    return specs.toList();
  }

  // ── Pagination ─────────────────────────────────────────────────────────────
  int get _totalPages =>
      (_filteredList.length / _itemsPerPage).ceil().clamp(1, 999);

  List<AstrologerModel> get _paginatedList {
    if (_filteredList.isEmpty) return [];
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredList.length);
    if (start >= _filteredList.length) return [];
    return _filteredList.sublist(start, end);
  }

  AstrologerModel? get _featured {
    if (_allAstrologers.isEmpty) return null;
    return _allAstrologers.firstWhere(
      (a) => a.isFeatured,
      orElse: () => _allAstrologers.first,
    );
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchAstrologers();
    Future.microtask(() => _initProvider());
  }

  Future<void> _initProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    await context.read<SpotlightProvider>().init(token: token);
  }

  Future<void> _fetchAstrologers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rawList = await AstrologerService.getAllAstrologers();
      final parsedList =
          rawList.map((json) => AstrologerModel.fromJson(json)).toList();

      setState(() {
        _allAstrologers = parsedList;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Core filter + search + sort engine ─────────────────────────────────────

  void _applyFilters() {
    setState(() {
      _currentPage = 1;

      // 1. Category / speciality chip
      List<AstrologerModel> list = _selectedFilter == 'All'
          ? [..._allAstrologers]
          : _allAstrologers.where((a) {
              return a.specialityList.any(
                (s) => s.toLowerCase().contains(
                      _selectedFilter.toLowerCase(),
                    ),
              );
            }).toList();

      // 2. Search query
      if (_searchQuery.isNotEmpty) {
        list = list.where((a) {
          return a.name.toLowerCase().contains(_searchQuery) ||
              a.specialities.toLowerCase().contains(_searchQuery) ||
              a.languages.toLowerCase().contains(_searchQuery);
        }).toList();
      }

      // 3. Sort
      switch (_selectedSort) {
        case 'Top Rated':
          list.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'Most Experienced':
          list.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
          break;
        case 'Price: Low to High':
          list.sort((a, b) => a.chatPrice.compareTo(b.chatPrice));
          break;
        case 'Price: High to Low':
          list.sort((a, b) => b.chatPrice.compareTo(a.chatPrice));
          break;
        default:
          break;
      }

      _filteredList = list;
    });
  }

  void _applyFilter(String category) {
    _selectedFilter = category;
    _applyFilters();
  }

  void _onSearch(String value) {
    _searchQuery = value.toLowerCase().trim();
    _applyFilters();
  }

  // ── Filter Bottom Sheet ────────────────────────────────────────────────────

  void _showFilterSheet() {
    String tempSpeciality = _selectedFilter;
    String tempSort = _selectedSort;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Handle ───────────────────────────────────────
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Title ────────────────────────────────────────
                  Text(
                    'Filter Experts',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E2E5D),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Speciality ───────────────────────────────────
                  Text(
                    'SPECIALITY',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _allSpecialities.map((spec) {
                      final isSelected = spec == tempSpeciality;
                      return GestureDetector(
                        onTap: () => setSheetState(() => tempSpeciality = spec),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFD4A73A)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            spec,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // ── Sort ─────────────────────────────────────────
                  Text(
                    'SORT BY',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      'Default',
                      'Top Rated',
                      'Most Experienced',
                      'Price: Low to High',
                      'Price: High to Low',
                    ].map((sort) {
                      final isSelected = sort == tempSort;
                      return GestureDetector(
                        onTap: () => setSheetState(() => tempSort = sort),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2E2E5D)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            sort,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // ── Actions ───────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              tempSpeciality = 'All';
                              tempSort = 'Default';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFD4A73A)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(color: Color(0xFFD4A73A)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = tempSpeciality;
                              _selectedSort = tempSort;
                            });
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4A73A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, AppColors.goldLight],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchAstrologers,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // ── HEADER ────────────────────────────────────────
                  const HeaderWidget(),
                  const SizedBox(height: 20),

                  // ── TITLE ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Chat or Call with Trusted Astrologers',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFB38A2E),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── SEARCH ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: GlobalSearchWidget(
                          hintText: "Search by name or speciality...",
                          // onChanged: _onSearch,           // ← live search
                          // onSubmitted: _onSearch,         // ← keyboard enter
                          onFilterTap: _showFilterSheet, // ← filter sheet
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── ACTIVE FILTER INDICATOR ───────────────────────
                  if (_selectedFilter != 'All' || _selectedSort != 'Default')
                    _buildActiveFilterRow(),

                  const SizedBox(height: 8),

                  // ── FILTER CHIPS ──────────────────────────────────
                  const SizedBox(height: 20),

                  // ── CONTENT ───────────────────────────────────────
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _buildError()
                  else if (_allAstrologers.isEmpty)
                    _buildEmpty()
                  else ...[
                    // SPOTLIGHT
                    if (_featured != null)
                      SpotlightSection(
                        astrologer: _featured!,
                      ),

                    const SizedBox(height: 20),

                    // SECTION TITLE
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Top Rated Astrologers',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E2E5D),
                            ),
                          ),
                          Text(
                            'Showing ${_filteredList.length}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    // LIST
                    if (_filteredList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.person_search,
                                  size: 52, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No experts found for "$_searchQuery"'
                                    : 'No astrologers found for this filter.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black45),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        itemCount: _paginatedList.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 10),
                        itemBuilder: (context, index) {
                          final astrologer = _paginatedList[index];
                          return AstrologerCard(
                            astrologer: astrologer,
                            allAstrologers: _allAstrologers,
                          );
                        },
                      ),

                    const SizedBox(height: 20),

                    // PAGINATION
                    _buildPagination(),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Active filter chips row ────────────────────────────────────────────────
  Widget _buildActiveFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (_selectedFilter != 'All')
            _filterChip(
              label: _selectedFilter,
              onRemove: () {
                setState(() => _selectedFilter = 'All');
                _applyFilters();
              },
            ),
          if (_selectedSort != 'Default')
            _filterChip(
              label: _selectedSort,
              onRemove: () {
                setState(() => _selectedSort = 'Default');
                _applyFilters();
              },
            ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4A73A).withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8B6914),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Color(0xFF8B6914)),
          ),
        ],
      ),
    );
  }

  // ── WIDGETS ────────────────────────────────────────────────────────────────

  Widget _buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;

          return GestureDetector(
            onTap: () => _applyFilter(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFD4A73A)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(25),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(_totalPages, (index) {
          final page = index + 1;
          final isActive = page == _currentPage;
          return GestureDetector(
            onTap: () => setState(() => _currentPage = page),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                        )
                      ]
                    : [],
              ),
              child: Text(
                page.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.black : Colors.grey,
                ),
              ),
            ),
          );
        }),
        if (_currentPage < _totalPages)
          GestureDetector(
            onTap: () => setState(() => _currentPage++),
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.arrow_forward_ios, size: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.wifi_off, size: 52, color: Colors.black26),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Failed to load astrologers.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black45, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchAstrologers,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.person_search, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'No astrologers found.\nCheck your connection or try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchAstrologers,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
