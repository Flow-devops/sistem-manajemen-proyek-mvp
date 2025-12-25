// lib/widgets/daily_quest_banner.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/daily_quest_service.dart';
import 'daily_quest_modal.dart';

class DailyQuestBanner extends StatefulWidget {
  final DailyQuestService service;
  const DailyQuestBanner({super.key, required this.service});

  @override
  State<DailyQuestBanner> createState() => _DailyQuestBannerState();
}

class _DailyQuestBannerState extends State<DailyQuestBanner> {
  DailyQuest? _quest;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuest();
  }

  Future<void> _loadQuest() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _loading = false;
        _error = "Belum login";
      });
      return;
    }

    try {
      final q = await widget.service.fetchOrCreateForUser(userId);
      setState(() => _quest = q);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openModal() {
    if (_quest == null) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Quest',
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, secAnim, child) {
        final curved = Curves.easeOutBack.transform(anim.value);
        return Transform.scale(
          scale: curved,
          child: Opacity(
            opacity: anim.value,
            child: DailyQuestModal(questText: _quest!.questText),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 450),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        width: double.infinity,
        color: Colors.indigo.shade50,
        padding: const EdgeInsets.all(12),
        child: const Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (_error != null) {
      return Container(
        width: double.infinity,
        color: Colors.red.shade50,
        padding: const EdgeInsets.all(12),
        child: Text('Daily Quest error: $_error', style: TextStyle(color: Colors.red.shade700)),
      );
    }

    if (_quest == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _openModal,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.indigo.shade100),
        ),
        child: Row(
          children: [
            const Icon(Icons.flash_on, color: Colors.indigo),
            const SizedBox(width: 12),
            Expanded(child: Text(_quest!.questText, style: const TextStyle(fontWeight: FontWeight.w600))),
            TextButton(onPressed: _openModal, child: const Text('Mulai')),
          ],
        ),
      ),
    );
  }
}
