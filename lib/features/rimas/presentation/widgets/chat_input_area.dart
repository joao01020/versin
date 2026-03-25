import 'package:flutter/material.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Color activeColor;
  final String hintText;

  const ChatInputArea({
    super.key,
    required this.controller,
    required this.onSend,
    required this.activeColor,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), 
        borderRadius: BorderRadius.circular(22), 
        border: Border.all(color: activeColor.withOpacity(0.3))
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.multiline,
              maxLines: 5, 
              minLines: 1,
              style: TextStyle(color: activeColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 15), 
                border: InputBorder.none, 
                contentPadding: const EdgeInsets.symmetric(vertical: 12)
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send_rounded, color: activeColor),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}