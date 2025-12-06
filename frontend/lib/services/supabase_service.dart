import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/photo_post.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  // PICK IMAGE
  Future<XFile?> pickImage() async {
    final picker = ImagePicker();
    return await picker.pickImage(source: ImageSource.gallery);
  }

  // UPLOAD KE BACKEND upload.js
  Future<void> uploadToBackend({
    required XFile file,
    required String caption,
  }) async {
    final uri = Uri.parse("https://YOUR_BACKEND_URL/api/upload");

    final request = HttpClient();
    final httpReq = await request.postUrl(uri);

    // multipart/form-data
    final boundary = "----SnapFeedFormData";
    httpReq.headers.set("Content-Type", "multipart/form-data; boundary=$boundary");

    final fileBytes = await file.readAsBytes();
    final fileName = file.path.split('/').last;
    final fileExt = fileName.split('.').last;

    // Multipart body
    final builder = StringBuffer();
    builder.writeln("--$boundary");
    builder.writeln('Content-Disposition: form-data; name="caption"');
    builder.writeln();
    builder.writeln(caption);

    builder.writeln("--$boundary");
    builder.writeln('Content-Disposition: form-data; name="file"; filename="$fileName"');
    builder.writeln('Content-Type: image/$fileExt');
    builder.writeln();

    httpReq.write(builder.toString());
    httpReq.add(fileBytes);
    httpReq.write("\r\n--$boundary--\r\n");

    final response = await httpReq.close();
    if (response.statusCode != 200) {
      throw Exception("Upload gagal dengan status: ${response.statusCode}");
    }
  }

  // STREAM FEED DARI SUPABASE
  Stream<List<PhotoPost>> getPhotoFeed() {
    return client
        .from('posts')
        .stream(primaryKey: ['id'])
        .order("id", ascending: false)
        .map((rows) => rows.map((e) => PhotoPost.fromJson(e)).toList());
  }
}
