import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameController = TextEditingController();
  DateTime? _birthday;
  File? _image;
  String? _existingAvatarUrl;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Flexible(child: Text(message, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14))),
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

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      _usernameController.text = data['username'] ?? '';
      _existingAvatarUrl = data['avatar_url'];
      if (data['birthday'] != null) {
        _birthday = DateTime.parse(data['birthday']);
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    if (_usernameController.text.trim().isEmpty) {
      _showTopNotification("Username cannot be empty", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      String? avatarUrl = _existingAvatarUrl;

      if (_image != null) {
        final path = 'avatars/${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('avatars').upload(
          path,
          _image!,
          fileOptions: const FileOptions(upsert: true),
        );
        avatarUrl = supabase.storage.from('avatars').getPublicUrl(path);
      }

      await supabase.from('profiles').update({
        'username': _usernameController.text.trim(),
        'birthday': _birthday?.toIso8601String(),
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      }).eq('id', user.id);

      if (mounted) {
        Navigator.pop(context, true);
        _showTopNotification("Profile updated successfully!");
      }
    } catch (e) {
      _showTopNotification("Update failed: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        _buildPhotoSection(),
                        const SizedBox(height: 40),
                        _buildFormSection(),
                      ],
                    ),
                  ),
                ),
                _buildSaveButton(),
              ],
            ),
          ),

          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1CBABE),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            "Edit Profile",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _image != null
                  ? FileImage(_image!)
                  : (_existingAvatarUrl != null
                      ? NetworkImage(_existingAvatarUrl!)
                      : null) as ImageProvider?,
              child: (_image == null && _existingAvatarUrl == null)
                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 4,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1CBABE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputLabel("Username"),
        TextField(
          controller: _usernameController,
          style: GoogleFonts.poppins(fontSize: 15),
          decoration: InputDecoration(
            hintText: "Enter your username",
            filled: true,
            fillColor: Colors.black.withOpacity(0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.alternate_email, size: 20),
          ),
        ),
        const SizedBox(height: 25),
        _inputLabel("Birthday"),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _birthday ?? DateTime(2000),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _birthday = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined, size: 20, color: Colors.black54),
                const SizedBox(width: 12),
                Text(
                  _birthday == null
                      ? "Select birthday"
                      : "${_birthday!.day}/${_birthday!.month}/${_birthday!.year}",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: _birthday == null ? Colors.black38 : Colors.black87,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today, size: 16, color: Colors.black38),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _inputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1CBABE),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          "Save Changes",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
