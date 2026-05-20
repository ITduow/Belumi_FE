import 'package:flutter/material.dart';

class ImageCard extends StatelessWidget {
  const ImageCard({
    super.key,
    required this.imageUrl,
    required this.child,
    this.height = 160,
  });

  final String? imageUrl;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          SizedBox(
            height: height,
            width: double.infinity,
            child: imageUrl == null
                ? ColoredBox(color: Colors.grey.shade100)
                : Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        ColoredBox(color: Colors.grey.shade100),
                  ),
          ),
          Container(
            height: height,
            color: Colors.black.withValues(alpha: 0.28),
          ),
          Positioned(left: 16, right: 16, bottom: 16, child: child),
        ],
      ),
    );
  }
}
