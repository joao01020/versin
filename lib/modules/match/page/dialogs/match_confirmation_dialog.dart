import 'package:flutter/material.dart';
import 'package:versin/modules/match/page/services/match_confirmation_service.dart';

enum MatchConfirmationAction { continueDiscovering, viewProject, startNow }

class MatchConfirmationDialog extends StatelessWidget {
  final MatchConfirmation confirmation;
  final bool allowQuickStart;
  const MatchConfirmationDialog({
    super.key,
    required this.confirmation,
    this.allowQuickStart = false,
  });

  static const Color _surface = Color(0xFF111116);
  static const Color _accent = Color(0xFF8B5CF6);
  static const Color _muted = Color(0xFF9BA1AD);

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFF292633)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (context, progress, child) => Opacity(
                opacity: progress,
                child: Transform.scale(
                  scale: 0.94 + 0.06 * progress,
                  child: child,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _ProfileAvatar(profile: confirmation.self),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.85, end: 1),
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 650),
                          curve: Curves.easeOutBack,
                          builder: (context, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFFE85D75),
                            size: 28,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _ProfileAvatar(profile: confirmation.other),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Deu Match!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vocês demonstraram interesse um no outro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  const Divider(color: Color(0xFF292633), height: 1),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        color: _accent,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Uma nova conexão começou',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Agora vocês podem conversar, compartilhar ideias e criar juntos.',
                    style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(MatchConfirmationAction.viewProject),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Ver projeto'),
                    ),
                  ),
                  if (allowQuickStart) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(
                          MatchConfirmationAction.startNow,
                        ),
                        child: const Text('Iniciar conexão agora'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(MatchConfirmationAction.continueDiscovering),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF34303E)),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Continuar descobrindo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final MatchConfirmationProfile profile;
  const _ProfileAvatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final avatar = profile.avatarUrl;
    final initials = profile.name.trim().isEmpty
        ? '?'
        : profile.name.trim().substring(0, 1).toUpperCase();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: SizedBox(
            width: 64,
            height: 64,
            child: avatar == null
                ? _fallback(initials)
                : Image.network(
                    avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stackTrace) => _fallback(initials),
                  ),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          profile.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (profile.username.isNotEmpty)
          Text(
            '@${profile.username.replaceFirst(RegExp(r'^@+'), '')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF9BA1AD), fontSize: 11),
          ),
      ],
    );
  }

  Widget _fallback(String initials) => Container(
    color: const Color(0xFF242032),
    alignment: Alignment.center,
    child: Text(
      initials,
      style: const TextStyle(
        color: Color(0xFFA78BFA),
        fontSize: 23,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
