import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  bool _showAuthCard = false;
  bool _isLogin = true;

  void _toggleAuthCard(bool show, {bool isLogin = true}) {
    FocusScope.of(context).unfocus();
    setState(() {
      _showAuthCard = show;
      _isLogin = isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF1CBABE);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF002324),
      resizeToAvoidBottomInset: false, 
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1CBABE),
                    Color(0xFF004D4E),
                    Color(0xFF001A1B),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
            top: size.height * 0.2,
            left: -size.width * 0.3,
            child: _buildBlurBlob(size.width * 0.8, Colors.white.withOpacity(0.15)),
          ),
          Positioned(
            bottom: size.height * 0.1,
            right: -size.width * 0.2,
            child: _buildBlurBlob(size.width * 0.6, brandColor.withOpacity(0.4)),
          ),

          Positioned(
            top: size.height * 0.1,
            left: -20,
            child: Transform.rotate(
              angle: -0.2,
              child: _buildMomentFrame(100, 120, Icons.camera_alt_outlined),
            ),
          ),
          Positioned(
            top: size.height * 0.35,
            right: -30,
            child: Transform.rotate(
              angle: 0.15,
              child: _buildMomentFrame(130, 150, Icons.photo_library_outlined),
            ),
          ),
          Positioned(
            bottom: size.height * 0.3,
            left: size.width * 0.05,
            child: Transform.rotate(
              angle: 0.1,
              child: _buildMomentFrame(80, 80, Icons.favorite_border_rounded),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              const SizedBox(height: 50),
                              Hero(
                                tag: 'flow_logo',
                                child: Text(
                                  'FLOW',
                                  style: GoogleFonts.syncopate(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 10,
                                    shadows: [
                                      const Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                                    ]
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              Container(
                                width: 50,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1CBABE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 25),
                              Text(
                                'Capture life as it happens.\nYour moments, shared instantly.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),

                          Transform.scale(
                            scale: 1.2,
                            child: Lottie.asset(
                              'assets/animations/Influencer.json',
                              width: size.width * 0.8,
                              fit: BoxFit.contain,
                              frameRate: FrameRate.composition, // Lock frame rate
                            ),
                          ),

                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Column(
                                  children: [
                                    _buildButton(
                                      label: 'GET STARTED',
                                      onPressed: () => _toggleAuthCard(true, isLogin: false),
                                      isPrimary: true,
                                    ),
                                    const SizedBox(height: 15),
                                    _buildButton(
                                      label: 'SIGN IN',
                                      onPressed: () => _toggleAuthCard(true, isLogin: true),
                                      isPrimary: false,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 50),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            ),
          ),

          if (_showAuthCard)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _toggleAuthCard(false),
                child: Container(color: Colors.black.withOpacity(0.6)),
              ),
            ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 500), 
            curve: Curves.easeOutQuart, 
            top: _showAuthCard ? 100 : size.height,
            left: 0,
            right: 0,
            bottom: 0,
            child: RepaintBoundary( 
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black45, blurRadius: 40, spreadRadius: 2),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    GestureDetector(
                      onVerticalDragUpdate: (details) {
                        if (details.primaryDelta! > 10) _toggleAuthCard(false);
                      },
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    Expanded(
                      child: _isLogin 
                        ? LoginScreen(
                            isInsideOnboarding: true, 
                            onBack: () => _toggleAuthCard(false),
                            onSwitchToRegister: () => setState(() => _isLogin = false),
                          ) 
                        : RegisterScreen(
                            isInsideOnboarding: true, 
                            onBack: () => _toggleAuthCard(false),
                            onSwitchToLogin: () => setState(() => _isLogin = true),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentFrame(double width, double height, IconData icon) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1CBABE).withOpacity(0.2), blurRadius: 15)
        ]
      ),
      child: Center(
        child: Icon(icon, color: Colors.white.withOpacity(0.3), size: width * 0.4),
      ),
    );
  }

  Widget _buildBlurBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 80,
            spreadRadius: 10,
          )
        ],
      ),
    );
  }

  Widget _buildButton({required String label, required VoidCallback onPressed, bool isPrimary = true}) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: isPrimary ? BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ) : null,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1CBABE),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white70, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(label, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
            ),
    );
  }
}
