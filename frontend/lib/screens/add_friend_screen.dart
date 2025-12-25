import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchFriendScreen extends StatefulWidget {
  const SearchFriendScreen({super.key});

  @override
  State<SearchFriendScreen> createState() => _SearchFriendScreenState();
}

class _SearchFriendScreenState extends State<SearchFriendScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  bool isSearching = false;
  bool isSending = false;

  Map<String, dynamic>? foundUser;
  String? searchError;

  List<Map<String, dynamic>> incomingRequests = [];
  List<Map<String, dynamic>> sentRequests = [];
  List<Map<String, dynamic>> acceptedFriends = [];

  @override
  void initState() {
    super.initState();
    _loadFriendStatus();
  }

  // ===============================
  // LOAD FRIEND STATUS
  // ===============================
  Future<void> _loadFriendStatus() async {
    final myId = supabase.auth.currentUser!.id;

    incomingRequests.clear();
    sentRequests.clear();
    acceptedFriends.clear();

    // 1️⃣ Incoming Requests (to me)
    final incoming = await supabase
        .from('friendships')
        .select('id, from_user_id')
        .eq('to_user_id', myId)
        .eq('status', 'pending');

    for (final row in incoming) {
      final profile = await supabase
          .from('profiles')
          .select('id, username, avatar_url')
          .eq('id', row['from_user_id'])
          .single();

      incomingRequests.add({
        'friendship_id': row['id'],
        ...profile,
      });
    }

    // 2️⃣ Sent Requests (from me)
    final sent = await supabase
        .from('friendships')
        .select('id, to_user_id')
        .eq('from_user_id', myId)
        .eq('status', 'pending');

    for (final row in sent) {
      final profile = await supabase
          .from('profiles')
          .select('id, username, avatar_url')
          .eq('id', row['to_user_id'])
          .single();

      sentRequests.add({
        'friendship_id': row['id'],
        ...profile,
      });
    }

    // 3️⃣ Accepted Friends
    final accepted = await supabase
        .from('friendships')
        .select('from_user_id, to_user_id')
        .eq('status', 'accepted')
        .or('from_user_id.eq.$myId,to_user_id.eq.$myId');

    for (final row in accepted) {
      final friendId =
      row['from_user_id'] == myId ? row['to_user_id'] : row['from_user_id'];

      final profile = await supabase
          .from('profiles')
          .select('id, username, avatar_url')
          .eq('id', friendId)
          .single();

      acceptedFriends.add(profile);
    }

    setState(() {});
  }

  // ===============================
  // SEARCH USER
  // ===============================
  Future<void> searchUser() async {
    final username = _searchController.text.trim();
    if (username.isEmpty) return;

    setState(() {
      isSearching = true;
      foundUser = null;
      searchError = null;
    });

    final res = await supabase
        .from('profiles')
        .select('id, username, avatar_url')
        .eq('username', username)
        .maybeSingle();

    setState(() {
      isSearching = false;
      foundUser = res;
      if (res == null) searchError = "User tidak ditemukan";
    });
  }

  // ===============================
  // SEND FRIEND REQUEST
  // ===============================
  Future<void> sendFriendRequest(String targetId) async {
    final myId = supabase.auth.currentUser!.id;

    setState(() => isSending = true);

    await supabase.from('friendships').insert({
      'from_user_id': myId,
      'to_user_id': targetId,
      'friend_id': targetId,
      'status': 'pending',
      'updated_at': DateTime.now().toIso8601String(),
    });

    await _loadFriendStatus();
    setState(() => isSending = false);
  }

  // ===============================
  // ACCEPT FRIEND + CREATE CHAT ROOM
  // ===============================
  Future<void> acceptFriend(String friendshipId, String friendId) async {
    final myId = supabase.auth.currentUser!.id;

    // Update friendship status
    await supabase
        .from('friendships')
        .update({'status': 'accepted'})
        .eq('id', friendshipId);

    // Buat chat room otomatis
    await supabase.rpc('get_or_create_room', params: {
      'p_user1': myId,
      'p_user2': friendId,
    });

    await _loadFriendStatus();
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Add Friend"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBox(),
            const SizedBox(height: 20),

            // Found user search
            if (foundUser != null)
              _userTile(
                foundUser!,
                "Add",
                sentRequests.any((e) => e['id'] == foundUser!['id']),
                    () => sendFriendRequest(foundUser!['id']),
              ),

            // Sent requests
            if (sentRequests.isNotEmpty) ...[
              const SizedBox(height: 30),
              const Text("Pending Requests",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 10),
              for (final user in sentRequests)
                _userTile(user, "Pending", true, () {}),
            ],

            // Incoming requests
            if (incomingRequests.isNotEmpty) ...[
              const SizedBox(height: 30),
              const Text("Friend Requests",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 10),
              for (final user in incomingRequests)
                _userTile(
                  user,
                  "Accept",
                  false,
                      () async {
                    await acceptFriend(user['friendship_id'], user['id']);
                    await _loadFriendStatus();
                  },
                ),
            ],

            // Accepted friends
            if (acceptedFriends.isNotEmpty) ...[
              const SizedBox(height: 30),
              const Text("Your Friends",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 10),
              for (final user in acceptedFriends)
                _userTile(user, "Friends", true, () {}),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      onSubmitted: (_) => searchUser(),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Search username",
        filled: true,
        fillColor: Colors.grey.shade900,
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _userTile(Map<String, dynamic> user, String btn, bool disabled,
      VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: user['avatar_url'] != null
                ? NetworkImage(user['avatar_url'])
                : null,
            child: user['avatar_url'] == null
                ? Text(user['username'][0].toUpperCase())
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user['username'],
              style: const TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: disabled ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: disabled ? Colors.grey : Colors.yellow,
              foregroundColor: Colors.black,
            ),
            child: Text(btn),
          ),
        ],
      ),
    );
  }
}
