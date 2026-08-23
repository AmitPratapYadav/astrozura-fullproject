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
  final bool palmReadingOnly;

  const AstrologerScreen({super.key, this.palmReadingOnly = false});

  @override
  State<AstrologerScreen> createState() => _AstrologerScreenState();
}

class _AstrologerScreenState extends State<AstrologerScreen> {
  List<AstrologerModel> _allAstrologers = [];
  List<AstrologerModel> _filteredList = [];

  bool _isLoading = true;
  String? _error;
  late String _selectedFilter; // speciality chip filter
  String _searchQuery = '';
  String _selectedSort = 'Default'; // ← NEW: sort option from filter sheet
  String _selectedLanguage = 'All';
  String _selectedConsultation = 'All';
  String _selectedAvailability = 'All';
  int _currentPage = 1;
  static const int _itemsPerPage = 3;

  // All unique specialities extracted from loaded astrologers — used in sheet
  List<String> get _allSpecialities {
    final Set<String> specs = {'All'};
    for (final a in _allAstrologers) {
      specs.addAll(a.specialityList);
    }
    return specs.toList();
  }

  List<String> get _allLanguages {
    final Set<String> languages = {'All'};
    for (final a in _allAstrologers) {
      languages.addAll(a.languageList);
    }
    return languages.toList();
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
    _selectedFilter = widget.palmReadingOnly ? 'Palm Reading' : 'All';
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
      List<AstrologerModel> list = widget.palmReadingOnly
          ? _allAstrologers.where((a) => a.isPalmReadingExpert).toList()
          : _selectedFilter == 'All'
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

      if (_selectedLanguage != 'All') {
        list = list
            .where((a) => a.languageList.any((language) =>
                language.toLowerCase() == _selectedLanguage.toLowerCase()))
            .toList();
      }

      if (_selectedConsultation == 'Chat') {
        list = list.where((a) => a.supportsChat).toList();
      } else if (_selectedConsultation == 'Call') {
        list = list.where((a) => a.supportsCall).toList();
      }

      if (_selectedAvailability == 'Available') {
        list = list
            .where((a) =>
                a.availabilityLabel == 'Available' && !a.isBusy && a.isOnline)
            .toList();
      } else if (_selectedAvailability == 'Busy') {
        list = list.where((a) => a.availabilityLabel == 'Busy').toList();
      } else if (_selectedAvailability == 'Offline') {
        list = list.where((a) => a.availabilityLabel == 'Offline').toList();
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

  void _onSearch(String value) {
    _searchQuery = value.toLowerCase().trim();
    _applyFilters();
  }

  // ── Filter Bottom Sheet ────────────────────────────────────────────────────

  void _showFilterSheet() {
    String tempSpeciality = _selectedFilter;
    String tempSort = _selectedSort;
    String tempLanguage = _selectedLanguage;
    String tempConsultation = _selectedConsultation;
    String tempAvailability = _selectedAvailability;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
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
                          onTap: () =>
                              setSheetState(() => tempSpeciality = spec),
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
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // ── Sort ─────────────────────────────────────────
                    Text(
                      'LANGUAGE',
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
                      children: _allLanguages.take(14).map((language) {
                        final isSelected = language == tempLanguage;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => tempLanguage = language),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1E3557)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              language,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'CONSULTATION',
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
                      children: ['All', 'Chat', 'Call'].map((type) {
                        final isSelected = type == tempConsultation;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => tempConsultation = type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF5B63D3)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'AVAILABILITY',
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
                      children:
                          ['All', 'Available', 'Busy', 'Offline'].map((status) {
                        final isSelected = status == tempAvailability;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => tempAvailability = status),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0F9F6E)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

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
                                color:
                                    isSelected ? Colors.white : Colors.black87,
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
                                tempLanguage = 'All';
                                tempConsultation = 'All';
                                tempAvailability = 'All';
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
                                _selectedLanguage = tempLanguage;
                                _selectedConsultation = tempConsultation;
                                _selectedAvailability = tempAvailability;
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
                      widget.palmReadingOnly
                          ? 'Palm Reading Experts'
                          : 'Chat or Call with Trusted Astrologers',
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
                          astrologersOnly: true,
                          animatedHints: const [
                            'Search your favourite Astrologer',
                            'Connect with a specialist',
                          ],
                          hintText: 'Search your favourite Astrologer',
                          onChanged: _onSearch,
                          // onChanged: _onSearch,           // ← live search
                          // onSubmitted: _onSearch,         // ← keyboard enter
                          onFilterTap: _showFilterSheet, // ← filter sheet
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── ACTIVE FILTER INDICATOR ───────────────────────
                  if (_selectedFilter != 'All' ||
                      _selectedSort != 'Default' ||
                      _selectedLanguage != 'All' ||
                      _selectedConsultation != 'All' ||
                      _selectedAvailability != 'All')
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
                          GestureDetector(
                            onTap: _showFilterSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color:
                                      const Color(0xFFD4A73A).withOpacity(0.45),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tune,
                                    size: 16,
                                    color: Color(0xFFD4A73A),
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Filter',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E3557),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                                widget.palmReadingOnly
                                    ? 'No palm reading experts are available right now. Please check again shortly.'
                                    : _searchQuery.isNotEmpty
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
          if (_selectedLanguage != 'All')
            _filterChip(
              label: _selectedLanguage,
              onRemove: () {
                setState(() => _selectedLanguage = 'All');
                _applyFilters();
              },
            ),
          if (_selectedConsultation != 'All')
            _filterChip(
              label: _selectedConsultation,
              onRemove: () {
                setState(() => _selectedConsultation = 'All');
                _applyFilters();
              },
            ),
          if (_selectedAvailability != 'All')
            _filterChip(
              label: _selectedAvailability,
              onRemove: () {
                setState(() => _selectedAvailability = 'All');
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
