import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + controller.value, -1),
              end: Alignment(1 - controller.value, 1),
              colors: const [
                Color(0xff0f2027),
                Color(0xff203a43),
                Color(0xff2c5364),
                Color(0xff1c1c1c),
              ],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
