// spark_category_sheet.dart
// Usage: SparkCategorySheet.show(context);

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/other_pages/pages_data.dart';

class SparkCategorySheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _SheetRoot(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

class _C {
  static const gold = Color(0xFFD4A84F);
  static const goldLight = Color(0xFFF5EDDA);
  static const goldMid = Color(0xFFEDD99A);
  static const darkBlue = Color(0xFF0d437b);
  static const textDark = Color(0xFF1A1A1A);
  static const textMid = Color(0xFF666666);
  static const textLight = Color(0xFFAAAAAA);
  static const divider = Color(0xFFF0F0F0);
  static const bg = Color(0xFFFAFAFA);
  static const white = Color(0xFFFFFFFF);
}

// ─────────────────────────────────────────────────────────────────────────────
// Root shell — owns the slide animation
// ─────────────────────────────────────────────────────────────────────────────

class _SheetRoot extends StatefulWidget {
  const _SheetRoot();
  @override
  State<_SheetRoot> createState() => _SheetRootState();
}

class _SheetRootState extends State<_SheetRoot>
    with SingleTickerProviderStateMixin {
  CategoryItem? _activeCat;

  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _openSubPage(CategoryItem cat) {
    HapticFeedback.lightImpact();
    setState(() => _activeCat = cat);
    _slideCtrl.forward(from: 0);
  }

  void _goBack() {
    HapticFeedback.lightImpact();
    _slideCtrl.reverse().then((_) {
      if (mounted) setState(() => _activeCat = null);
    });
  }

  void _handleLeafNavigation(BuildContext ctx, String id, String title) {
    final builder = categoryRoutes[id];

    if (builder == null) {
      // Dev safety net — remove before release
      debugPrint('⚠️  No route registered for id: "$id"');
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Page not ready: $title'),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    Navigator.push(ctx, MaterialPageRoute(builder: builder));
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH * 0.70,
      decoration: const BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Stack(
          children: [
            _MainCategoryPage(
              onCategoryTap: (cat) {
                if (cat.hasSubCategories) {
                  _openSubPage(cat);
                } else {
                  Navigator.pop(context);
                  _handleLeafNavigation(context, cat.id, cat.title);
                }
              },
              onClose: () => Navigator.pop(context),
            ),
            if (_activeCat != null)
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _SubCategoryPage(
                    category: _activeCat!,
                    onBack: _goBack,
                    onSubTap: (sub) {
                      Navigator.pop(context);
                      _handleLeafNavigation(context, sub.id, sub.title);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Category List Page
// ─────────────────────────────────────────────────────────────────────────────

class _MainCategoryPage extends StatefulWidget {
  final ValueChanged<CategoryItem> onCategoryTap;
  final VoidCallback onClose;

  const _MainCategoryPage({
    required this.onCategoryTap,
    required this.onClose,
  });

  @override
  State<_MainCategoryPage> createState() => _MainCategoryPageState();
}

class _MainCategoryPageState extends State<_MainCategoryPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
        () => setState(() => _query = _searchCtrl.text.toLowerCase().trim()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CategoryItem> get _filtered {
    if (_query.isEmpty) return allCategories;
    return allCategories.where((cat) {
      if (cat.title.toLowerCase().contains(_query)) return true;
      return cat.subCategories
          .any((s) => s.title.toLowerCase().contains(_query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle
          const _DragHandle(),

          // ── Header
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 18, 18),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Services',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _C.textDark,
                          letterSpacing: -0.3,
                        )),
                    const SizedBox(height: 2),
                    Text('${allCategories.length} services',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _C.textLight,
                          fontWeight: FontWeight.w400,
                        )),
                  ],
                ),
                const Spacer(),
                _IconBtn(
                  icon: Icons.close_rounded,
                  onTap: widget.onClose,
                ),
              ],
            ),
          ),

          // ── Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
            child: _SearchField(controller: _searchCtrl),
          ),

          // ── Divider
          const Divider(height: 1, color: _C.divider),

          // ── List
          Expanded(
            child: _filtered.isEmpty
                ? _EmptyState(query: _query)
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 6, bottom: 32),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final cat = _filtered[i];
                      final isLast = i == _filtered.length - 1;
                      return _CategoryTile(
                        cat: cat,
                        isLast: isLast,
                        onTap: () => widget.onCategoryTap(cat),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-Category Page
// ─────────────────────────────────────────────────────────────────────────────

class _SubCategoryPage extends StatelessWidget {
  final CategoryItem category;
  final VoidCallback onBack;
  final ValueChanged<SubCategoryItem> onSubTap;

  const _SubCategoryPage({
    required this.category,
    required this.onBack,
    required this.onSubTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DragHandle(),

          // ── Header with back button
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Row(
              children: [
                _IconBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  iconSize: 15,
                  onTap: onBack,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _C.textDark,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose a service',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _C.textLight,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: _C.divider),

          // ── Sub-category list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 6, bottom: 32),
              itemCount: category.subCategories.length,
              itemBuilder: (_, i) {
                final sub = category.subCategories[i];
                final isLast = i == category.subCategories.length - 1;
                return _SubTile(
                  sub: sub,
                  index: i,
                  isLast: isLast,
                  onTap: () => onSubTap(sub),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tiles
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final CategoryItem cat;
  final bool isLast;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.cat,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: _C.goldLight,
            highlightColor: _C.goldLight.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _C.goldLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(cat.assetPath, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _C.textDark,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow badge
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: cat.hasSubCategories
                          ? _C.goldLight
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: cat.hasSubCategories ? _C.gold : _C.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.only(left: 80),
            child: Divider(height: 1, color: _C.divider),
          ),
      ],
    );
  }
}

class _SubTile extends StatelessWidget {
  final SubCategoryItem sub;
  final int index;
  final bool isLast;
  final VoidCallback onTap;

  const _SubTile({
    required this.sub,
    required this.index,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: _C.goldLight,
            highlightColor: _C.goldLight.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
              child: Row(
                children: [
                  // Service artwork
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _C.goldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Image.asset(
                        sub.assetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.auto_awesome_outlined,
                          color: _C.gold,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Text(
                      sub.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _C.textDark,
                        height: 1.35,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: _C.textLight,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.only(left: 64),
            child: Divider(height: 1, color: _C.divider),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  const _DragHandle();
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFDDDDDD),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: iconSize, color: const Color(0xFF888888)),
        ),
      );
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) => Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          style: const TextStyle(
            fontSize: 14,
            color: _C.textDark,
            fontWeight: FontWeight.w400,
          ),
          decoration: const InputDecoration(
            hintText: 'Search services...',
            hintStyle: TextStyle(fontSize: 14, color: _C.textLight),
            prefixIcon:
                Icon(Icons.search_rounded, size: 18, color: _C.textLight),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _C.goldLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 28, color: _C.gold),
            ),
            const SizedBox(height: 14),
            const Text('No results found',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _C.textDark,
                )),
            const SizedBox(height: 4),
            Text('Try searching for "$query"',
                style: const TextStyle(
                  fontSize: 13,
                  color: _C.textLight,
                )),
          ],
        ),
      );
}
