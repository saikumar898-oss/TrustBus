import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;

  const GlassCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // -------- Responsive width --------

    double cardWidth;

    if (width < 600) {
      cardWidth = width * 0.9; // mobile
    } else if (width < 1000) {
      cardWidth = 420; // tablet
    } else {
      cardWidth = 460; // desktop
    }

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 25,
            sigmaY: 25,
          ),
          child: Container(
            width: cardWidth,

            // -------- Card Padding --------

            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 32,
            ),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),

              // -------- Glass Color --------

              color: Colors.white.withValues(alpha: 0.08),

              // -------- Border --------

              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),

              // -------- Shadow --------

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 40,
                  spreadRadius: 3,
                  offset: const Offset(0, 15),
                ),
              ],
            ),

            child: child,
          ),
        ),
      ),
    );
  }
}
