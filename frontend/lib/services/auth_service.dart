// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // SIGN UP dengan username
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username, // gunakan username
    String? fullName, // opsional
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'full_name': fullName,
      },
    );

    // Masukkan/Perbarui record profiles secara eksplisit
    if (response.user != null) {
      await _supabase.from('profiles').upsert({
        'id': response.user!.id,
        'username': username.trim(),
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    return response;
  }

  // SIGN IN
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // RESET PASSWORD (kirim email reset)
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      // sesuaikan redirect jika perlu
      redirectTo: 'flow://reset-password',
    );
  }

  // SIGN OUT
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Ambil profile dari tabel profiles
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final res = await _supabase.from('profiles').select().eq('id', userId).single();
    return res;
  }
}
