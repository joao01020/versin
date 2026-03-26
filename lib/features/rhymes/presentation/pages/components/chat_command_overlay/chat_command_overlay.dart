import 'package:flutter/material.dart';
import 'package:versin/features/rhymes/presentation/utils/command_handler.dart';

class ChatCommandOverlay extends StatelessWidget {
  final CommandHandler commandHandler;
  final Color activeColor;
  final Function(String) onCommandSelected;

  const ChatCommandOverlay({
    super.key,
    required this.commandHandler,
    required this.activeColor,
    required this.onCommandSelected,
  });

  @override
  Widget build(BuildContext context) {
    final commands = commandHandler.getCommands();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: activeColor.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: commands.map((c) => ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(c['cmd']!, style: TextStyle(color: activeColor, fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(c['desc']!, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            onTap: () => onCommandSelected(c['cmd']!),
          )).toList(),
        ),
      ),
    );
  }
}