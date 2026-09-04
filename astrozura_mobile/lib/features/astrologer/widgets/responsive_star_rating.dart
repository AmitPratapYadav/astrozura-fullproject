import 'package:flutter/material.dart';

class ResponsiveStarRating extends StatelessWidget {
  final double rating;
  final double maxSize;
  final double spacing;
  final Color activeColor;
  final Color emptyColor;

  const ResponsiveStarRating({
    super.key,
    required this.rating,
    this.maxSize = 16,
    this.spacing = 1.5,
    this.activeColor = const Color(0xFFD4A73C),
    this.emptyColor = const Color(0x55FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    final value = rating.isFinite ? rating.clamp(0.0, 5.0) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : (maxSize * 5) + (spacing * 4);
        final size = ((available - spacing * 4) / 5).clamp(9.0, maxSize);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final fill = (value - index).clamp(0.0, 1.0);
            final icon = fill >= 0.75
                ? Icons.star_rounded
                : fill >= 0.25
                    ? Icons.star_half_rounded
                    : Icons.star_border_rounded;

            return Padding(
              padding: EdgeInsets.only(right: index == 4 ? 0 : spacing),
              child: Icon(
                icon,
                size: size,
                color: fill == 0 ? emptyColor : activeColor,
              ),
            );
          }),
        );
      },
    );
  }
}
