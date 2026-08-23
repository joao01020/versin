import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// MATCH LOCATION CONSENT SERVICE
// ============================================================
//
// Responsável por persistir a confirmação apresentada antes
// do modo de descoberta por proximidade.
//
// IMPORTANTE:
//
// Este consentimento é uma confirmação interna do Versin.
//
// Ele NÃO substitui:
//
// - permissão nativa do Android;
// - permissão nativa do iOS;
// - permissão nativa do macOS;
// - permissão nativa do Windows;
// - permissão/GeoClue no Linux.
//
// O MatchLocationService continua responsável por solicitar a
// permissão real do sistema operacional.
//
// ============================================================
//
// PRIVACIDADE
//
// A localização é utilizada para:
//
// - obter uma posição aproximada do usuário;
// - calcular a distância entre profissionais;
// - encontrar artistas próximos;
// - facilitar projetos e colaborações presenciais.
//
// A localização exata NÃO é exibida para outros usuários.
//
// Outros usuários NÃO recebem:
//
// - latitude;
// - longitude;
// - coordenadas GPS;
// - endereço exato.
//
// O Match utiliza somente a informação necessária para
// determinar proximidade entre perfis.
//
// ============================================================

class MatchLocationConsentService {
  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase;

  // ============================================================
  // CONFIGURAÇÃO
  // ============================================================

  static const String _profilesTable = 'profiles';

  // ============================================================
  // VERSÃO DO CONSENTIMENTO
  // ============================================================
  //
  // Alterar esta versão sempre que houver uma mudança relevante
  // no texto, finalidade ou política apresentada ao usuário.
  //
  // Usuários que aceitaram versões anteriores precisarão
  // confirmar novamente.
  //
  // ============================================================

  static const String _consentVersion = 'v3';

  // ============================================================
  // TEXTOS DO CONSENTIMENTO
  // ============================================================
  //
  // Centralizados aqui para garantir que toda a aplicação
  // apresente a mesma explicação ao usuário.
  //
  // ============================================================

  static const String consentTitle = 'Encontrar profissionais próximos';

  static const String consentDescription =
      'Usamos sua localização aproximada para encontrar '
      'artistas e profissionais próximos de você.\n\n'
      'Isso ajuda a conectar pessoas que podem desenvolver '
      'projetos, sessões, eventos e colaborações presenciais.\n\n'
      'Não compartilhamos sua localização exata com outros '
      'usuários. Sua latitude, longitude e endereço não são '
      'exibidos no seu perfil nem enviados para outros artistas.';

  static const String consentConfirmation =
      'Confirmo que entendi e permito o uso da minha '
      'localização aproximada para encontrar profissionais '
      'próximos e facilitar projetos presenciais.';

  static const String consentPrivacyNotice =
      'Você pode negar ou revogar a permissão de localização '
      'a qualquer momento nas configurações do seu dispositivo.';

  // ============================================================
  // USER ID
  // ============================================================

  MatchLocationConsentService({
    SupabaseClient? supabase,
  }) : _supabase =
           supabase ??
           Supabase.instance.client;

  // ============================================================
  // USER ID
  // ============================================================

  String? get currentUserId {
    final id = _supabase.auth.currentUser?.id.trim();

    if (id ==
            null ||
        id.isEmpty) {
      return null;
    }

    return id;
  }

  // ============================================================
  // VERSÃO ATUAL
  // ============================================================

  String get consentVersion {
    return _consentVersion;
  }

  // ============================================================
  // JÁ ACEITOU?
  // ============================================================

