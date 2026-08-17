import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/project_message_model.dart';

// ============================================================
// PROJECT CHAT SERVICE
// ============================================================
//
// Responsável pela comunicação entre:
//
// Flutter
//    ↓
// public.project_messages
//    ↓
// Supabase Realtime
//
// MODELO DO CHAT:
//
// O chat pertence à Studio Session.
//
// Portanto:
//
// project_id
//
// identifica a conversa.
//
// NÃO existe:
//
// receiver_id
//
// Isso permite:
//
// João + Maria
//      ↓
// project_id = X
//
// Pedro entra depois
//      ↓
// project_id = X
//
// João + Maria + Pedro
//      ↓
// continuam usando o mesmo histórico.
//
// Este service:
//
// - identifica o usuário autenticado;
// - busca mensagens da Studio Session;
// - envia mensagens para a Studio Session;
// - abre stream Realtime;
// - aceita mensagens de vários sender_id;
// - valida conteúdo;
// - mantém cada conversa isolada pelo projectId;
// - permite apagar somente mensagens do usuário autenticado.
//
// IMPORTANTE:
//
// A autorização REAL continua protegida pelas políticas RLS
// configuradas no Supabase.
//
// A RLS deve garantir que:
//
// - somente membros do projeto leiam mensagens;
// - somente membros do projeto enviem mensagens;
// - somente o autor apague sua própria mensagem.
//
// ============================================================

class ProjectChatService {
  // ==========================================================
  // TABELA
  // ==========================================================

  static const String _table = 'project_messages';

  static const String _audioBucket = 'chat-audio';

  // ==========================================================
  // LIMITES
  // ==========================================================

  static const int maxMessageLength = 4000;

  static const int defaultHistoryLimit = 200;

  static const int maxHistoryLimit = 500;

  // ==========================================================
  // CAMPOS
  // ==========================================================
  //
  // Mantemos centralizado para evitar divergência entre:
  //
  // - SELECT;
  // - INSERT RETURNING;
  // - carregamento manual.
  //
  // ==========================================================

  static const String _messageFields = '''
    id,
    project_id,
    sender_id,
    content,
    message_type,
    audio_path,
    audio_duration_ms,
    created_at
  ''';

  // ==========================================================
  // SUPABASE
  // ==========================================================

  final SupabaseClient _supabase;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  ProjectChatService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  // ==========================================================
  // USUÁRIO ATUAL
  // ==========================================================

  String? get currentUserId {
    final id = _supabase.auth.currentUser?.id.trim();

    if (id == null || id.isEmpty) {
      return null;
    }

    return id;
  }

  // ==========================================================
  // USUÁRIO OBRIGATÓRIO
  // ==========================================================

  String requireCurrentUserId() {
    final id = currentUserId;

    if (id == null) {
      throw StateError('Usuário não autenticado.');
    }

    return id;
  }

  // ==========================================================
  // STREAM DE MENSAGENS
  // ==========================================================
  //
  // O stream:
  //
  // 1. recebe o estado inicial;
  // 2. continua ouvindo inserts / updates / deletes;
  // 3. entrega somente mensagens do projectId informado;
  // 4. aceita qualquer sender_id autorizado pela RLS.
  //
  // Exemplo:
  //
  // project_id = X
  //
  // sender_id = João
  // sender_id = Maria
  // sender_id = Pedro
  //
  // Todos aparecem no MESMO stream.
  //
  // ==========================================================

  Stream<List<ProjectMessageModel>> streamMessages({
    required String projectId,
  }) {
    final normalizedProjectId = _required(projectId, 'projectId');

    // ========================================================
    // AUTH
    // ========================================================

    requireCurrentUserId();

    return _supabase
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('project_id', normalizedProjectId)
        .order('created_at', ascending: true)
        .map((rows) {
          final messages = <ProjectMessageModel>[];

          for (final row in rows) {
            final message = ProjectMessageModel.fromMap(
              Map<String, dynamic>.from(row),
            );

            // ==================================================
            // VALIDAR ID
            // ==================================================

            if (message.id.isEmpty) {
              continue;
            }

            // ==================================================
            // VALIDAR PROJECT
            // ==================================================

            if (message.projectId != normalizedProjectId) {
              continue;
            }

            messages.add(message);
          }

          // ==================================================
          // ORDENAR DEFENSIVAMENTE
          // ==================================================

          messages.sort(
            (first, second) => first.createdAt.compareTo(second.createdAt),
          );

          return List<ProjectMessageModel>.unmodifiable(messages);
        });
  }

