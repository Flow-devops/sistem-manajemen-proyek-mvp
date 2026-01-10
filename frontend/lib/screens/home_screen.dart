import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'settings_screen.dart';
import 'send_to_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  List posts = [];
  bool loading = true;
  bool _isUploadCooldown = false;

  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier(0);
  final ValueNotifier<String?> _bgNotifier = ValueNotifier(null);

  List<Widget> _floatingAnimations = [];
  final GlobalKey _loveIconKey = GlobalKey();
  final GlobalKey _likeIconKey = GlobalKey();

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    loadPosts();
    NotificationService.updateToken();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentIndexNotifier.dispose();
    _bgNotifier.dispose();
    super.dispose();
  }

  void _showTopNotification(String message, {bool isError = false}) {
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) =>
          Positioned(
            top: MediaQuery
                .of(context)
                .padding
                .top + 10,
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
                      offset: Offset(0, value), child: child);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isError
                        ? Colors.redAccent.withOpacity(0.9)
                        : const Color(0xFF1CBABE).withOpacity(0.9),
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
                      Icon(
                        isError ? Icons.error_outline : Icons
                            .check_circle_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          message,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
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

  Future<void> loadPosts() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      final myId = supabase.auth.currentUser!.id;
      final friendshipData = await supabase.from('friendships').select(
          'from_user_id, to_user_id').eq('status', 'accepted').or(
          'from_user_id.eq.$myId,to_user_id.eq.$myId');
      List<String> friendIds = [myId];
      for (var row in friendshipData) {
        if (row['from_user_id'] == myId) {
          friendIds.add(row['to_user_id'] as String);
        } else {
          friendIds.add(row['from_user_id'] as String);
        }
      }
      final data = await supabase.from("posts").select().filter(
          'user_id', 'in', friendIds).order("created_at", ascending: false);
      final userIds = data.map((p) => p['user_id']).toSet().toList();
      final profilesData = await supabase.from('profiles').select(
          'id, username, avatar_url').filter('id', 'in', userIds);
      final profileMap = {for (var p in profilesData) p['id']: p};
      final now = DateTime.now();
      List myPosts = [];
      List friendsPosts = [];
      for (var post in data) {
        post['profiles'] = profileMap[post['user_id']];
        final exp = DateTime.parse(post["expires_at"]);
        if (exp.isAfter(now)) {
          if (post['user_id'] == myId) {
            myPosts.add(post);
          } else {
            friendsPosts.add(post);
          }
        }
      }
      if (!mounted) return;
      setState(() {
        posts = [...myPosts, ...friendsPosts];
        loading = false;

        // Cek apakah user punya post sendiri
        final hasMyPost = posts.any((p) => p['user_id'] == myId);

        if (posts.isNotEmpty) {
          if (!hasMyPost) {
            // Jika tidak ada post sendiri, index 0 adalah slide kosong (no background)
            _bgNotifier.value = null;
            _currentIndexNotifier.value = 0;
            // Langsung arahkan ke post pertama orang lain (index 1) agar tidak stuck di slide kosong
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (_pageController.hasClients) _pageController.jumpToPage(1);
            });
          } else {
            _bgNotifier.value = posts[0]["image_url"];
            _currentIndexNotifier.value = 0;
          }
        } else {
          _bgNotifier.value = null;
        }
      });
    } catch (e) {
      debugPrint("Error loading posts: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text(
                "Delete Status", style: TextStyle(color: Colors.white)),
            content: const Text("Are you sure you want to delete this status?",
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                      "Delete", style: TextStyle(color: Colors.redAccent))),
            ],
          ),
    );
    if (confirmed == true) {
      try {
        await supabase.from('posts').delete().eq('id', postId);
        loadPosts();
        _showTopNotification('Status deleted!');
      } catch (e) {
        debugPrint("Error deleting post: $e");
      }
    }
  }

  Future<void> _downloadImage(String url) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/downloaded_image.jpg';
      await Dio().download(url, path);
      await Gal.putImage(path);
      _showTopNotification('Saved to gallery!');
    } catch (e) {
      _showTopNotification('Failed to save image', isError: true);
    }
  }

  void _addFloatingAnimation(String assetPath, GlobalKey key) {
    final RenderBox? renderBox = key.currentContext
        ?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final id = DateTime
        .now()
        .millisecondsSinceEpoch;

    setState(() {
      _floatingAnimations.add(
        _FloatingWidget(
          key: ValueKey(id),
          assetPath: assetPath,
          startX: position.dx + (size.width / 2),
          startY: position.dy,
          onComplete: () {
            if (mounted) {
              setState(() {
                _floatingAnimations.removeWhere((w) => w.key == ValueKey(id));
              });
            }
          },
        ),
      );
    });
  }

  Future<void> _sendCommentAsMessage(String content) async {
    if (content.isEmpty || posts.isEmpty) return;

    final currentUserId = supabase.auth.currentUser?.id;
    final hasMyPost = posts.any((p) => p['user_id'] == currentUserId);
    final currentIdx = _currentIndexNotifier.value;

    // Sesuaikan index jika ada slide kosong di depan
    int postIdx = (!hasMyPost) ? currentIdx - 1 : currentIdx;

    if (postIdx < 0 || postIdx >= posts.length) return;

    final currentPost = posts[postIdx];
    final postOwnerId = currentPost['user_id'];
    final myId = supabase.auth.currentUser!.id;
    if (postOwnerId == myId) return;
    try {
      final room = await supabase.rpc('get_or_create_room',
          params: {'p_user1': myId, 'p_user2': postOwnerId});
      await supabase.from('messages').insert({
        'room_id': room,
        'sender_id': myId,
        'content': "💬 Membalas status Anda: \"$content\"",
        'created_at': DateTime.now().toIso8601String()
      });
      _showTopNotification('Sent to chat!');
    } catch (e) {
      debugPrint("Error sending comment: $e");
    }
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 15, bottom: 10),
                child: Text(
                  'Create a new status',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                    Icons.photo_library_outlined, color: Colors.white70),
                title: Text('Upload from Gallery', style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageAndPreview(ImageSource.gallery);
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              ListTile(
                leading: const Icon(
                    Icons.camera_alt_outlined, color: Colors.white70),
                title: Text('Open Camera', style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageAndPreview(ImageSource.camera);
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              SizedBox(height: MediaQuery
                  .of(context)
                  .padding
                  .bottom + 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser?.id;
    final hasMyPost = posts.any((p) => p['user_id'] == currentUserId);
    final totalItems = (posts.isNotEmpty && !hasMyPost)
        ? posts.length + 1
        : posts.length;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          ValueListenableBuilder<String?>(
            valueListenable: _bgNotifier,
            builder: (context, bgUrl, _) {
              if (bgUrl == null) return Container(color: Colors.black);
              return Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _BlurredBackground(
                      key: ValueKey(bgUrl), imageUrl: bgUrl),
                ),
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 10),

                Expanded(
                  child: loading
                      ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                      : posts.isEmpty
                      ? Center(child: _EmptyState(onAdd: _showUploadOptions))
                      : PageView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    controller: _pageController,
                    itemCount: totalItems,
                    onPageChanged: (index) {
                      if (!hasMyPost) {
                        if (index == 0) {
                          _bgNotifier.value = null;
                        } else {
                          _bgNotifier.value = posts[index - 1]["image_url"];
                        }
                      } else {
                        _bgNotifier.value = posts[index]["image_url"];
                      }
                      _currentIndexNotifier.value = index;
                    },
                    itemBuilder: (_, index) {
// Jika tidak ada status sendiri, index 0 jadi slide kosong (Kamera)
                      if (!hasMyPost && index == 0) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Container Icon Glassmorphism (Ukuran Diperkecil)
                                Container(
                                  height: 90, // Lebih kecil dari EmptyState
                                  width: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF1CBABE).withOpacity(
                                        0.05),
                                    border: Border.all(
                                      color: const Color(0xFF1CBABE)
                                          .withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        height: 40,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF1CBABE)
                                                  .withOpacity(0.2),
                                              blurRadius: 30,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 35, // Diperkecil
                                        color: Colors.white24,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 25),
                                Text(
                                  "Ready to Share?",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 18, // Ukuran teks diperkecil
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Tap the camera below to capture your moment.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white54,
                                    fontSize: 13, // Ukuran teks diperkecil
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Ambil post dengan penyesuaian index jika ada slide kosong di depan
                      final post = hasMyPost ? posts[index] : posts[index - 1];
                      final isMe = post['user_id'] == currentUserId;

                      return _PostItem(
                        key: ValueKey(post['id']),
                        post: post,
                        isMe: isMe,
                        onDelete: () => _deletePost(post['id']),
                        onDownload: () => _downloadImage(post['image_url']),
                      );
                    },
                  ),
                ),

                ValueListenableBuilder<int>(
                  valueListenable: _currentIndexNotifier,
                  builder: (context, idx, _) {
                    bool showMessageBar = false;
                    bool showBottomActions = true;

                    if (posts.isNotEmpty) {
                      if (!hasMyPost) {
                        if (idx == 0) {
                          showMessageBar = false;
                          showBottomActions = true;
                        } else {
                          showMessageBar = true;
                          showBottomActions = false;
                        }
                      } else {
                        final isOwnPost = posts[idx]["user_id"] ==
                            currentUserId;
                        showMessageBar = !isOwnPost;
                        showBottomActions = isOwnPost;
                      }
                    } else if (posts.isEmpty) {
                      showMessageBar = false;
                      showBottomActions = false;
                    }

                    return Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 400),
                          opacity: showMessageBar ? 1.0 : 0.0,
                          curve: Curves.easeInOut,
                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 400),
                            offset: showMessageBar ? Offset.zero : const Offset(
                                0, 0.4),
                            curve: Curves.easeOutCubic,
                            child: IgnorePointer(
                              ignoring: !showMessageBar,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 60),
                                child: _buildMessageBar(),
                              ),
                            ),
                          ),
                        ),

                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 400),
                          opacity: showBottomActions ? 1.0 : 0.0,
                          curve: Curves.easeInOut,
                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 400),
                            offset: showBottomActions
                                ? Offset.zero
                                : const Offset(0, 0.4),
                            curve: Curves.easeOutCubic,
                            child: IgnorePointer(
                              ignoring: !showBottomActions,
                              child: _buildBottomActions(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          ..._floatingAnimations,
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
          CircleAvatar(radius: 18,
              backgroundColor: Colors.white24,
              child: IconButton(icon: const Icon(
                  Icons.settings, size: 20, color: Colors.white),
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const SettingsScreen())))),
          CircleAvatar(radius: 18,
              backgroundColor: Colors.white24,
              child: IconButton(icon: const Icon(
                  Icons.chat_bubble_outline, color: Colors.white),
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const ChatScreen())))),
        ],
      ),
    );
  }

  Widget _buildMessageBar() {
    final TextEditingController localCommentController = TextEditingController();
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: localCommentController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(hintText: "Send message...",
                      hintStyle: TextStyle(color: Colors.white60, fontSize: 14),
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 10)),
                  onSubmitted: (val) {
                    _sendCommentAsMessage(val);
                    localCommentController.clear();
                  },
                ),
              ),
              GestureDetector(
                  key: _loveIconKey,
                  onTap: () {
                    _addFloatingAnimation(
                        'assets/animations/love.json', _loveIconKey);
                    _sendCommentAsMessage("❤️");
                  },
                  child: const Icon(Icons.favorite, color: Colors.red, size: 22)
              ),
              const SizedBox(width: 10),
              GestureDetector(
                  key: _likeIconKey,
                  onTap: () {
                    _addFloatingAnimation(
                        'assets/animations/like.json', _likeIconKey);
                    _sendCommentAsMessage("👍");
                  },
                  child: const Icon(
                      Icons.thumb_up, color: Colors.blue, size: 22)
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
        padding: const EdgeInsets.fromLTRB(24, 15, 24, 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _roundIcon(Icons.photo_library, () =>
                _pickImageAndPreview(ImageSource.gallery)),
            const SizedBox(width: 25),
            _roundIconBig(Icons.camera_alt, () =>
                _pickImageAndPreview(ImageSource.camera)),
          ],
        ),
      ),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap) {
    return Container(height: 50,
        width: 50,
        decoration: BoxDecoration(shape: BoxShape.circle,
            border: Border.all(width: 4, color: const Color(0xFF1CBABE))),
        child: IconButton(
            icon: Icon(icon, color: Colors.white), onPressed: onTap));
  }

  Widget _roundIconBig(IconData icon, VoidCallback onTap) {
    return Container(height: 78,
        width: 78,
        decoration: BoxDecoration(shape: BoxShape.circle,
            border: Border.all(width: 5, color: const Color(0xFF1CBABE))),
        child: IconButton(
            icon: Icon(icon, size: 32, color: Colors.white), onPressed: onTap));
  }

  Future<void> _pickImageAndPreview(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
        source: source, maxWidth: 1080, maxHeight: 1920, imageQuality: 80);
    if (pickedFile == null) return;
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          SendToScreen(imageUrl: pickedFile.path, onSend: _handleSend)));
    }
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
      'caption': caption.isEmpty ? '' : caption,
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime
          .now()
          .add(const Duration(hours: 24))
          .toIso8601String()
    });
    loadPosts();
  }
}

