import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with SingleTickerProviderStateMixin {
  bool _showSuccess = false;
  String? _lastUserId;
  late AnimationController _lottieController;
  late Future<bool> _onboardingFuture;

  @override
  void initState() {
    super.initState();
    // Simpan future agar tidak ter-recreate saat rebuild (mencegah layar kedip/reset)
    _onboardingFuture = _checkOnboarding();
    
    _lottieController = AnimationController(vsync: this);
    _lottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _showSuccess = false;
          });
        }
        _lottieController.reset();
      }
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  Future<bool> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  Future<void> _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final currentUserId = auth.currentUser?.id;

        if (_lastUserId == null && currentUserId != null) {
          _lastUserId = currentUserId;
          _showSuccess = true;
          _markOnboardingComplete();
        } else if (currentUserId == null) {
          _lastUserId = null;
        }

        if (currentUserId != null) {
          if (_showSuccess) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Lottie.asset(
                  'assets/animations/success.json',
                  controller: _lottieController,
                  width: 200,
                  height: 200,
                  repeat: false,
                  frameRate: FrameRate.composition, // Lock frame rate to avoid speed-up on 120Hz screens
                  onLoaded: (composition) {
                    if (mounted) {
                      _lottieController.duration = composition.duration;
                      _lottieController.forward();
                    }
                  },
                ),
              ),
            );
          }
          return const HomeScreen();
        }

        return FutureBuilder<bool>(
          future: _onboardingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Color(0xFF1CBABE))));
            }

            final bool completed = snapshot.data ?? false;

            if (completed) {
              return const WelcomeScreen();
            } else {
              return const OnboardingScreen();
            }
          },
        );
      },
    );
  }
}
