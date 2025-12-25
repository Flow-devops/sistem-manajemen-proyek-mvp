import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'settings_screen.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  List posts = [];
  bool loading = true;
  int currentIndex = 0;

  // Status animasi
  Map<int, bool> _showLoveAnimation = {};
  List<Widget> _floatingAnimations = [];
  bool _isShowingSuccessAnimation = true;

  @override
  void initState() {
    super.initState();
    loadPosts();
    _startSuccessTimer();
  }

  void _startSuccessTimer() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _isShowingSuccessAnimation = false);
  }

  Future<void> loadPosts() async {
    try {
      final data = await supabase
          .from("posts")
          .select()
          .order("created_at", ascending: false);

      final now = DateTime.now();
      final filtered = data.where((p) {
        final exp = DateTime.parse(p["expires_at"]);
        return exp.isAfter(now);
      }).toList();

      setState(() {
        posts = filtered;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  // Fungsi memicu animasi melayang ke atas
  void _addFloatingAnimation(String url) {
    final id = DateTime
        .now()
        .millisecondsSinceEpoch;
    setState(() {
      _floatingAnimations.add(
        _FloatingWidget(
          key: ValueKey(id),
          url: url,
          onComplete: () {
            setState(() {
              _floatingAnimations.removeWhere((w) => w.key == ValueKey(id));
            });
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser?.id;
    bool isOwnPost = false;
    if (posts.isNotEmpty && currentIndex < posts.length) {
      isOwnPost = posts[currentIndex]["user_id"] == currentUserId;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 10),

                // AREA POSTINGAN
                Expanded(
                  child: posts.isEmpty && !loading
                      ? _buildEmptyState()
                      : PageView.builder(
                    controller: PageController(viewportFraction: 0.92),
                    itemCount: posts.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                        _showLoveAnimation.clear(); // RESET ANIMASI SAAT SWIPE
                      });
                    },
                    itemBuilder: (_, index) {
                      final post = posts[index];
                      return _buildPostItem(post, index);
                    },
                  ),
                ),

                // MESSAGE BAR (Hanya muncul jika BUKAN post sendiri)
                if (posts.isNotEmpty && !isOwnPost) _buildMessageBar(),

                // NAVIGATION BUTTONS (Selalu muncul)
                _buildBottomActions(),
              ],
            ),
          ),

          // Layer Animasi Melayang
          ..._floatingAnimations,

          // Overlay Sukses Awal - DIPERBAIKI
          if (_isShowingSuccessAnimation) _buildInitialOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.black12,
            child: IconButton(
              icon: const Icon(Icons.settings, size: 20),
              onPressed: () =>
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen())),
            ),
          ),
          const Text("Everyone",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.black12,
            child: IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () =>
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ChatScreen())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(dynamic post, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          GestureDetector(
            onDoubleTap: () {
              setState(() => _showLoveAnimation[index] = true);
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) setState(() => _showLoveAnimation[index] = false);
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.network(post["image_url"], fit: BoxFit.cover),
                  ),
                ),
                if (_showLoveAnimation[index] == true)
                  Lottie.network(
                    'https://lottie.host/eac00a27-4091-4c2c-9810-3cd16e0b77a4/OqAS7ABo77.json',
                    width: 200,
                    height: 200,
                    repeat: false,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(post["caption"], style: GoogleFonts.poppins()),
        ],
      ),
    );
  }

  Widget _buildMessageBar() {
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(25)),
          child: Row(
            children: [
              const Expanded(child: Text("Send message...")),
              GestureDetector(
                onTap: () =>
                    _addFloatingAnimation(
                        'https://lottie.host/eac00a27-4091-4c2c-9810-3cd16e0b77a4/OqAS7ABo77.json'),
                child: const Icon(Icons.favorite, color: Colors.red, size: 28),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () =>
                    _addFloatingAnimation(
                        'https://lottie.host/31cbe0c9-e981-429c-b7d1-1a5355e018b2/hAKyiZ1UJ6.json'),
                child: const Icon(Icons.thumb_up, color: Colors.blue, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _roundIcon(Icons.photo_library,
                    () => _pickImageAndPreview(ImageSource.gallery)),
            _roundIconBig(Icons.camera_alt,
                    () => _pickImageAndPreview(ImageSource.camera)),
            const Icon(Icons.sentiment_satisfied_alt_outlined, size: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialOverlay() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Lottie.asset(
          'assets/animations/success.json',
          width: 280,
          height: 280,
          fit: BoxFit.contain,
          repeat: false,
          animate: true,
        ),
      ),
    );
  }

  // --- Widget Tambahan (Round Icons, Empty State, etc) ---
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Icon(Icons.add_a_photo_outlined,
                  size: 50, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text("Belum ada foto yang dibagikan.",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
                "Ambil foto atau pilih dari galeri untuk mulai berbagi momen dengan teman!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(width: 4, color: Colors.blueGrey)),
      child: IconButton(icon: Icon(icon), onPressed: onTap),
    );
  }

  Widget _roundIconBig(IconData icon, VoidCallback onTap) {
    return Container(
      height: 78,
      width: 78,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(width: 5, color: Colors.blueGrey)),
      child: IconButton(icon: Icon(icon, size: 32), onPressed: onTap),
    );
  }

  Future<void> _pickImageAndPreview(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                SendToScreen(imageUrl: pickedFile.path, onSend: _handleSend)));
  }

  Future<void> _handleSend(String path, String caption) async {
    final file = File(path);
    final fileName = 'uploads/${DateTime
        .now()
        .millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('uploads').upload(fileName, file);
    final imageUrl = supabase.storage.from('uploads').getPublicUrl(fileName);
    await supabase.from('posts').insert({
      'user_id': supabase.auth.currentUser!.id,
      'image_url': imageUrl,
      'caption': caption.isEmpty ? 'Foto baru' : caption,
      'created_at': DateTime.now().toIso8601String(),
      'expires_at':
      DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    });
    loadPosts();
  }
}

// WIDGET UNTUK ANIMASI MELAYANG KE ATAS
class _FloatingWidget extends StatefulWidget {
  final String url;
  final VoidCallback onComplete;

  const _FloatingWidget(
      {super.key, required this.url, required this.onComplete});

  @override
  State<_FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<_FloatingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _yAnim;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _yAnim = Tween<double>(begin: 0.7, end: 0.1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0)));
    _ctrl.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) =>
          Align(
            alignment: Alignment(0, _yAnim.value),
            child: Opacity(
                opacity: _opacity.value,
                child: Lottie.network(widget.url, width: 200, repeat: false)),
          ),
    );
  }
}

// --- SEND TO SCREEN (Tetap sama) ---
class SendToScreen extends StatefulWidget {
  final String imageUrl;
  final Function(String, String) onSend;

  const SendToScreen({super.key, required this.imageUrl, required this.onSend});

  @override
  State<SendToScreen> createState() => _SendToScreenState();
}

class _SendToScreenState extends State<SendToScreen> {
  final TextEditingController _cap = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            AspectRatio(
                aspectRatio: 1,
                child: Image.file(File(widget.imageUrl), fit: BoxFit.cover)),
            Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                    controller: _cap,
                    decoration: const InputDecoration(hintText: "Caption..."))),
            IconButton(
                icon: const Icon(Icons.send, size: 40),
                onPressed: () {
                  widget.onSend(widget.imageUrl, _cap.text);
                  Navigator.pop(context);
                }),
          ],
        ),
      ),
    );
  }
}