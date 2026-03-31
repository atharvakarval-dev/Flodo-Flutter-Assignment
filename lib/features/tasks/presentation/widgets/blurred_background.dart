import 'dart:ui';
import 'package:flutter/material.dart';

class BlurredBackground extends StatelessWidget {
  final Widget child;

  const BlurredBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Ellipse 1 (Purple/Blue top right)
        Positioned(
          left: 300,
          top: 200,
          child: _buildBlurCircle(
            size: 150,
            colors: [
              const Color(0xFF7C46F0),
              const Color(0xFF7C46F0).withOpacity(0.15),
            ],
            blur: 75,
          ),
        ),
        // Ellipse 3 (Light Blue mid left)
        Positioned(
          left: -40,
          top: 500,
          child: _buildBlurCircle(
            size: 120,
            colors: [
              const Color(0xFF46BDF0),
              const Color(0xFF46BDF0).withOpacity(0.15),
            ],
            blur: 75,
          ),
        ),
        // Ellipse 11 (Yellow bottom right)
        Positioned(
          left: 200,
          top: 700,
          child: _buildBlurCircle(
            size: 100,
            colors: [
              const Color(0xFFF0B646),
              const Color(0xFFF0B646).withOpacity(0.15),
            ],
            blur: 65,
          ),
        ),
        // Ellipse 2 (Green top left)
        Positioned(
          left: -20,
          top: -20,
          child: _buildBlurCircle(
            size: 100,
            colors: [
              const Color(0xFF46F080),
              const Color(0xFF46F080).withOpacity(0.15),
            ],
            blur: 75,
          ),
        ),
        // Foreground Content
        Container(
          color: Colors.white.withOpacity(0.6), // Light frost layer over blurs if desired
          child: child,
        ),
      ],
    );
  }

  Widget _buildBlurCircle({
    required double size,
    required List<Color> colors,
    required double blur,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
