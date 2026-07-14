import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _startTimer();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    Timer(const Duration(seconds: 2), _checkRedirect);
  }

  Future<void> _checkRedirect() async {
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
      
      if (!mounted) return;

      if (!seenOnboarding) {
        context.go('/onboarding');
      } else {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          context.go('/home');
        } else {
          context.go('/login');
        }
      }
    } catch (_) {
      if (mounted) {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9A724E), // Warm brown color matching the mockup
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Full white transparent logo (mark + brand + slogan)
              Image.asset(
                'assets/images/onboarding_logo_transparent.png',
                width: 250,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if logo file not found
                  return Column(
                    children: [
                      Image.asset(
                        'assets/images/belumi_logo_mark.png',
                        height: 96,
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'belumi',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'da thấu suốt, sắc rạng ngời',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
