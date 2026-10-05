import 'package:flutter/material.dart';

class ChatInputArea
    extends
        StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Color activeColor;
  final String hintText;
  final ValueChanged<
    String
  >?
  onAddRhyme;

  const ChatInputArea({
    super.key,
    required this.controller,
    required this.onSend,
    required this.activeColor,
    required this.hintText,
    this.onAddRhyme,
  });

  @override
  State<
    ChatInputArea
  >
  createState() => _ChatInputAreaState();
}

class _ChatInputAreaState
    extends
        State<
          ChatInputArea
        > {
  bool _isCompactMode = false;

  void _toggleMode() {
    setState(
      () {
        _isCompactMode = !_isCompactMode;
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.sizeOf(
              context,
            ).height *
            0.45,
      ),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 250,
        ),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(
            0xFF121212,
          ),
          borderRadius: BorderRadius.circular(
            24,
          ),
          border: Border.all(
            color: widget.activeColor.withValues(
              alpha: 0.1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                bottom: 8,
              ),
              child: GestureDetector(
                onTap: _toggleMode,
                child: Icon(
                  _isCompactMode
                      ? Icons.unfold_more_rounded
                      : Icons.unfold_less_rounded,
                  color: widget.activeColor.withValues(
                    alpha: 0.5,
                  ),
                  size: 22,
                ),
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child: TextField(
                controller: widget.controller,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 1,
                maxLines: _isCompactMode
                    ? 3
                    : null,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.8,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(
                    color: Colors.white24,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                ),
              ),
            ),

            IconButton(
              onPressed: widget.onSend,
              icon: Icon(
                Icons.send_rounded,
                color: widget.activeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
