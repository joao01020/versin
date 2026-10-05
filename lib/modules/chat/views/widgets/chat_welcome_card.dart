import 'package:flutter/material.dart';

class ChatWelcomeCard
    extends
        StatelessWidget {
  final Color activeColor;

  const ChatWelcomeCard({
    super.key,
    this.activeColor = Colors.purpleAccent,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(
                16,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withValues(
                  alpha: 0.1,
                ),
                border: Border.all(
                  color: activeColor.withValues(
                    alpha: 0.3,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(
                      alpha: 0.05,
                    ),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.mic_external_on,
                color: activeColor,
                size: 38,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              'VERSIN',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            Text(
              'uma letra organizada brota ouvintes até do chão,\n'
              'cultive sua reflexão que vamos te entregar sua melhor\n'
              'versão escrita',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
