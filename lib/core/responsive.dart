import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;

  Responsive(this.context);

  double get width => MediaQuery.of(context).size.width;

  // BREAKPOINTS
  bool get isMobile => width < 600;

  bool get isTablet => width >= 600 && width < 1024;

  bool get isDesktop => width >= 1024;

  // SCALE
  double scale() {
    if (width < 360) return 0.85;
    if (width < 600) return 1.0;
    if (width < 900) return 1.1;
    if (width < 1200) return 1.2;
    return 1.35;
  }

  double font(double base) {
    return base * scale();
  }

  // GRID
  int gridColumns() {
    if (isMobile) return 1;
    if (isTablet) return 2;
    return 4;
  }

  // PADDING
  EdgeInsets screenPadding() {
    if (isMobile) {
      return const EdgeInsets.all(16);
    } else if (isTablet) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.symmetric(horizontal: 80, vertical: 32);
    }
  }
}
