import 'package:flutter/material.dart';

import '../../../core/models/other_pages/pages_data.dart';

class CategoryCard extends StatelessWidget {
  final CategoryItem category;

  const CategoryCard({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        /// Category has subcategories
        if (category.hasSubCategories) {
          _showSubCategories(context);
          return;
        }

        /// Direct navigation
        if (activateCategoryTarget(category.id)) return;

        final routeBuilder = categoryRoutes[category.id];

        if (routeBuilder != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: routeBuilder,
            ),
          );
        }
      },
      child: Container(
        width: 108,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 84,
              width: 84,
              child: Image.asset(
                category.assetPath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              category.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E3557),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubCategories(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.50),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.64,
        minChildSize: 0.36,
        maxChildSize: 0.90,
        builder: (context, scrollController) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 26,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4A84F).withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Text(
                      category.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: category.subCategories.length,
                        itemBuilder: (context, index) {
                          final subCategory = category.subCategories[index];
                          return ListTile(
                            leading: Image.asset(
                              subCategory.assetPath,
                              width: 38,
                              height: 38,
                            ),
                            title: Text(
                              subCategory.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              if (activateCategoryTarget(subCategory.id)) {
                                return;
                              }
                              final routeBuilder =
                                  categoryRoutes[subCategory.id];
                              if (routeBuilder != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: routeBuilder),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
