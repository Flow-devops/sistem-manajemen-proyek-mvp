import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/photo_post.dart';
import 'camera_modal.dart';

class PhotoFeedScreen extends StatefulWidget {
  const PhotoFeedScreen({super.key});

  @override
  State<PhotoFeedScreen> createState() => _PhotoFeedScreenState();
}

class _PhotoFeedScreenState extends State<PhotoFeedScreen> {
  final supabase = Supabase.instance.client;
  final PageController controller = PageController();
  int pageIndex = 0;

  Future<List<PhotoPost>> fetchPhotos() async {
    final response = await supabase
        .from('photos')
        .select()
        .order('id', ascending: false);

    return (response as List)
        .map((e) => PhotoPost.fromJson(e))
        .toList();
  }

  void openCameraModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CameraModal(),
    ).then((_) {
      setState(() {}); // refresh
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SnapFeed"),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: openCameraModal,
          ),
        ],
      ),
      body: FutureBuilder<List<PhotoPost>>(
        future: fetchPhotos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada foto."));
          }

          final photos = snapshot.data!;

          return PageView.builder(
            controller: controller,
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final p = photos[index];
              return Column(
                children: [
                  Text(p.username),
                  Expanded(
                    child: Image.network(
                      p.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(p.caption),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
