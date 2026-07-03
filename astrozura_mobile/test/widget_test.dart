import 'package:astrozura_application/core/contants/api_constants.dart';
import 'package:astrozura_application/core/models/app_content_catalog.dart';
import 'package:astrozura_application/core/models/other_pages/pages_data.dart';
import 'package:astrozura_application/core/providers/profile_provider.dart';
import 'package:astrozura_application/features/mainwidgets/bottom_navbar.dart';
import 'package:astrozura_application/features/mainwidgets/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('customer service catalog has stable unique destinations', () {
    final ids = <String>{};
    for (final category in allCategories) {
      expect(ids.add(category.id), isTrue);
      expect(category.assetPath, startsWith('assets/images/'));
      for (final service in category.subCategories) {
        expect(ids.add(service.id), isTrue);
        expect(service.assetPath, startsWith('assets/images/'));
        expect(service.targetIndex, greaterThanOrEqualTo(0));
      }
    }
    expect(allCategories.map((item) => item.title),
        isNot(contains('Our Astrologers')));
  });

  testWidgets('bottom navigation exposes Chat instead of Experts',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CustomBottomNavbar(
            currentIndex: 0,
            onTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Experts'), findsNothing);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
  });

  test('media URLs preserve cloud URLs and resolve legacy uploads', () {
    expect(
      ApiConstants.baseUrl,
      'https://astrozura.com/apigateway/index.php/api',
    );
    expect(
      ApiConstants.storageUrl('https://cdn.example.com/user/avatar.jpg'),
      'https://cdn.example.com/user/avatar.jpg',
    );
    expect(
      ApiConstants.storageUrl('/uploads/user-profiles/avatar.jpg'),
      'https://astrozura.com/uploads/user-profiles/avatar.jpg',
    );
    expect(
      ApiConstants.storageUrl('/storage/user-profiles/avatar.jpg'),
      'https://astrozura.com/storage/user-profiles/avatar.jpg',
    );
  });

  testWidgets('banner and zodiac assets use deployable exact paths',
      (tester) async {
    for (final banner in homeBanners) {
      expect(await rootBundle.load(banner.assetPath), isNotNull);
    }
    for (final sign in zodiacSigns) {
      expect(await rootBundle.load(sign.assetPath), isNotNull);
    }
  });

  testWidgets('notification panel opens and closes', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ProfileProvider(),
        child: const MaterialApp(home: Scaffold(body: HeaderWidget())),
      ),
    );

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('No new notifications yet'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('No new notifications yet'), findsNothing);
  });
}
