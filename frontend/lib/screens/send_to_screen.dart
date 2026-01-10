import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SendToScreen extends StatefulWidget {
  final String imageUrl;
  final Future<void> Function(String path, String caption) onSend;

  const SendToScreen({super.key, required this.imageUrl, required this.onSend});

  @override
  State<SendToScreen> createState() => _SendToScreenState();
}

class _SendToScreenState extends State<SendToScreen> {
  final TextEditingController _captionController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // Fungsi Notifikasi Premium di Bagian Atas
  void _showTopNotification(String message, {bool isError = false}) {
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
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? Colors.redAccent.withOpacity(0.9) : const Color(0xFF1CBABE).withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      message,
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
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
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  Future<void> _handleSend() async {
    if (_isSending) return;
    setState(() => _isSending = true);
    try {
      await widget.onSend(widget.imageUrl, _captionController.text.trim());
      if (mounted) {
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        _showTopNotification("Upload failed: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF1CBABE);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. IMAGE PREVIEW (FULLSCREEN)
          Positioned.fill(
            child: Image.file(
              File(widget.imageUrl),
              fit: BoxFit.cover,
            ),
          ),

          // 2. TOP OVERLAY (Back Button)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 150,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: CircleAvatar(
                      backgroundColor: Colors.black26,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. BOTTOM OVERLAY (Caption & Send)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // GLASSMORPHISM CAPTION INPUT
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: TextField(
                          controller: _captionController,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
                          maxLines: 3,
                          minLines: 1,
                          cursorColor: brandColor,
                          decoration: InputDecoration(
                            hintText: "Write a caption...",
                            hintStyle: GoogleFonts.poppins(color: Colors.white54),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 15),
                            filled: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // SEND BUTTON
                  GestureDetector(
                    onTap: _handleSend,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 45,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: brandColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: brandColor.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Center(
                        child: _isSending
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "SHARE STORY",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
