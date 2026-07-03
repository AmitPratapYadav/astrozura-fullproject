import 'package:flutter/material.dart';
import 'greeting_widget.dart';
import '../../mainwidgets/search_widget.dart';

class GreetingSearchWidget extends StatelessWidget {
  final String userName;

  const GreetingSearchWidget({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GreetingWidget(),

          const SizedBox(height: 20),

          const GlobalSearchWidget(),
        ],
      ),
    );
  }
}