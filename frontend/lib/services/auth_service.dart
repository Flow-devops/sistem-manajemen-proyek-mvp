import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Register new user
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
        },
      );

      if (response.user != null) {
        // Profile akan otomatis dibuat oleh trigger database
        // Tapi kita bisa update data tambahan di sini jika perlu
        await _updateProfile(
          userId: response.user!.id,
          fullName: fullName.trim(),
        );
      }

      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Gagal mendaftar: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Gagal login: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Gagal logout: ${e.toString()}');
    }
  }

  // Reset password (send email)
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'flow://reset-password', // Deep link untuk mobile
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Gagal mengirim email reset: ${e.toString()}');
    }
  }

  // Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      return await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Gagal update password: ${e.toString()}');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      throw Exception('Gagal mengambil profil: ${e.toString()}');
    }
  }

  // Update user profile
  Future<void> _updateProfile({
    required String userId,
    required String fullName,
  }) async {
    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'full_name': fullName,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Log error tapi jangan throw, karena user sudah terdaftar
      print('Warning: Failed to update profile - ${e.toString()}');
    }
  }

  // Update profile data
  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final updates = <String, dynamic>{
        'id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;

      await _supabase.from('profiles').upsert(updates);
    } catch (e) {
      throw Exception('Gagal update profil: ${e.toString()}');
    }
  }

  // Handle auth exceptions dengan pesan user-friendly
  String _handleAuthException(AuthException e) {
    switch (e.statusCode) {
      case '400':
        if (e.message.contains('already registered')) {
          return 'Email sudah terdaftar. Silakan login atau gunakan email lain.';
        }
        return 'Data yang dimasukkan tidak valid.';
      case '422':
        if (e.message.contains('email')) {
          return 'Format email tidak valid.';
        }
        if (e.message.contains('password')) {
          return 'Password harus minimal 6 karakter.';
        }
        return 'Data tidak valid.';
      default:
        if (e.message.contains('Invalid login credentials')) {
          return 'Email atau password salah.';
        }
        if (e.message.contains('Email not confirmed')) {
          return 'Silakan verifikasi email Anda terlebih dahulu.';
        }
        return e.message;
    }
  }
}