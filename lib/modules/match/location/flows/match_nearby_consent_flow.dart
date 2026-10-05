import 'package:flutter/material.dart';

import 'package:versin/modules/match/location/service/match_location_consent_service.dart';
import 'package:versin/modules/match/location/views/location_privacy_page.dart';

// ============================================================
// MATCH NEARBY CONSENT FLOW
// ============================================================
//
// Isola completamente da MatchPage:
//
// - leitura do consentimento;
// - dialog de explicação;
// - navegação para política de localização;
// - persistência do consentimento.
//
// Retorna:
// true  -> pode entrar em Próximos
// false -> fluxo cancelado / falhou
//
// ============================================================

class MatchNearbyConsentFlow {
  final MatchLocationConsentService _consentService;

  const MatchNearbyConsentFlow({
    required MatchLocationConsentService consentService,
  }) : _consentService = consentService;

  Future<bool> ensureConsent({
    required BuildContext context,
    required Color accentColor,
  }) async {
    try {
      final alreadyAccepted = await _consentService.hasAcceptedNearbyLocation();

      if (!context.mounted) {
        return false;
      }

      if (alreadyAccepted) {
        return true;
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH LOCATION] '
        'Erro ao consultar consentimento: $error',
      );

      debugPrint(
        '[MATCH LOCATION] '
        'Stack trace: $stackTrace',
      );

      if (!context.mounted) {
        return false;
      }

      _showMessage(
        context,
        'Não foi possível verificar a confirmação de localização.',
      );

      return false;
    }

    final accepted = await _showConsentDialog(
      context: context,
      accentColor: accentColor,
    );

    if (!context.mounted || !accepted) {
      return false;
    }

    try {
      await _consentService.acceptNearbyLocation();

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH LOCATION] '
        'Erro ao salvar consentimento: $error',
      );

      debugPrint(
        '[MATCH LOCATION] '
        'Stack trace: $stackTrace',
      );

      if (context.mounted) {
        _showMessage(context, 'Não foi possível salvar sua confirmação.');
      }

      return false;
    }
  }

  Future<bool> _showConsentDialog({
    required BuildContext context,
    required Color accentColor,
  }) async {
    bool accepted = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF17132D),
              surfaceTintColor: Colors.transparent,
              title: const Text(
                'Encontrar profissionais próximos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Usamos sua localização apenas para '
                    'encontrar profissionais próximos de você.\n\n'
                    'Sua posição é usada para calcular a '
                    'distância entre perfis e melhorar os '
                    'resultados do modo Próximos.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        await Navigator.of(dialogContext).push(
                          MaterialPageRoute<void>(
                            builder: (_) {
                              return const LocationPrivacyPage();
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 15),
                      label: const Text('Como usamos sua localização'),
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: accepted,
                    activeColor: accentColor,
                    checkColor: Colors.black,
                    title: const Text(
                      'Confirmo que entendi e permito '
                      'o uso da minha localização para '
                      'encontrar profissionais próximos.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        accepted = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('CANCELAR'),
                ),
                FilledButton(
                  onPressed: accepted
                      ? () {
                          Navigator.of(dialogContext).pop(true);
                        }
                      : null,
                  child: const Text('CONTINUAR'),
                ),
              ],
            );
          },
        );
      },
    );

    return result == true;
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