class _PostItem extends StatefulWidget {
  final dynamic post;
  final bool isMe;
  final VoidCallback onDelete;
  final VoidCallback onDownload;

  const _PostItem(
      {super.key, required this.post, required this.isMe, required this.onDelete, required this.onDownload});

  @override
  State<_PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<_PostItem> with TickerProviderStateMixin {
  late AnimationController _loveController;
  bool _showLove = false;

  @override
  void initState() {
    super.initState();
    _loveController = AnimationController(vsync: this);
    _loveController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) setState(() => _showLove = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _loveController.dispose();
    super.dispose();
  }

  void _triggerLove() {
    if (_showLove) return;
    if (mounted) {
      setState(() => _showLove = true);
      _loveController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.post['profiles'];
    final avatarUrl = profile != null ? profile['avatar_url'] : null;
    final username = profile != null ? profile['username'] : "user";
    final hasCaption = widget.post["caption"] != null && widget.post["caption"]
        .toString()
        .trim()
        .isNotEmpty;

    return Align(
      alignment: Alignment.center,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onDoubleTap: _triggerLove,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 5,
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2)
                            ]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CachedNetworkImage(
                                  imageUrl: widget.post["image_url"],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(
                                      color: Colors.grey[900],
                                      child: const Center(
                                          child: CircularProgressIndicator(
                                              color: Color(0xFF1CBABE)))),
                                  errorWidget: (context, url, error) =>
                                      Container(color: Colors.grey[900],
                                          child: const Icon(Icons.error,
                                              color: Colors.white)),
                                  memCacheWidth: 800,
                                ),
                              ),
                              if (_showLove)
                                Positioned.fill(
                                  child: Lottie.asset(
                                    'assets/animations/love.json',
                                    controller: _loveController,
                                    fit: BoxFit.cover,
                                    repeat: false,
                                    frameRate: FrameRate.composition,
                                    onLoaded: (composition) {
                                      _loveController.duration =
                                          composition.duration;
                                      _loveController.forward(from: 0);
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (hasCaption)
                      Positioned(
                        bottom: 25,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                widget.post["caption"],
                                style: GoogleFonts.poppins(
                                    color: Colors.white, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),

                    if (widget.isMe) Positioned(bottom: 15,
                        left: 15,
                        child: CircleAvatar(backgroundColor: Colors.black45,
                            radius: 18,
                            child: IconButton(padding: EdgeInsets.zero,
                                icon: const Icon(
                                    Icons.download_rounded, color: Colors.white,
                                    size: 18),
                                onPressed: widget.onDownload))),
                    if (widget.isMe) Positioned(bottom: 15,
                        right: 15,
                        child: CircleAvatar(
                            backgroundColor: Colors.redAccent.withOpacity(0.8),
                            radius: 18,
                            child: IconButton(padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.white, size: 18),
                                onPressed: widget.onDelete))),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(radius: 12,
                        backgroundColor: Colors.white24,
                        backgroundImage: (avatarUrl != null &&
                            avatarUrl.isNotEmpty) ? CachedNetworkImageProvider(
                            avatarUrl) : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? const Icon(
                            Icons.person, size: 14, color: Colors.white)
                            : null),
                    const SizedBox(width: 8),
                    Text(
                      username,
                      style: GoogleFonts.poppins(color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlurredBackground extends StatelessWidget {
  final String imageUrl;

  const _BlurredBackground({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              memCacheWidth: 80,
              filterQuality: FilterQuality.low,
            ),
          ),
        ),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // Agar column tidak memakan ruang berlebih
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Container Icon Glassmorphism (Skala Kecil)
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1CBABE).withOpacity(0.05),
                border: Border.all(
                  color: const Color(0xFF1CBABE).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1CBABE).withOpacity(0.2),
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 32,
                    color: Colors.white24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Your Feed is Quiet",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18, // Ukuran teks diperkecil
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Share what you're up to right now.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 25),
            // Button Lebih Kecil & Simpel
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1CBABE), Color(0xFF169A9D)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'Share Status',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingWidget extends StatefulWidget {
  final String assetPath;
  final double startX;
  final double startY;
  final VoidCallback onComplete;

  const _FloatingWidget(
      {super.key, required this.assetPath, required this.startX, required this.startY, required this.onComplete});

  @override
  State<_FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<_FloatingWidget>
    with TickerProviderStateMixin {
  late AnimationController _movementController;
  late AnimationController _lottieController;
  late Animation<double> _xAnimation, _yAnimation, _sizeAnimation,
      _opacityAnimation;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _movementController = AnimationController(vsync: this);
    _lottieController = AnimationController(vsync: this);

    _lottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) widget.onComplete();
        });
      }
    });
  }

  void _initAnimations(Size size, Duration lottieDuration) {
    if (_initialized) return;

    _movementController.duration = lottieDuration;

    _xAnimation =
        Tween<double>(begin: widget.startX, end: size.width / 2).animate(
            CurvedAnimation(
                parent: _movementController, curve: Curves.easeOutQuart));
    _yAnimation =
        Tween<double>(begin: widget.startY, end: size.height / 2).animate(
            CurvedAnimation(
                parent: _movementController, curve: Curves.easeOutQuart));
    _sizeAnimation = Tween<double>(begin: 40, end: 250).animate(
        CurvedAnimation(parent: _movementController, curve: Curves.elasticOut));

    _opacityAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15)
    ]).animate(_movementController);

    _movementController.forward();
    _initialized = true;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _movementController.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _movementController,
      builder: (context, child) {
        if (!_initialized) {
          return Opacity(
            opacity: 0,
            child: Lottie.asset(
              widget.assetPath,
              controller: _lottieController,
              onLoaded: (composition) {
                _lottieController.duration = composition.duration;
                _initAnimations(
                    MediaQuery.sizeOf(context), composition.duration);
                _lottieController.forward(from: 0);
              },
            ),
          );
        }

        final currentSize = _sizeAnimation.value;
        return Positioned(
          left: _xAnimation.value - (currentSize / 2),
          top: _yAnimation.value - (currentSize / 2),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: IgnorePointer(
              child: Lottie.asset(
                widget.assetPath,
                controller: _lottieController,
                width: currentSize,
                height: currentSize,
                fit: BoxFit.contain,
                repeat: false,
                frameRate: FrameRate.composition,
              ),
            ),
          ),
        );
      },
    );
  }
}