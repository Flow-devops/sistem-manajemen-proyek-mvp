// lib/widgets/daily_quest_modal.dart
import 'package:flutter/material.dart';

class DailyQuestModal extends StatelessWidget {
  final String questText;
  final VoidCallback? onStart;

  const DailyQuestModal({super.key, required this.questText, this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          constraints: BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 14)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Daily Photo Quest', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade700)),
              const SizedBox(height: 12),
              Text(questText, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                    onPressed: () {
                      Navigator.pop(context);
                      if (onStart != null) onStart!();
                    },
                    child: const Text('Mulai'),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
