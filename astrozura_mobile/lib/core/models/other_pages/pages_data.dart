import 'package:flutter/material.dart';

import '../../../features/main_navigation.dart';

class CategoryItem {
  final String id;
  final String title;
  final String assetPath;
  final int? targetIndex;
  final List<SubCategoryItem> subCategories;

  const CategoryItem({
    required this.id,
    required this.title,
    required this.assetPath,
    this.targetIndex,
    this.subCategories = const [],
  });

  bool get hasSubCategories => subCategories.isNotEmpty;
}

class SubCategoryItem {
  final String id;
  final String title;
  final String assetPath;
  final int targetIndex;

  const SubCategoryItem({
    required this.id,
    required this.title,
    required this.assetPath,
    required this.targetIndex,
  });
}

const List<SubCategoryItem> reportServices = [
  SubCategoryItem(
    id: 'lal_kitab',
    title: 'Lal Kitab Reports',
    assetPath: 'assets/images/reports/report-lal-kitab.png',
    targetIndex: 12,
  ),
  SubCategoryItem(
    id: 'detailed_kundali',
    title: 'Detailed Kundali Analysis',
    assetPath: 'assets/images/reports/report-detailed-kundali.png',
    targetIndex: 32,
  ),
  SubCategoryItem(
    id: 'detailed_dosha',
    title: 'Detailed Dosha Analysis',
    assetPath: 'assets/images/reports/report-detailed-dosha.png',
    targetIndex: 33,
  ),
  SubCategoryItem(
    id: 'detailed_matchmaking',
    title: 'Detailed Matchmaking Report',
    assetPath: 'assets/images/reports/report-detailed-matchmaking.png',
    targetIndex: 34,
  ),
];

const List<SubCategoryItem> calculatorServices = [
  SubCategoryItem(
    id: 'daily_nakshatra',
    title: 'Daily Nakshatra Predictions',
    assetPath: 'assets/images/calculators/daily_nakshatra.png',
    targetIndex: 13,
  ),
  SubCategoryItem(
    id: 'mangal_dosha',
    title: 'Mangal Dosha',
    assetPath: 'assets/images/calculators/mangal_dosha.png',
    targetIndex: 14,
  ),
  SubCategoryItem(
    id: 'kaalsarp_dosha',
    title: 'Kaalsarp Dosha',
    assetPath: 'assets/images/calculators/kaalsarp_dosha.png',
    targetIndex: 15,
  ),
  SubCategoryItem(
    id: 'sade_sati',
    title: 'Sade-Sati',
    assetPath: 'assets/images/calculators/sade_sati.png',
    targetIndex: 16,
  ),
  SubCategoryItem(
    id: 'pitra_dosha',
    title: 'Pitra Dosha',
    assetPath: 'assets/images/calculators/pitra_dosha.png',
    targetIndex: 17,
  ),
  SubCategoryItem(
    id: 'puja_suggestion',
    title: 'Puja Suggestion',
    assetPath: 'assets/images/calculators/pooja_suggestion.png',
    targetIndex: 18,
  ),
  SubCategoryItem(
    id: 'gemstone_suggestion',
    title: 'Gemstone Suggestion',
    assetPath: 'assets/images/calculators/gemstone_suggestion.png',
    targetIndex: 19,
  ),
  SubCategoryItem(
    id: 'rudraksha_suggestion',
    title: 'Rudraksha Suggestion',
    assetPath: 'assets/images/calculators/rudraksha_suggestion.png',
    targetIndex: 20,
  ),
  SubCategoryItem(
    id: 'vimshottari_dasha',
    title: 'Vimshottari Dasha',
    assetPath: 'assets/images/calculators/vimshottari_dasha.png',
    targetIndex: 21,
  ),
  SubCategoryItem(
    id: 'char_dasha',
    title: 'Char Dasha',
    assetPath: 'assets/images/calculators/char_dasha.png',
    targetIndex: 22,
  ),
  SubCategoryItem(
    id: 'yogini_dasha',
    title: 'Yogini Dasha',
    assetPath: 'assets/images/calculators/yogini_dasha.png',
    targetIndex: 23,
  ),
  SubCategoryItem(
    id: 'varshaphal',
    title: 'Varshaphal',
    assetPath: 'assets/images/calculators/varshaphal.png',
    targetIndex: 24,
  ),
  SubCategoryItem(
    id: 'krishnamurti_paddhati',
    title: 'Krishnamurti Paddhati',
    assetPath: 'assets/images/calculators/krishnamurti_paddhati.png',
    targetIndex: 25,
  ),
  SubCategoryItem(
    id: 'ashtakavarga_chart',
    title: 'Ashtakavarga and Sarvashta Varga Chart',
    assetPath: 'assets/images/calculators/ashtakavarga.png',
    targetIndex: 26,
  ),
  SubCategoryItem(
    id: 'detailed_numerology',
    title: 'Detailed Numerology',
    assetPath: 'assets/images/calculators/detailed_numerology.png',
    targetIndex: 27,
  ),
  SubCategoryItem(
    id: 'tarot_reading',
    title: 'Tarot Reading',
    assetPath: 'assets/images/calculators/tarot_reading.png',
    targetIndex: 28,
  ),
  SubCategoryItem(
    id: 'biorhythm',
    title: 'Biorhythm',
    assetPath: 'assets/images/calculators/biorhythm.png',
    targetIndex: 35,
  ),
  SubCategoryItem(
    id: 'palm_reading',
    title: 'Palm Reading',
    assetPath: 'assets/images/calculators/palm_reading.png',
    targetIndex: 29,
  ),
];

