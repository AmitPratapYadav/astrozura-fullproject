import 'package:flutter/material.dart';
import 'category_model.dart';

class CategoryData {
  static List<CategoryModel> categories = [

    CategoryModel(
      title: "Talk To\nAstrologers",
      icon: Icons.support_agent,
    ),

    CategoryModel(
      title: "Horoscope",
      icon: Icons.auto_awesome,
    ),

    CategoryModel(
      title: "Birth Chart",
      icon: Icons.pie_chart,
    ),

    CategoryModel(
      title: "Palm Reading",
      icon: Icons.pan_tool,
    ),

    CategoryModel(
      title: "Tarot",
      icon: Icons.style,
    ),
  ];
}