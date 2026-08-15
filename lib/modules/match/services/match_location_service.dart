import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// MATCH LOCATION SERVICE
// ============================================================
//
// Responsável por:
//
// - verificar serviço de localização;
// - verificar permissão;
// - solicitar permissão;
// - obter posição atual;
// - salvar localização no Supabase;
// - ativar localização;
// - desativar localização.
//
// Banco:
//
// public.profiles
//
// Campos:
//
// latitude
// longitude
// location_enabled
// location_updated_at
//
// Este service NÃO:
//
// - calcula distância;
// - filtra candidatos;
// - controla MatchController;
// - controla UI;
// - conhece BuildContext.
//
// Fluxo:
//
// MatchPage
//    ↓
// MatchSessionService
//    ↓
// MatchLocationService
//    ↓
// GPS / localização do sistema
//    ↓
// Supabase profiles
//
// ============================================================

class MatchLocationService {
  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase;

  // ============================================================
  // TABELA
  // ============================================================

  static const String _profilesTable = 'profiles';

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  MatchLocationService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  // ============================================================
  // USUÁRIO ATUAL
  // ============================================================

  String? get currentUserId {
    final id = _supabase.auth.currentUser?.id.trim();

    if (id == null || id.isEmpty) {
      return null;
    }

    return id;
  }

