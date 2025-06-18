// ────────────────────────────────────────────────────────────
// File    : lib/screens/login/widgets/animated_aurora_background.dart
// Purpose : Renders a slowly animating gradient background with a new
//           sophisticated silver and blue color palette.
// ────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedAuroraBackground extends StatefulWidget {
  const AnimatedAuroraBackground({super.key});

  @override
  State<AnimatedAuroraBackground> createState() =>
      _AnimatedAuroraBackgroundState();
}

class _AnimatedAuroraBackgroundState extends State<AnimatedAuroraBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 30)) // Slower for a more subtle effect
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Optional: Noise texture for a more organic feel
        // Positioned.fill(child: Opacity(opacity: 0.1, child: Image.asset('assets/noise.png', fit: BoxFit.cover))),

        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final alignment1 = AlignmentTween(
                begin: const Alignment(-1.0, -1.0),
                end: const Alignment(1.0, 1.0),
              ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

              final alignment2 = AlignmentTween(
                begin: const Alignment(1.0, -1.0),
                end: const Alignment(-1.5, 1.0),
              ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

              return Stack(
                children: [
                  // Blob 1: A soft silver/white color
                  _buildBlob(
                    alignment: alignment1.value,
                    color: const Color(0xFFE0E0E0).withOpacity(0.4),
                  ),

                  // Blob 2: A deep, professional blue
                  _buildBlob(
                    alignment: alignment2.value,
                    color: const Color(0xFF0D47A1).withOpacity(0.5),
                  ),

                  // Blob 3: A standard corporate blue
                  _buildBlob(
                    alignment: Alignment.center,
                    color: const Color(0xFF1976D2).withOpacity(0.4),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBlob({required Alignment alignment, required Color color}) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 500, // Slightly larger blobs for a softer gradient
        height: 500,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120), // More blur
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }
}