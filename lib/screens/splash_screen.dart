import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onThemeChanged});

  final VoidCallback? onThemeChanged;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.82, curve: Curves.easeInOutCubic),
    );

    _controller.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (_, __, ___) =>
              HomeScreen(onThemeChanged: widget.onThemeChanged),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            final jump = _jumpOffset(t);
            final scale = _characterScale(t);

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          _OrbitingStar(progress: t),
                          Transform.translate(
                            offset: Offset(0, jump),
                            child: Transform.scale(
                              scale: scale,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(38),
                                    child: Image.asset(
                                      'assets/splash/reader_splash.png',
                                      width: 210,
                                      height: 210,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  if (t > 0.46 && t < 0.62)
                                    const Positioned(
                                      top: 70,
                                      right: 74,
                                      child: _WinkMark(),
                                    ),
                                  if (t > 0.84)
                                    Positioned(
                                      bottom: 45,
                                      child: _PageFlip(
                                        progress: (t - 0.84) / 0.16,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Reader',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'тренажёр чтения',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _SplashProgressBar(value: _progress.value),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _jumpOffset(double t) {
    final firstJump = _sineWindow(t, 0.22, 0.42) * -28;
    final secondJump = _sineWindow(t, 0.45, 0.56) * -10;
    return firstJump + secondJump;
  }

  double _characterScale(double t) {
    final squash = _sineWindow(t, 0.18, 0.25) * -0.04;
    final stretch = _sineWindow(t, 0.25, 0.42) * 0.07;
    return 1 + squash + stretch;
  }

  double _sineWindow(double t, double begin, double end) {
    if (t <= begin || t >= end) return 0;
    final local = (t - begin) / (end - begin);
    return math.sin(local * math.pi);
  }
}

class _OrbitingStar extends StatelessWidget {
  const _OrbitingStar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final local = (progress / 0.72).clamp(0.0, 1.0);
    final eased = Curves.easeInOutCubic.transform(local);
    final angle = -1.35 + eased * math.pi * 2.15;
    final opacity = progress > 0.78
        ? (1 - (progress - 0.78) / 0.12).clamp(0.0, 1.0)
        : 1.0;

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(math.cos(angle) * 108, math.sin(angle) * 82),
        child: Transform.rotate(
          angle: angle,
          child: Icon(
            Icons.star_rounded,
            size: 32,
            color: colors.tertiary,
            shadows: [
              Shadow(
                blurRadius: 12,
                color: colors.tertiary.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinkMark extends StatelessWidget {
  const _WinkMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(28, 14), painter: _WinkPainter());
  }
}

class _WinkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3A2116)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(2, size.height * 0.55)
      ..quadraticBezierTo(
        size.width / 2,
        size.height,
        size.width - 2,
        size.height * 0.55,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PageFlip extends StatelessWidget {
  const _PageFlip({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final local = Curves.easeInOutCubic.transform(progress.clamp(0.0, 1.0));
    return Transform(
      alignment: Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(-math.pi * local),
      child: Container(
        width: 82,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(12),
            topLeft: Radius.circular(4),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashProgressBar extends StatelessWidget {
  const _SplashProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 16,
            child: LinearProgressIndicator(
              value: value,
              minHeight: 16,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(value * 100).round()}%',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