  // ============================================================
  // SERVIÇO DE LOCALIZAÇÃO ATIVO
  // ============================================================

  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (error) {
      debugPrint(
        '[MATCH LOCATION] '
        'Erro ao verificar serviço de localização: '
        '$error',
      );

      return false;
    }
  }

  // ============================================================
  // PERMISSÃO ATUAL
  // ============================================================

  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (error) {
      debugPrint(
        '[MATCH LOCATION] '
        'Erro ao verificar permissão: '
        '$error',
      );

      return LocationPermission.denied;
    }
  }

  // ============================================================
  // SOLICITAR PERMISSÃO
  // ============================================================

  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (error) {
      debugPrint(
        '[MATCH LOCATION] '
        'Erro ao solicitar permissão: '
        '$error',
      );

      return LocationPermission.denied;
    }
  }

  // ============================================================
  // GARANTIR PERMISSÃO
  // ============================================================
  //
  // Retorna true quando podemos tentar obter localização.
  //
  // ============================================================

  Future<bool> ensurePermission() async {
    // ==========================================================
    // SERVIÇO
    // ==========================================================

    final serviceEnabled = await isLocationServiceEnabled();

    if (!serviceEnabled) {
      debugPrint(
        '[MATCH LOCATION] '
        'Serviço de localização desativado.',
      );

      return false;
    }

    // ==========================================================
    // PERMISSÃO ATUAL
    // ==========================================================

    var permission = await checkPermission();

    // ==========================================================
    // SOLICITAR
    // ==========================================================

    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }

    // ==========================================================
    // NEGADA
    // ==========================================================

    if (permission == LocationPermission.denied) {
      debugPrint(
        '[MATCH LOCATION] '
        'Permissão de localização negada.',
      );

      return false;
    }

    // ==========================================================
    // NEGADA PERMANENTEMENTE
    // ==========================================================

    if (permission == LocationPermission.deniedForever) {
      debugPrint(
        '[MATCH LOCATION] '
        'Permissão de localização negada permanentemente.',
      );

      return false;
    }

    // ==========================================================
    // PERMITIDA
    // ==========================================================

    return true;
  }

  // ============================================================
  // POSIÇÃO ATUAL
  // ============================================================

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await ensurePermission();

    if (!hasPermission) {
      return null;
    }

    try {
      debugPrint(
        '[MATCH LOCATION] '
        'Obtendo localização atual.',
      );

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      debugPrint(
        '[MATCH LOCATION] '
        'Localização obtida.',
      );

      return position;
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH LOCATION] '
        'Erro ao obter localização: '
        '$error',
      );

      debugPrint(
        '[MATCH LOCATION] '
        'Stack trace: '
        '$stackTrace',
      );

      return null;
    }
  }

  // ============================================================
  // ATUALIZAR LOCALIZAÇÃO
  // ============================================================
  //
  // Obtém a posição atual e salva:
  //
  // latitude
  // longitude
  // location_enabled = true
  // location_updated_at
  //
  // Retorna a Position salva.
  //
  // ============================================================

  Future<Position?> updateCurrentLocation() async {
    final userId = currentUserId;

    if (userId == null) {
      debugPrint(
        '[MATCH LOCATION] '
        'Usuário não autenticado.',
      );

      return null;
    }

    // ==========================================================
    // OBTER POSIÇÃO
    // ==========================================================

    final position = await getCurrentPosition();

    if (position == null) {
      return null;
    }

    // ==========================================================
    // SALVAR
    // ==========================================================

    try {
      final now = DateTime.now().toUtc().toIso8601String();

      await _supabase
          .from(_profilesTable)
          .update({
            'latitude': position.latitude,

            'longitude': position.longitude,

            'location_enabled': true,

            'location_updated_at': now,

            'updated_at': now,
          })
          .eq('id', userId);

      debugPrint(
        '[MATCH LOCATION] '
        'Localização salva no Supabase.',
      );

      return position;
    } on PostgrestException catch (error) {
      debugPrint(
        '[MATCH LOCATION] '
        'Erro Supabase ao salvar localização.',
      );

      debugPrint(
        '[MATCH LOCATION] '
        'Mensagem: '
        '${error.message}',
      );

      debugPrint(
        '[MATCH LOCATION] '
        'Código: '
        '${error.code}',
      );

      debugPrint(
        '[MATCH LOCATION] '
        'Detalhes: '
        '${error.details}',
      );

      return null;
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH LOCATION] '
        'Erro inesperado ao salvar localização: '
        '$error',
      );

      debugPrint(
        '[MATCH LOCATION] '
        'Stack trace: '
        '$stackTrace',
      );

      return null;
    }
  }

  // ============================================================
  // ATIVAR LOCALIZAÇÃO
  // ============================================================
  //
  // É equivalente a atualizar a localização atual.
  //
  // ============================================================

  Future<Position?> enableLocation() {
    return updateCurrentLocation();
  }

  // ============================================================
  // DESATIVAR LOCALIZAÇÃO
  // ============================================================
  //
  // Não apaga as coordenadas imediatamente.
  //
  // location_enabled = false faz com que o perfil deixe de ser
  // elegível para o modo PRÓXIMOS.
  //
  // ============================================================

  Future<bool> disableLocation() async {
    final userId = currentUserId;

    if (userId == null) {
      return false;
    }

    try {
      await _supabase
          .from(_profilesTable)
          .update({
            'location_enabled': false,

            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);

      debugPrint(
        '[MATCH LOCATION] '
        'Localização desativada.',
      );

      return true;
    } on PostgrestException catch (error) {
      debugPrint(
        '[MATCH LOCATION] '
        'Erro Supabase ao desativar localização: '
        '${error.message}',
      );

      return false;
    } catch (error) {
      debugPrint(
        '[MATCH LOCATION] '
        'Erro ao desativar localização: '
        '$error',
      );

      return false;
    }
  }

  // ============================================================
  // APAGAR LOCALIZAÇÃO
  // ============================================================
  //
  // Mais forte que disableLocation().
  //
  // Remove as coordenadas armazenadas do perfil.
  //
  // Pode ser usado futuramente em:
  //
  // Configurações
  //     ↓
  // "Remover minha localização"
  //
  // ============================================================

  Future<bool> clearLocation() async {
    final userId = currentUserId;

    if (userId == null) {
      return false;
    }

    try {
      await _supabase
          .from(_profilesTable)
          .update({
            'latitude': null,

            'longitude': null,

            'location_enabled': false,

            'location_updated_at': null,

            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);

      debugPrint(
        '[MATCH LOCATION] '
        'Localização removida.',
      );

      return true;
    } on PostgrestException catch (error) {
      debugPrint(
        '[MATCH LOCATION] '
        'Erro Supabase ao remover localização: '
        '${error.message}',
      );

      return false;
    } catch (error) {
      debugPrint(
        '[MATCH LOCATION] '
        'Erro ao remover localização: '
        '$error',
      );

      return false;
    }
  }

  // ============================================================
  // ABRIR CONFIGURAÇÕES DE LOCALIZAÇÃO
  // ============================================================

  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (error) {
      debugPrint(
        '[MATCH LOCATION] '
        'Erro ao abrir configurações de localização: '
        '$error',
      );

      return false;
    }
  }

  // ============================================================
  // ABRIR CONFIGURAÇÕES DO APP
  // ============================================================

  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (error) {
      debugPrint(
        '[MATCH LOCATION] '
        'Erro ao abrir configurações do app: '
        '$error',
      );

      return false;
    }
  }
}
