import 'package:flutter/material.dart';

class RemoteAvatar extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double radius;
  final Color backgroundColor;

  const RemoteAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.radius,
    this.backgroundColor = const Color(0xFFE8E8EE),
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: Text(
        name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase(),
        style: TextStyle(
          color: const Color(0xFF1E3557),
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return ClipOval(
      child: SizedBox.square(
        dimension: radius * 2,
        child: imageUrl.trim().isEmpty
            ? fallback
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, _) =>
                    frame == null ? fallback : child,
                errorBuilder: (_, __, ___) => fallback,
              ),
      ),
    );
  }
}
