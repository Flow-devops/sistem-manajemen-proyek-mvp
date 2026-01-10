import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Real Moments,\nNo Filters',
      'subtitle': 'Authenticity at its core.',
      'description': 'Flow is designed for your real self. Share what\'s happening right now without the pressure of perfection.',
      'image': 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?q=80&w=2070&auto=format&fit=crop',
    },
    {
      'title': 'Your Inner\nCircle Only',
      'subtitle': 'Real friendships, no noise.',
      'description': 'Connect with people who truly matter. No followers, just genuine friends sharing real-life updates.',
      'image': 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?q=80&w=1932&auto=format&fit=crop',
    },
    {
      'title': 'Ephemeral\nMemories',
      'subtitle': 'Fresh feed, everyday.',
      'description': 'Moments that last for 24 hours. Keep your feed exciting and your privacy intact with auto-disappearing posts.',
      'image': 'https://images.unsplash.com/photo-1516062423079-7ca13cdc7f5a?q=80&w=2083&auto=format&fit=crop',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    // Navigasi ke WelcomeScreen (yang punya Sliding Card)
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (_) => const WelcomeScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF1CBABE);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _onboardingData.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => _buildOnboardingPage(_onboardingData[index]),
          ),

          // DOTS INDICATOR
          Positioned(
            bottom: 130,
            left: 30,
            child: Row(
              children: List.generate(
                _onboardingData.length,
                (index) => _buildDot(index, brandColor),
              ),
            ),
          ),
            
          // NAVIGATION BUTTONS
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(color: Colors.white54, fontWeight: FontWeight.w500),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_currentPage < _onboardingData.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400), 
                        curve: Curves.easeInOut
                      );
                    } else {
                      _finishOnboarding();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(color: brandColor, shape: BoxShape.circle),
                    child: Icon(
                      _currentPage < _onboardingData.length - 1 
                          ? Icons.arrow_forward_ios_rounded 
                          : Icons.check_rounded, 
                      color: Colors.white, 
                      size: 24
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(Map<String, String> data) {
    return Stack(
      children: [
        Positioned.fill(child: Image.network(data['image']!, fit: BoxFit.cover)),
        Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.5), Colors.black.withOpacity(0.9)])))),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text('flow', style: GoogleFonts.satisfy(fontSize: 48, fontWeight: FontWeight.bold, color: const Color(0xFF1CBABE))),
                const Spacer(),
                Text(data['title']!, style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                const SizedBox(height: 15),
                Text(data['subtitle']!, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1CBABE))),
                const SizedBox(height: 20),
                Text(data['description']!, style: GoogleFonts.poppins(fontSize: 15, color: Colors.white70, height: 1.5)),
                const SizedBox(height: 180),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(int index, Color activeColor) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(right: 10),
      height: 8,
      width: isActive ? 35 : 10,
      decoration: BoxDecoration(color: isActive ? activeColor : Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
    );
  }
}