  Future<
    bool
  >
  hasAcceptedNearbyLocation() async {
    final userId = currentUserId;

    if (userId ==
        null) {
      debugPrint(
        '[MATCH CONSENT] '
        'Usuário não autenticado.',
      );

      return false;
    }

    try {
      final response = await _supabase
          .from(
            _profilesTable,
          )
          .select(
            '''
                nearby_location_consent,
                nearby_location_consent_version,
                nearby_location_consent_at
                ''',
          )
          .eq(
            'id',
            userId,
          )
          .maybeSingle();

      if (response ==
          null) {
        debugPrint(
          '[MATCH CONSENT] '
          'Perfil não encontrado.',
        );

        return false;
      }

      final accepted =
          response['nearby_location_consent'] ==
          true;

      final version = response['nearby_location_consent_version']?.toString().trim();

      final valid =
          accepted &&
          version ==
              _consentVersion;

      debugPrint(
        '[MATCH CONSENT] '
        'Consentimento aceito: $accepted',
      );

      debugPrint(
        '[MATCH CONSENT] '
        'Versão salva: $version',
      );

      debugPrint(
        '[MATCH CONSENT] '
        'Versão atual: $_consentVersion',
      );

      debugPrint(
        '[MATCH CONSENT] '
        'Consentimento válido: $valid',
      );

      return valid;
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[MATCH CONSENT] '
        'Erro Supabase ao consultar consentimento.',
      );

      debugPrint(
        '[MATCH CONSENT] '
        'Mensagem: ${error.message}',
      );

      debugPrint(
        '[MATCH CONSENT] '
        'Código: ${error.code}',
      );

      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH CONSENT] '
        'Erro inesperado ao consultar consentimento: '
        '$error',
      );

      debugPrint(
        '[MATCH CONSENT] '
        'Stack trace: $stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // ACEITAR
  // ============================================================

  Future<
    void
  >
  acceptNearbyLocation() async {
    final userId = currentUserId;

    if (userId ==
        null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await _supabase
          .from(
            _profilesTable,
          )
          .update(
            {
              'nearby_location_consent': true,

              'nearby_location_consent_version': _consentVersion,

              'nearby_location_consent_at': now,

              'updated_at': now,
            },
          )
          .eq(
            'id',
            userId,
          );

      debugPrint(
        '[MATCH CONSENT] '
        'Consentimento salvo.',
      );

      debugPrint(
        '[MATCH CONSENT] '
        'Versão: $_consentVersion',
      );

      debugPrint(
        '[MATCH CONSENT] '
        'Data: $now',
      );
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[MATCH CONSENT] '
        'Erro Supabase ao salvar consentimento.',
      );

      debugPrint(
        '[MATCH CONSENT] '
        'Mensagem: ${error.message}',
      );

      debugPrint(
        '[MATCH CONSENT] '
        'Código: ${error.code}',
      );

      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH CONSENT] '
        'Erro inesperado ao salvar consentimento: '
        '$error',
      );

      debugPrint(
        '[MATCH CONSENT] '
        'Stack trace: $stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // REVOGAR CONFIRMAÇÃO INTERNA
  // ============================================================
  //
  // Útil para:
  //
  // Configurações
  //      ↓
  // Privacidade
  //      ↓
  // Localização
  //      ↓
  // Desativar descoberta por proximidade
  //
  // IMPORTANTE:
  //
  // Isso remove o consentimento salvo no Versin.
  //
  // Não revoga automaticamente a permissão nativa concedida ao
  // aplicativo no sistema operacional.
  //
  // ============================================================

  Future<
    void
  >
  revokeNearbyLocationConsent() async {
    final userId = currentUserId;

    if (userId ==
        null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await _supabase
          .from(
            _profilesTable,
          )
          .update(
            {
              'nearby_location_consent': false,

              'nearby_location_consent_version': null,

              'nearby_location_consent_at': null,

              'updated_at': now,
            },
          )
          .eq(
            'id',
            userId,
          );

      debugPrint(
        '[MATCH CONSENT] '
        'Consentimento revogado.',
      );
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[MATCH CONSENT] '
        'Erro Supabase ao revogar consentimento.',
      );

      debugPrint(
        '[MATCH CONSENT] '
        'Mensagem: ${error.message}',
      );

      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH CONSENT] '
        'Erro inesperado ao revogar consentimento: '
        '$error',
      );

      debugPrint(
        '[MATCH CONSENT] '
        'Stack trace: $stackTrace',
      );

      rethrow;
    }
  }
}
