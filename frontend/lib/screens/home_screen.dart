// lib/screens/home_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// ===================== MODEL =====================
class PhotoPost {
  final String id;
  final String userId;
  final String imageUrl;
  final String caption;
  final DateTime createdAt;

  PhotoPost({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
  });

  factory PhotoPost.fromJson(Map<String, dynamic> json) {
    return PhotoPost(
      id: json['id'].toString(),
      userId: json['user_id']?.toString() ?? '',
      imageUrl: json['image_url'] ?? '',
      caption: json['caption'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

// ===================== HOME SCREEN =====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();

  // Ganti jika server berjalan di alamat lain.
  // Untuk Android emulator gunakan: http://10.0.2.2:3000
  // Untuk iOS simulator / mac: http://localhost:3000
  final String backendBaseUrl = "http://10.0.2.2:3000";

  int _currentPage = 0;

  Stream<List<PhotoPost>> photoStream() {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) {
      final list = (rows as List).map((e) {
        final map = Map<String, dynamic>.from(e);
        return PhotoPost.fromJson(map);
      }).toList();
      return list;
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_pageListener);
  }

  void _pageListener() {
    final p = _pageController.page;
    if (p == null) return;
    final next = p.round();
    if (_currentPage != next) {
      setState(() => _currentPage = next);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_pageListener);
    _pageController.dispose();
    super.dispose();
  }

  // Buka modal kamera (preview + caption + upload)
  void _openCamera(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CameraUploadModal(
        picker: _picker,
        backendUrl: backendBaseUrl + '/api/uploads',
      ),
    );
  }

  Widget _buildNavigationButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        padding: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SnapFeed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.indigo, size: 28),
            onPressed: () => _openCamera(context),
            tooltip: 'Buka Kamera',
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: 500,
          child: Column(
            children: [
              // Feed: realtime via Supabase stream
              Expanded(
                child: StreamBuilder<List<PhotoPost>>(
                  stream: photoStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final photos = snapshot.data ?? [];
                    if (photos.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library, size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Belum ada foto yang diunggah.', style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(height: 8),
                            Text('Tekan ikon kamera untuk mengunggah foto.', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      );
                    }

                    // adjust current page if out of range
                    if (_currentPage >= photos.length) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_pageController.hasClients) {
                          _pageController.jumpToPage(photos.length - 1);
                        }
                      });
                    }

                    return Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: photos.length,
                          itemBuilder: (context, index) => PhotoCard(post: photos[index]),
                        ),

                        if (_currentPage > 0)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: _buildNavigationButton(
                                Icons.arrow_back_ios,
                                    () => _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
                              ),
                            ),
                          ),

                        if (_currentPage < photos.length - 1)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: _buildNavigationButton(
                                Icons.arrow_forward_ios,
                                    () => _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              // Dot indicator (hooked to same stream)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: StreamBuilder<List<PhotoPost>>(
                  stream: photoStream(),
                  builder: (context, snapshot) {
                    final photos = snapshot.data ?? [];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(photos.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          height: 8.0,
                          width: _currentPage == index ? 24.0 : 8.0,
                          decoration: BoxDecoration(
                            color: _currentPage == index ? Colors.indigo : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeIn),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== PHOTO CARD (UI tetap sama) ====================
class PhotoCard extends StatelessWidget {
  final PhotoPost post;
  const PhotoCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - show userId because your table doesn't have username column
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    child: Text(
                      post.userId.isNotEmpty ? post.userId[0].toUpperCase() : '?',
                      style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(post.userId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),

            // Photo
            Expanded(
              child: Image.network(
                post.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, _, __) => Container(
                  color: Colors.grey.shade300,
                  child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                ),
              ),
            ),

            // Caption
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
                  children: <TextSpan>[
                    TextSpan(text: '${post.userId} ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    TextSpan(text: post.caption, style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== CAMERA + PREVIEW + UPLOAD MODAL ====================
class CameraUploadModal extends StatefulWidget {
  final ImagePicker picker;
  final String backendUrl; // full url to POST /api/uploads

  const CameraUploadModal({super.key, required this.picker, required this.backendUrl});

  @override
  State<CameraUploadModal> createState() => _CameraUploadModalState();
}

class _CameraUploadModalState extends State<CameraUploadModal> {
  XFile? _pickedFile;
  bool _isUploading = false;
  final TextEditingController _captionController = TextEditingController();

  Future<void> _takePhoto() async {
    final XFile? file = await widget.picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file != null) {
      setState(() => _pickedFile = file);
    }
  }

  // Upload to backend (multipart/form-data)
  Future<void> _uploadToBackend() async {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih foto terlebih dahulu')));
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harus login terlebih dahulu')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final uri = Uri.parse(widget.backendUrl);
      final request = http.MultipartRequest('POST', uri);

      request.fields['user_id'] = user.id;
      request.fields['caption'] = _captionController.text.trim();

      // field name must match server: server uses upload.single("image")
      final fileBytes = await _pickedFile!.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.name}';
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          fileBytes,
          filename: fileName,
        ),
      );


      final streamed = await request.send();
      final respStr = await streamed.stream.bytesToString();

      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        // success - server returns JSON { message, imageUrl }
        final jsonResp = jsonDecode(respStr);
        if (jsonResp != null && jsonResp['imageUrl'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload berhasil')));
          // Close modal; Supabase stream will pick up new row inserted by server
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload berhasil, tapi server tidak mengembalikan URL.')));
          Navigator.pop(context);
        }
      } else {
        final jsonResp = respStr.isNotEmpty ? jsonDecode(respStr) : null;
        final errMsg = jsonResp != null && jsonResp['error'] != null ? jsonResp['error'] : 'Status ${streamed.statusCode}';
        throw Exception(errMsg);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload gagal: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // Helper to get MediaType for MultipartFile
  MediaType? _getMediaType(String path) {
    // import can't add package:http_parser here without extra dep; simpler to return null
    // http.MultipartFile will set default content-type if null; but we can try common extensions.
    final ext = path.split('.').last.toLowerCase();
    final mime = <String, String>{
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp'
    }[ext];
    if (mime == null) return null;
    return MediaType.parse(mime);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.centerRight, child: IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => Navigator.pop(context))),
          const Text('Ambil Foto & Unggah', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo), textAlign: TextAlign.center),
          const SizedBox(height: 12),

          // button take photo
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton.icon(onPressed: _takePhoto, icon: const Icon(Icons.camera_alt), label: const Text('Ambil Foto')),
          ]),

          const SizedBox(height: 12),

          // preview area
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
              child: _pickedFile == null
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.add_a_photo, size: 48, color: Colors.grey), SizedBox(height: 8), Text('Belum ada foto. Tekan "Ambil Foto" untuk mulai.')]))
                  : ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_pickedFile!.path), fit: BoxFit.cover, width: double.infinity)),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _captionController,
            decoration: InputDecoration(labelText: 'Tulis caption (opsional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            maxLines: 2,
          ),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: _isUploading ? null : _uploadToBackend,
            icon: _isUploading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.cloud_upload),
            label: Text(_isUploading ? 'Mengunggah...' : 'Unggah ke Server'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ],
      ),
    );
  }
}

// Minimal MediaType helper (avoid extra dependency)
// If package:http_parser is available, replace this with MediaType from that package.
class MediaType {
  final String mime;
  MediaType(this.mime);
  static MediaType parse(String mime) => MediaType(mime);
  @override
  String toString() => mime;
}
