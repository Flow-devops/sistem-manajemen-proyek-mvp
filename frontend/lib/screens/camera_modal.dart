import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class CameraModal extends StatefulWidget {
  const CameraModal({super.key});

  @override
  State<CameraModal> createState() => _CameraModalState();
}

class _CameraModalState extends State<CameraModal> {
  final picker = ImagePicker();
  File? selectedImage;
  final captionController = TextEditingController();
  final supabase = Supabase.instance.client;

  Future<void> pickFromGallery() async {
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => selectedImage = File(file.path));
  }

  Future<void> pickFromCamera() async {
    final XFile? file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) setState(() => selectedImage = File(file.path));
  }

  Future<void> upload() async {
    if (selectedImage == null) return;

    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await supabase.storage
        .from('photos')
        .upload(fileName, selectedImage!);

    final publicUrl =
    supabase.storage.from('photos').getPublicUrl(fileName);

    await supabase.from('photos').insert({
      'username': 'UserTest',     // TODO: ganti dengan user login
      'caption': captionController.text,
      'image_url': publicUrl,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: pickFromCamera,
                  child: const Text("Ambil Foto"),
                ),
                ElevatedButton(
                  onPressed: pickFromGallery,
                  child: const Text("Pilih dari Gallery"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedImage != null)
              Expanded(
                child: Image.file(selectedImage!),
              ),
            TextField(
              controller: captionController,
              decoration: const InputDecoration(
                labelText: "Caption",
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: upload,
              child: const Text("Upload"),
            ),
          ],
        ),
      ),
    );
  }
}
