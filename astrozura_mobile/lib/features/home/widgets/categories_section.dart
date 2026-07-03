import 'package:astrozura_application/core/contants/app_colors.dart';
import 'package:flutter/material.dart';
import 'category_card.dart';
import '../../../core/models/other_pages/pages_data.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../other_pages/category_page.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔹 Title Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Explore Astrozura",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => SparkCategorySheet.show(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        "View All",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        /// 🔹 Horizontal List
        SizedBox(
          height: 106,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 16),
            itemCount: allCategories.length,
            itemBuilder: (context, index) {
              return CategoryCard(
                category: allCategories[index],
              );
            },
          ),
        ),
      ],
    );
  }
}
