import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  final bool isInsideOnboarding;
  final VoidCallback? onBack;
  final VoidCallback? onSwitchToLogin;

  const RegisterScreen({super.key, this.isInsideOnboarding = false, this.onBack, this.onSwitchToLogin});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showTopNotification(String message, {bool isError = false}) {
    if (!mounted) return;
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 500),
            tween: Tween<double>(begin: -100, end: 0),
            curve: Curves.easeOutBack,
            builder: (context, double value, child) {
              return Transform.translate(offset: Offset(0, value), child: child);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? Colors.redAccent.withOpacity(0.9) : const Color(0xFF1CBABE).withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      message,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlayState.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    
    await authProvider.signOut();

    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      username: _usernameController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      if (authProvider.isAuthenticated) {
        await authProvider.signOut();
      }

      if (!mounted) return;

      _showTopNotification('Registration Successful! Please login to continue.');

      if (widget.onSwitchToLogin != null) {
        widget.onSwitchToLogin!();
      }
    } else {
      _showTopNotification(authProvider.errorMessage ?? 'Registration failed', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF1CBABE);

    Widget formContent = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 15), // Diperkecil dari 20
          Text(
            'Create Account',
            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 8), // Diperkecil dari 10
          const Text(
            'Join our community and start sharing\nyour real moments today.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 30), // Diperkecil dari 40
          
          _buildTextField(
            controller: _usernameController,
            hint: 'Username',
            icon: Icons.person_outline,
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 15), // Diperkecil dari 20
          
          _buildTextField(
            controller: _emailController,
            hint: 'Email',
            icon: Icons.alternate_email,
            validator: (val) => val == null || !val.contains('@') ? 'Invalid email' : null,
          ),
          const SizedBox(height: 15), // Diperkecil dari 20
          
          _buildTextField(
            controller: _passwordController,
            hint: 'Password',
            icon: Icons.lock_outline,
            isPassword: true,
            validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
          ),
          
          const SizedBox(height: 30), // Diperkecil dari 40
          
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return SizedBox(
                width: double.infinity,
                height: 54, // Disamakan dengan tombol di WelcomeScreen
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text('GET STARTED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.2)),
                ),
              );
            },
          ),
          
          const SizedBox(height: 30), // Diperkecil dari 50
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account? ', style: TextStyle(color: Colors.black54, fontSize: 13)),
              GestureDetector(
                onTap: widget.onSwitchToLogin,
                child: const Text(
                  'Log In',
                  style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20), // Tambahan padding bawah agar tidak mepet
        ],
      ),
    );

    if (widget.isInsideOnboarding) {
      return Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 5, 20, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: TextButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 16),
                  label: const Text('Back', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(), 
                padding: const EdgeInsets.symmetric(horizontal: 30), 
                child: formContent
              )
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [brandColor, Color(0xFF000000)],
                  ),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                            ),
                            padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
                            child: formContent,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.black26, size: 20),
        suffixIcon: isPassword 
          ? IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black26, size: 18),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            )
          : null,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF1CBABE), width: 2)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      validator: validator,
    );
  }
}
