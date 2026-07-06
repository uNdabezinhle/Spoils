import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/spoil_colors.dart';
import '../../shared/widgets/spoil_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpoilColors.cream,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: SpoilColors.blush,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.card_giftcard, size: 56, color: SpoilColors.teal),
              ),
              const SizedBox(height: 28),
              const SpoilLogo(size: 42, showTagline: true),
              const SizedBox(height: 12),
              Text(
                'Let\'s make gifting special',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}