  // ==========================================================
  // CARREGAR MENSAGENS
  // ==========================================================
  //
  // Não é obrigatório para o Realtime, pois stream() já envia
  // o estado inicial.
  //
  // Mantemos este método para:
  //
  // - paginação futura;
  // - histórico;
  // - carregamento manual;
  // - testes;
  // - recuperação após reconexão.
  //
  // ==========================================================

  Future<List<ProjectMessageModel>> getMessages({
    required String projectId,
    int limit = defaultHistoryLimit,
  }) async {
    final normalizedProjectId = _required(projectId, 'projectId');

    // ========================================================
    // AUTH
    // ========================================================

    requireCurrentUserId();

    // ========================================================
    // LIMIT
    // ========================================================

    final normalizedLimit = limit.clamp(1, maxHistoryLimit);

    try {
      final response = await _supabase
          .from(_table)
          .select(_messageFields)
          .eq('project_id', normalizedProjectId)
          .order('created_at', ascending: false)
          .limit(normalizedLimit);

      final messages = <ProjectMessageModel>[];

      for (final row in response) {
        final message = ProjectMessageModel.fromMap(
          Map<String, dynamic>.from(row),
        );

        if (message.id.isEmpty) {
          continue;
        }

        if (message.projectId != normalizedProjectId) {
          continue;
        }

        messages.add(message);
      }

      // ======================================================
      // ORDEM PARA UI
      // ======================================================
      //
      // A consulta busca:
      //
      // mais recente
      // ↓
      // mais antigo
      //
      // por eficiência com LIMIT.
      //
      // A UI precisa:
      //
      // mais antigo
      // ↓
      // mais recente
      //
      // ======================================================

      final ordered = messages.reversed.toList(growable: false);

      return List<ProjectMessageModel>.unmodifiable(ordered);
    } on PostgrestException catch (error) {
      debugPrint(
        '[PROJECT CHAT] '
        'Erro ao carregar mensagens: '
        '${error.message}',
      );

      debugPrint(
        '[PROJECT CHAT] '
        'Código: '
        '${error.code}',
      );

      rethrow;
    }
  }

  // ==========================================================
  // ENVIAR MENSAGEM
  // ==========================================================
  //
  // IMPORTANTE:
  //
  // Não existe targetUserId.
  //
  // A mensagem é enviada para:
  //
  // projectId
  //
  // O senderId identifica somente QUEM falou.
  //
  // Todos os membros autorizados pela RLS e conectados ao
  // mesmo projectId recebem a mensagem.
  //
  // ==========================================================

  Future<ProjectMessageModel> sendMessage({
    required String projectId,
    required String content,
  }) async {
    final normalizedProjectId = _required(projectId, 'projectId');

    final normalizedContent = _normalizeMessage(content);

    final userId = requireCurrentUserId();

    try {
      // ========================================================
      // INSERT
      // ========================================================

      final response = await _supabase
          .from(_table)
          .insert({
            'project_id': normalizedProjectId,

            'sender_id': userId,

            'content': normalizedContent,
          })
          .select(_messageFields)
          .single();

      // ========================================================
      // MODEL
      // ========================================================

      final message = ProjectMessageModel.fromMap(
        Map<String, dynamic>.from(response),
      );

      // ========================================================
      // VALIDAR ID
      // ========================================================

      if (message.id.isEmpty) {
        throw StateError('Mensagem criada sem ID.');
      }

      // ========================================================
      // VALIDAR PROJECT
      // ========================================================

      if (message.projectId != normalizedProjectId) {
        throw StateError('Mensagem criada em uma Studio Session diferente.');
      }

      // ========================================================
      // VALIDAR SENDER
      // ========================================================

      if (message.senderId != userId) {
        throw StateError('Mensagem criada com remetente inesperado.');
      }

      debugPrint(
        '[PROJECT CHAT] '
        'Mensagem enviada: '
        '${message.id} '
        '| project: '
        '$normalizedProjectId '
        '| sender: '
        '$userId',
      );

      return message;
    } on PostgrestException catch (error) {
      debugPrint(
        '[PROJECT CHAT] '
        'Erro Supabase ao enviar mensagem: '
        '${error.message}',
      );

      debugPrint(
        '[PROJECT CHAT] '
        'Código: '
        '${error.code}',
      );

      rethrow;
    }
  }

  // ==========================================================
  // ENVIAR MENSAGEM DE ÁUDIO
  // ==========================================================

