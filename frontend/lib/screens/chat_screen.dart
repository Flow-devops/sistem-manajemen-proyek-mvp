import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_friend_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final supabase = Supabase.instance.client;
  bool loading = true;
  List<Map<String, dynamic>> chatRooms = [];
  final Color brandColor = const Color(0xFF1CBABE);

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      final myId = supabase.auth.currentUser!.id;
      final rooms = await supabase
          .from('chat_rooms')
          .select('id, user1_id, user2_id')
          .or('user1_id.eq.$myId,user2_id.eq.$myId');

      final List<Map<String, dynamic>> temp = [];

      for (final room in rooms) {
        final friendId =
            room['user1_id'] == myId ? room['user2_id'] : room['user1_id'];

        final profile = await supabase
            .from('profiles')
            .select('id, username, avatar_url')
            .eq('id', friendId)
            .single();

        final lastMessageData = await supabase
            .from('messages')
            .select('content, created_at')
            .eq('room_id', room['id'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        temp.add({
          'room_id': room['id'],
          'friend_id': friendId,
          'username': profile['username'],
          'avatar': profile['avatar_url'],
          'last_message': lastMessageData != null ? lastMessageData['content'] : "No messages yet",
          'last_time': lastMessageData != null ? _formatTime(lastMessageData['created_at']) : "",
        });
      }

      if (!mounted) return;
      setState(() {
        chatRooms = temp;
        loading = false;
      });
    } catch (e) {
      debugPrint('Error load chat rooms: $e');
      if (mounted) setState(() => loading = false);
    }
  }

  String _formatTime(String timestamp) {
    final dt = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    return "${dt.day}/${dt.month}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: loading
                      ? _buildLoading()
                      : chatRooms.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              color: brandColor,
                              onRefresh: _loadChatRooms,
                              child: ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                itemCount: chatRooms.length,
                                itemBuilder: (context, index) {
                                  return _ChatTile(
                                    room: chatRooms[index],
                                    brandColor: brandColor,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatRoomScreen(
                                          roomId: chatRooms[index]['room_id'],
                                          username: chatRooms[index]['username'],
                                          avatar: chatRooms[index]['avatar'],
                                        ),
                                      ),
                                    ).then((_) => _loadChatRooms()),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            "Messages",
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: brandColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.person_add_rounded, color: brandColor, size: 18),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchFriendScreen()),
              ).then((_) => _loadChatRooms());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: brandColor, strokeWidth: 2),
          const SizedBox(height: 15),
          Text("Loading...", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.grey[200]),
          const SizedBox(height: 15),
          Text("No messages", style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final Map<String, dynamic> room;
  final Color brandColor;
  final VoidCallback onTap;

  const _ChatTile({required this.room, required this.brandColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFF0F0F0),
            backgroundImage: room['avatar'] != null ? NetworkImage(room['avatar']) : null,
            child: room['avatar'] == null ? Icon(Icons.person, color: Colors.grey[400], size: 24) : null,
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  room['username'], 
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(room['last_time'], style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400])),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              room['last_message'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 18),
        ),
      ),
    );
  }
}

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final String username;
  final String? avatar;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.username,
    this.avatar,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  final Color brandColor = const Color(0xFF1CBABE);

  @override
  void initState() {
    super.initState();
    _messagesStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.roomId)
        .order('created_at', ascending: false);
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final userId = supabase.auth.currentUser!.id;
    _controller.clear();

    try {
      await supabase.from('messages').insert({
        'room_id': widget.roomId,
        'sender_id': userId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        toolbarHeight: 55,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFF0F0F0),
              backgroundImage: widget.avatar != null ? NetworkImage(widget.avatar!) : null,
              child: widget.avatar == null ? const Icon(Icons.person, size: 18, color: Colors.grey) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.username,
                style: GoogleFonts.poppins(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator(color: brandColor, strokeWidth: 2));
                  }
                  final messages = snapshot.data!;
                  return ListView.builder(
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['sender_id'] == userId;
                      return _ChatBubble(content: msg['content'], isMe: isMe, brandColor: brandColor);
                    },
                  );
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: brandColor.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(Icons.add_rounded, color: brandColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 38,
              height: 40,
              decoration: BoxDecoration(
                color: brandColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: brandColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final Color brandColor;

  const _ChatBubble({required this.content, required this.isMe, required this.brandColor});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? brandColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          content,
          style: GoogleFonts.poppins(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
