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
        width: 96,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 68,
              width: 68,
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
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
                            final routeBuilder = categoryRoutes[subCategory.id];
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
            );
          },
        ),
      ),
    );
  }
}