  Future<ProjectMessageModel> sendAudioMessage({
    required String projectId,
    required Uint8List audioBytes,
    required int audioDurationMs,
    String extension = 'wav',
    String mimeType = 'audio/wav',
  }) async {
    final normalizedProjectId = _required(projectId, 'projectId');

    final normalizedExtension = _required(extension, 'extension').toLowerCase();

    final normalizedMimeType = _required(mimeType, 'mimeType').toLowerCase();

    if (audioBytes.isEmpty) {
      throw ArgumentError('audioBytes não pode ser vazio.');
    }

    if (audioDurationMs <= 0) {
      throw ArgumentError('audioDurationMs deve ser maior que zero.');
    }

    final userId = requireCurrentUserId();

    final now = DateTime.now().toUtc();

    final fileName = '${now.microsecondsSinceEpoch}.$normalizedExtension';

    final audioPath = '$normalizedProjectId/$userId/$fileName';

    var uploaded = false;

    try {
      await _supabase.storage
          .from(_audioBucket)
          .uploadBinary(
            audioPath,
            audioBytes,
            fileOptions: FileOptions(
              contentType: normalizedMimeType,
              upsert: false,
            ),
          );

      uploaded = true;

      final response = await _supabase
          .from(_table)
          .insert({
            'project_id': normalizedProjectId,
            'sender_id': userId,
            'content': '',
            'message_type': 'audio',
            'audio_path': audioPath,
            'audio_duration_ms': audioDurationMs,
          })
          .select(_messageFields)
          .single();

      final message = ProjectMessageModel.fromMap(
        Map<String, dynamic>.from(response),
      );

      if (message.id.isEmpty) {
        throw StateError('Mensagem de áudio criada sem ID.');
      }

      if (message.projectId != normalizedProjectId) {
        throw StateError('Mensagem de áudio criada em outra Studio Session.');
      }

      if (message.senderId != userId) {
        throw StateError('Mensagem de áudio criada com remetente inesperado.');
      }

      debugPrint(
        '[PROJECT CHAT] '
        'Áudio enviado: '
        '${message.id} '
        '| duração: '
        '$audioDurationMs ms',
      );

      return message;
    } catch (error, stackTrace) {
      debugPrint(
        '[PROJECT CHAT] '
        'Erro ao enviar áudio: '
        '$error',
      );

      debugPrint(
        '[PROJECT CHAT] '
        'StackTrace: '
        '$stackTrace',
      );

      if (uploaded) {
        try {
          await _supabase.storage.from(_audioBucket).remove([audioPath]);
        } catch (cleanupError) {
          debugPrint(
            '[PROJECT CHAT] '
            'Falha ao remover áudio órfão: '
            '$cleanupError',
          );
        }
      }

      rethrow;
    }
  }

  // ==========================================================
  // APAGAR MENSAGEM
  // ==========================================================
  //
  // Fazemos a filtragem por:
  //
  // id
  // +
  // sender_id
  //
  // Mesmo assim, a RLS continua sendo a proteção real.
  //
  // ==========================================================

