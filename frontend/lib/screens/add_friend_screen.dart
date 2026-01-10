import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchFriendScreen extends StatefulWidget {
  const SearchFriendScreen({super.key});

  @override
  State<SearchFriendScreen> createState() => _SearchFriendScreenState();
}

class _SearchFriendScreenState extends State<SearchFriendScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  bool loading = true;
  bool isSearching = false;
  Map<String, dynamic>? foundUser;
  String? searchError;

  List<Map<String, dynamic>> incomingRequests = [];
  List<Map<String, dynamic>> sentRequests = [];
  List<Map<String, dynamic>> acceptedFriends = [];

  final Color brandColor = const Color(0xFF1CBABE);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  // Notifikasi Premium
  void _showTopNotification(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : brandColor,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // LOGIK UTAMA: Mengambil semua data pertemanan
  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => loading = true);

    final myId = supabase.auth.currentUser!.id;

    try {
      final res = await supabase
          .from('friendships')
          .select(
          '*, sender:profiles!from_user_id(*), receiver:profiles!to_user_id(*)')
          .or('from_user_id.eq.$myId,to_user_id.eq.$myId');

      List<Map<String, dynamic>> tempIncoming = [];
      List<Map<String, dynamic>> tempSent = [];
      List<Map<String, dynamic>> tempAccepted = [];

      for (var f in res) {
        final status = f['status'];
        final fromId = f['from_user_id'];
        final toId = f['to_user_id'];

        if (status == 'pending') {
          if (toId == myId) {
            if (f['sender'] != null) {
              tempIncoming.add({'friendship_id': f['id'], ...f['sender']});
            }
          } else {
            if (f['receiver'] != null) {
              tempSent.add({'friendship_id': f['id'], ...f['receiver']});
            }
          }
        } else if (status == 'accepted') {
          final friend = (fromId == myId) ? f['receiver'] : f['sender'];
          if (friend != null) tempAccepted.add(friend);
        }
      }

      if (mounted) {
        setState(() {
          incomingRequests = tempIncoming;
          sentRequests = tempSent;
          acceptedFriends = tempAccepted;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading friends: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> searchUser() async {
    final username = _searchController.text.trim();
    if (username.isEmpty) return;

    setState(() {
      isSearching = true;
      foundUser = null;
      searchError = null;
    });

    try {
      final res = await supabase.from('profiles').select().eq(
          'username', username).maybeSingle();
      if (mounted) {
        if (res != null) {
          final targetId = res['id'];
          String? status;
          if (acceptedFriends.any((f) => f['id'] == targetId))
            status = "Friends";
          else if (sentRequests.any((r) => r['id'] == targetId))
            status = "Sent";
          else if (incomingRequests.any((r) => r['id'] == targetId))
            status = "Requested You";
          else if (targetId == supabase.auth.currentUser!.id) status = "You";

          setState(() {
            isSearching = false;
            foundUser = {...res, 'status_text': status};
          });
        } else {
          setState(() {
            isSearching = false;
            searchError = "User not found";
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() {
        isSearching = false;
        searchError = "Search error";
      });
    }
  }

  Future<void> sendRequest(String targetId) async {
    final myId = supabase.auth.currentUser!.id;
    
    if (mounted && foundUser != null && foundUser!['id'] == targetId) {
      setState(() {
        foundUser!['status_text'] = "Sent";
      });
    }

    try {
      await supabase.from('friendships').insert({
        'from_user_id': myId,
        'to_user_id': targetId,
        'friend_id': targetId,
        'status': 'pending',
      });
      await _loadAllData();
      _showTopNotification("Request sent!");
    } catch (e) {
      if (mounted && foundUser != null && foundUser!['id'] == targetId) {
        setState(() {
          foundUser!['status_text'] = null;
        });
      }
      _showTopNotification("Failed to send request", isError: true);
    }
  }

  Future<void> acceptFriend(String fId, String friendId) async {
    if (mounted) {
      setState(() {
        for (var r in incomingRequests) {
          if (r['friendship_id'] == fId) {
            r['is_accepting'] = true;
            break;
          }
        }
      });
    }

    try {
      await supabase.from('friendships').update({'status': 'accepted'}).eq(
          'id', fId);
      await supabase.rpc('get_or_create_room', params: {
        'p_user1': supabase.auth.currentUser!.id,
        'p_user2': friendId
      });
      await _loadAllData();
      _showTopNotification("Friend accepted!");
    } catch (e) {
      if (mounted) {
        setState(() {
          for (var r in incomingRequests) {
            if (r['friendship_id'] == fId) {
              r['is_accepting'] = false;
              break;
            }
          }
        });
      }
      _showTopNotification("Action failed", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    brandColor.withOpacity(0.05),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 10),
                      if (isSearching)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1CBABE)),
                        ),
                      if (foundUser != null) _buildSearchResult(),
                      if (searchError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(searchError!, style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13)),
                        ),
                      const SizedBox(height: 20),
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildList(acceptedFriends, "Start building your circle", isFriend: true),
                            _buildRequestsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (loading && acceptedFriends.isEmpty && incomingRequests.isEmpty && sentRequests.isEmpty)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF1CBABE))),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 5),
          Text(
            "FLOW",
            style: GoogleFonts.syncopate(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          Text(
            "ADD FRIENDS",
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: brandColor.withOpacity(0.3),
          ),
        ),
        child: TextField(
          controller: _searchController,
          onSubmitted: (_) => searchUser(),
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15,
          ),
          cursorColor: brandColor,
          decoration: InputDecoration(
            filled: false,
            hintText: "Search by username...",
            hintStyle: GoogleFonts.poppins(
              color: Colors.white24,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Colors.white38,
              size: 22,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white38,
                size: 18,
              ),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  foundUser = null;
                  searchError = null;
                });
              },
            )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResult() {
    final status = foundUser!['status_text'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SEARCH RESULT",
            style: GoogleFonts.poppins(color: brandColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          _userTile(
            foundUser!,
            status ?? "Add Friend",
            status == null ? brandColor : Colors.white.withOpacity(0.08),
            status == null ? Colors.white : Colors.white38,
            status == null ? () => sendRequest(foundUser!['id']) : null,
            isSearchItem: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: brandColor,
            boxShadow: [
              BoxShadow(
                color: brandColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "FRIENDS"),
            Tab(text: "REQUESTS"),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (incomingRequests.isEmpty && sentRequests.isEmpty && !loading) {
      return _buildEmptyState(Icons.mail_outline_rounded, "No pending requests");
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: brandColor,
      backgroundColor: Colors.grey[900],
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(25),
        children: [
          if (incomingRequests.isNotEmpty) ...[
            _buildSectionHeader("INCOMING"),
            const SizedBox(height: 15),
            ...incomingRequests.map((r) {
              final isAccepting = r['is_accepting'] == true;
              return _userTile(
                r, 
                isAccepting ? "Accepted" : "Accept", 
                isAccepting ? Colors.white.withOpacity(0.08) : brandColor, 
                isAccepting ? Colors.white38 : Colors.white, 
                isAccepting ? null : () => acceptFriend(r['friendship_id'], r['id']),
              );
            }),
          ],
          if (sentRequests.isNotEmpty) ...[
            if (incomingRequests.isNotEmpty) const SizedBox(height: 30),
            _buildSectionHeader("SENT"),
            const SizedBox(height: 15),
            ...sentRequests.map((r) => _userTile(
              r, "Pending", Colors.white.withOpacity(0.08), Colors.white38, null,
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.05), thickness: 1)),
      ],
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, String emptyMsg, {bool isFriend = false}) {
    if (list.isEmpty && !loading) {
      return _buildEmptyState(isFriend ? Icons.people_outline_rounded : Icons.hourglass_empty_rounded, emptyMsg);
    }
    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: brandColor,
      backgroundColor: Colors.grey[900],
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(25),
        itemCount: list.length,
        itemBuilder: (context, i) => _userTile(
          list[i], 
          isFriend ? "Friend" : "Add",
          Colors.white.withOpacity(0.05), 
          Colors.white60, 
          null,
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.05), size: 80),
          const SizedBox(height: 15),
          Text(
            message,
            style: GoogleFonts.poppins(color: Colors.white24, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _userTile(Map<String, dynamic> user, String btnText, Color btnBg,
      Color textColor, VoidCallback? onTap, {bool isSearchItem = false}) {
    final String? avatarUrl = user['avatar_url'];
    final String username = user['username'] ?? "User";

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSearchItem ? brandColor.withOpacity(0.05) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSearchItem ? brandColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: brandColor.withOpacity(0.2), width: 1),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[900],
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null 
                ? Text(username.isNotEmpty ? username[0].toUpperCase() : "?", style: GoogleFonts.poppins(color: Colors.white38, fontWeight: FontWeight.bold)) 
                : null,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user['status_text'] ?? "Member",
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (onTap != null)
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnBg,
                foregroundColor: textColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(btnText, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: btnBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                btnText,
                style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