const List<CategoryItem> allCategories = [
  CategoryItem(
    id: 'pooja_anusthan',
    title: 'Pooja Anusthan',
    assetPath: 'assets/images/services/pooja_anusthan.png',
    targetIndex: 7,
  ),
  CategoryItem(
    id: 'panchang',
    title: 'Panchang',
    assetPath: 'assets/images/services/panchang.png',
    subCategories: [
      SubCategoryItem(
        id: 'daily_panchang',
        title: 'Daily Panchang',
        assetPath: 'assets/images/services/panchang.png',
        targetIndex: 8,
      ),
      SubCategoryItem(
        id: 'chaughadiya_muhurt',
        title: 'Chaughadiya Muhurt',
        assetPath: 'assets/images/services/panchang.png',
        targetIndex: 9,
      ),
      SubCategoryItem(
        id: 'hora_muhurta',
        title: 'Hora Muhurta',
        assetPath: 'assets/images/services/panchang.png',
        targetIndex: 10,
      ),
    ],
  ),
  CategoryItem(
    id: 'horoscope',
    title: 'Horoscope',
    assetPath: 'assets/images/services/horoscope.png',
    targetIndex: 11,
  ),
  CategoryItem(
    id: 'reports',
    title: 'Reports',
    assetPath: 'assets/images/services/reports.png',
    subCategories: reportServices,
  ),
  CategoryItem(
    id: 'calculators',
    title: 'Calculators',
    assetPath: 'assets/images/services/calculators.png',
    subCategories: calculatorServices,
  ),
];

final Map<String, WidgetBuilder> categoryRoutes = {
  for (final category in allCategories)
    if (category.targetIndex != null)
      category.id: (_) => MainNavigation(initialIndex: category.targetIndex!),
  for (final category in allCategories)
    for (final sub in category.subCategories)
      sub.id: (_) => MainNavigation(initialIndex: sub.targetIndex),
};

int? categoryTargetIndex(String id) {
  for (final category in allCategories) {
    if (category.id == id) return category.targetIndex;
    for (final sub in category.subCategories) {
      if (sub.id == id) return sub.targetIndex;
    }
  }
  return null;
}

bool activateCategoryTarget(String id) {
  final targetIndex = categoryTargetIndex(id);
  final navigation = MainNavigationState.instance;
  if (targetIndex == null || navigation == null) return false;
  navigation.switchTab(targetIndex);
  return true;
}
