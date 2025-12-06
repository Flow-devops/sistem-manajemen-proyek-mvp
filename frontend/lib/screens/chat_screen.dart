import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart'; // Import untuk menggunakan variabel global 'supabase'

// --- CHAT SCREEN WIDGET UTAMA ---

class ChatScreen extends StatefulWidget {
  final String friendId;      // ID Teman yang dikirim dari HomeScreen
  final String friendName;    // Nama Teman
  final String? friendAvatar; // Foto Teman (opsional)

  const ChatScreen({
    super.key,
    required this.friendId,
    required this.friendName,
    this.friendAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  // NOTE: Stream Supabase Realtime akan diinisiasi di sini
  // late Stream<List<Map<String, dynamic>>> _messagesStream;

  @override
  void initState() {
    super.initState();
    // Di sini Anda akan menginisiasi _messagesStream untuk mengambil data chat real-time
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!mounted) return;
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    // Logika pengiriman pesan ke Supabase (Placeholder)
    try {
      // Logic Supabase insert pesan (akan diaktifkan saat database siap)
      // await supabase.from('messages').insert({
      //   'sender_id': supabase.auth.currentUser!.id,
      //   'receiver_id': widget.friendId,
      //   'text': text,
      //   'created_at': DateTime.now().toIso8601String(),
      // });
      print('Message sent: $text');

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim pesan: ${e.toString()}')),
      );
    }
  }

  // Widget Input Area (Bottom Bar)
  Widget _chatInput() {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 20),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF5F5F5))),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attachment, color: Colors.grey),
            onPressed: () {},
          ),

          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: (_) => _handleSend(),
              decoration: InputDecoration(
                hintText: 'Ketik pesan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tag_faces_outlined, color: Colors.grey),
                  onPressed: () {},
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Tombol Kirim (Send)
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.blue[500],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _handleSend,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Contoh data dummy untuk demonstrasi UI
    const dummyMessages = [
      {'sender_id': 'OTHER_ID', 'text': 'Can i Share a picture', 'created_at': '2025-12-03T22:31:00Z'},
      {'sender_id': 'MY_ID', 'text': 'Sure, I\'m waiting buddy', 'created_at': '2025-12-03T22:32:00Z'},
      {'sender_id': 'OTHER_ID', 'text': 'HY', 'created_at': '2025-12-03T22:30:00Z'},
      {'sender_id': 'MY_ID', 'text': 'Thanks!', 'created_at': '2025-12-03T22:33:00Z'},
    ];

    return Scaffold(
      // --- HEADER ---
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.friendAvatar != null
                  ? NetworkImage(widget.friendAvatar!)
                  : null,
              child: widget.friendAvatar == null
                  ? const Icon(Icons.person, size: 18, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.friendName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Text(
                    'Online Now',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8) // Opacity fix
                    )
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),

      // --- MESSAGES AREA ---
      body: Column(
        children: [
          Expanded(
            // Placeholder List for messages
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              itemCount: dummyMessages.length,
              itemBuilder: (context, index) {
                final message = dummyMessages[index];
                // Asumsi: 'MY_ID' akan diganti dengan ID pengguna yang sebenarnya saat real-time
                final isMe = message['sender_id'] == 'MY_ID';

                return MessageBubble(
                  message: message['text'] ?? 'Pesan Kosong',
                  isMe: isMe,
                  // FIX: Memastikan String dikonversi dengan benar
                  timestamp: DateTime.parse(message['created_at']! as String),
                  avatarUrl: widget.friendAvatar,
                );
              },
            ),
          ),

          // --- INPUT AREA ---
          _chatInput(),
        ],
      ),
    );
  }
}


// --- WIDGET BUBBLE PESAN KUSTOM ---

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final String? avatarUrl;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    this.avatarUrl,
  });

  String _formatTime(DateTime date) {
    return date.hour.toString().padLeft(2, '0') +
        ':' +
        date.minute.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar Teman (Jika bukan pesan saya)
          if (!isMe) ...[
            CircleAvatar(
              radius: 12,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null ? const Icon(Icons.person, size: 12, color: Colors.white) : null,
              backgroundColor: Colors.grey,
            ),
            const SizedBox(width: 8),
          ],

          // Kotak Pesan
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue[500] : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(timestamp), // Timestamp kecil
                    style: TextStyle(
                      fontSize: 10.0,
                      color: isMe ? Colors.white70 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Spacer dan Avatar Saya (Opsional)
          if (isMe) const SizedBox(width: 8),
          if (isMe) const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 12, color: Colors.white)),
        ],
      ),
    );
  }
}