  Future<void> deleteMessage({required String messageId}) async {
    final normalizedMessageId = _required(messageId, 'messageId');

    final userId = requireCurrentUserId();

    // ========================================================
    // CARREGAR MENSAGEM
    // ========================================================
    //
    // Precisamos conhecer:
    //
    // - sender_id;
    // - created_at;
    // - message_type;
    // - audio_path.
    //
    // Assim conseguimos aplicar a regra de 24 horas e, quando
    // for áudio, remover também o arquivo do Storage.
    //
    // ========================================================

    final response = await _supabase
        .from(_table)
        .select(_messageFields)
        .eq('id', normalizedMessageId)
        .maybeSingle();

    if (response == null) {
      throw StateError('Mensagem não encontrada.');
    }

    final message = ProjectMessageModel.fromMap(
      Map<String, dynamic>.from(response),
    );

    // ========================================================
    // AUTOR
    // ========================================================

    if (message.senderId != userId) {
      throw StateError('Você só pode apagar suas próprias mensagens.');
    }

    // ========================================================
    // SISTEMA
    // ========================================================

    if (message.isSystem) {
      throw StateError(
        'Mensagens do sistema não podem ser apagadas por usuários.',
      );
    }

    // ========================================================
    // LIMITE DE 24 HORAS
    // ========================================================

    if (!message.canDelete) {
      throw StateError(
        'O prazo de 24 horas para apagar esta mensagem terminou.',
      );
    }

    final audioPath = message.audioPath?.trim();

    final shouldDeleteAudio =
        message.isAudio && audioPath != null && audioPath.isNotEmpty;

    try {
      // ======================================================
      // DELETE DA MENSAGEM
      // ======================================================
      //
      // Fazemos primeiro o DELETE no banco.
      //
      // A RLS deve repetir a mesma regra de 24 horas para ser
      // a proteção real contra chamadas externas.
      //
      // ======================================================

      await _supabase
          .from(_table)
          .delete()
          .eq('id', normalizedMessageId)
          .eq('sender_id', userId);

      // ======================================================
      // DELETE DO ÁUDIO
      // ======================================================
      //
      // Se a mensagem era de áudio, removemos também o WAV do
      // bucket privado.
      //
      // ======================================================

      if (shouldDeleteAudio) {
        try {
          await _supabase.storage.from(_audioBucket).remove([audioPath]);

          debugPrint(
            '[PROJECT CHAT] '
            'Arquivo de áudio removido: '
            '$audioPath',
          );
        } catch (storageError, storageStackTrace) {
          // A mensagem já foi apagada do banco.
          //
          // Portanto não voltamos a inserir a linha.
          // Apenas registramos a falha para diagnóstico.

          debugPrint(
            '[PROJECT CHAT] '
            'Mensagem apagada, mas houve erro ao remover '
            'o arquivo de áudio: '
            '$storageError',
          );

          debugPrint(
            '[PROJECT CHAT] '
            'Storage StackTrace: '
            '$storageStackTrace',
          );
        }
      }

      debugPrint(
        '[PROJECT CHAT] '
        'Mensagem apagada: '
        '$normalizedMessageId',
      );
    } on PostgrestException catch (error) {
      debugPrint(
        '[PROJECT CHAT] '
        'Erro ao apagar mensagem: '
        '${error.message}',
      );

      debugPrint(
        '[PROJECT CHAT] '
        'Código: '
        '${error.code}',
      );

      rethrow;
    }
  }

  // ==========================================================
  // EXISTEM MENSAGENS?
  // ==========================================================

  Future<bool> hasMessages({required String projectId}) async {
    final messages = await getMessages(projectId: projectId, limit: 1);

    return messages.isNotEmpty;
  }

  // ==========================================================
  // ÚLTIMA MENSAGEM
  // ==========================================================

  Future<ProjectMessageModel?> getLatestMessage({
    required String projectId,
  }) async {
    final normalizedProjectId = _required(projectId, 'projectId');

    requireCurrentUserId();

    try {
      final response = await _supabase
          .from(_table)
          .select(_messageFields)
          .eq('project_id', normalizedProjectId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        return null;
      }

      final message = ProjectMessageModel.fromMap(
        Map<String, dynamic>.from(response.first),
      );

      if (message.id.isEmpty || message.projectId != normalizedProjectId) {
        return null;
      }

      return message;
    } on PostgrestException catch (error) {
      debugPrint(
        '[PROJECT CHAT] '
        'Erro ao buscar última mensagem: '
        '${error.message}',
      );

      rethrow;
    }
  }

  // ==========================================================
  // CRIAR URL PARA REPRODUÇÃO DO ÁUDIO
  // ==========================================================

  Future<String> createAudioPlaybackUrl({
    required String audioPath,
    int expiresInSeconds = 3600,
  }) async {
    final normalizedAudioPath = _required(audioPath, 'audioPath');

    final normalizedExpiresIn = expiresInSeconds.clamp(60, 86400);

    requireCurrentUserId();

    final url = await _supabase.storage
        .from(_audioBucket)
        .createSignedUrl(normalizedAudioPath, normalizedExpiresIn);

    final normalizedUrl = url.trim();

    if (normalizedUrl.isEmpty) {
      throw StateError('O Supabase retornou uma URL de áudio vazia.');
    }

    return normalizedUrl;
  }

  // ==========================================================
  // NORMALIZAR MENSAGEM
  // ==========================================================

  String _normalizeMessage(String content) {
    final normalized = content.trim();

    if (normalized.isEmpty) {
      throw ArgumentError('A mensagem não pode ser vazia.');
    }

    if (normalized.length > maxMessageLength) {
      throw ArgumentError(
        'A mensagem pode possuir no máximo '
        '$maxMessageLength caracteres.',
      );
    }

    return normalized;
  }

  // ==========================================================
  // REQUIRED
  // ==========================================================

  String _required(String value, String field) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError('$field não pode ser vazio.');
    }

    return normalized;
  }
}
