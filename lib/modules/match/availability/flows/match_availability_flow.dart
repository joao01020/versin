import 'package:flutter/material.dart';

import 'package:versin/modules/match/availability/controllers/match_availability_controller.dart';
import 'package:versin/modules/match/availability/widgets/match_availability_duration_sheet.dart';
import 'package:versin/modules/profile/services/presence/user_presence_service.dart';

// ============================================================
// MATCH AVAILABILITY FLOW
// ============================================================
//
// Orquestra apenas a entrada no modo "Agora":
//
// - confirma presença real;
// - se necessário pede que o perfil online seja ajustado;
// - solicita duração;
// - ativa disponibilidade.
//
// ============================================================

class MatchAvailabilityFlow {
  final MatchAvailabilityController _availabilityController;
  final UserPresenceService _presenceService;

  const MatchAvailabilityFlow({
    required MatchAvailabilityController availabilityController,
    required UserPresenceService presenceService,
  }) : _availabilityController = availabilityController,
       _presenceService = presenceService;

  Future<bool> ensureAvailable({
    required BuildContext context,
    required Color accentColor,
    required Future<void> Function() openOnlineProfile,
  }) async {
    var reallyOnline = await _presenceService.ensureReallyOnline();

    if (!context.mounted) {
      return false;
    }

    if (!reallyOnline) {
      _presenceService.requestOnlineAttention();

      _showMessage(
        context,
        'Fique online primeiro para usar Disponíveis agora.',
      );

      await openOnlineProfile();

      if (!context.mounted) {
        return false;
      }

      reallyOnline = await _presenceService.ensureReallyOnline();

      if (!context.mounted || !reallyOnline) {
        return false;
      }
    }

    if (_availabilityController.isActive) {
      return true;
    }

    final selectedMinutes = await MatchAvailabilityDurationSheet.show(
      context: context,
      accentColor: accentColor,
    );

    if (!context.mounted || selectedMinutes == null) {
      return false;
    }

    final activated = await _availabilityController.activate(
      minutes: selectedMinutes,
    );

    if (!context.mounted) {
      return false;
    }

    if (!activated) {
      _showMessage(context, 'Não foi possível ativar sua disponibilidade.');

      return false;
    }

    _showMessage(
      context,
      'Disponível agora por '
      '${_availabilityController.durationLabel(selectedMinutes)}.',
    );

    return true;
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
      );
  }
}
