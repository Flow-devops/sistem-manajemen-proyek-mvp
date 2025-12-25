import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendRequestScreen extends StatefulWidget {
  const FriendRequestScreen({super.key});

  @override
  State<FriendRequestScreen> createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends State<FriendRequestScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool isLoading = true;
  List<Map<String, dynamic>> requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  // ===============================
  // LOAD INCOMING FRIEND REQUESTS
  // ===============================
  Future<void> _loadRequests() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      final res = await _supabase
          .from('friendships')
          .select(
        'id, from_user_id, '
            'profiles!friendships_from_user_id_fkey(full_name, username, avatar_url)',
      )
          .eq('to_user_id', currentUser.id)
          .eq('status', 'pending');

      setState(() {
        requests = List<Map<String, dynamic>>.from(res);
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  // ===============================
  // ACCEPT FRIEND
  // ===============================
  Future<void> _acceptFriend(String friendshipId) async {
    await _supabase.from('friendships').update({
      'status': 'accepted',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', friendshipId);

    _loadRequests();
  }

  // ===============================
  // REJECT FRIEND
  // ===============================
  Future<void> _rejectFriend(String friendshipId) async {
    await _supabase.from('friendships').update({
      'status': 'rejected',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', friendshipId);

    _loadRequests();
  }

  // ===============================
  // BUILD UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Permintaan Pertemanan'),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.white),
      )
          : requests.isEmpty
          ? const Center(
        child: Text(
          'Tidak ada permintaan',
          style: TextStyle(color: Colors.white54),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index];
          final user = req['profiles'];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: user['avatar_url'] != null
                      ? NetworkImage(user['avatar_url'])
                      : null,
                  backgroundColor: Colors.grey,
                  child: user['avatar_url'] == null
                      ? Text(
                    user['username'][0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['full_name'] ?? user['username'],
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        '@${user['username']}',
                        style: const TextStyle(
                            color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.redAccent),
                  onPressed: () => _rejectFriend(req['id']),
                ),
                IconButton(
                  icon: const Icon(Icons.check,
                      color: Colors.greenAccent),
                  onPressed: () => _acceptFriend(req['id']),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
