import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      color: const Color(0xFF17102F),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/footer_stars.png',
              height: 260,
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 34, 24, 0),
            child: Text(
              'Your stars.\nYour path.\nYour Astrozura.',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
