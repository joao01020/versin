import '../data/models/project_call_model.dart';
import '../types/call_media_type.dart';

// ============================================================
// PROJECT CALL REPOSITORY
// ============================================================
//
// Contrato da camada de persistência das chamadas.
//
// Essa interface NÃO conhece:
//
// - Supabase;
// - SQL;
// - RPC;
// - WebRTC;
// - câmera;
// - microfone;
// - SDP;
// - ICE.
//
// A implementação concreta fica em:
//
// data/repositories/project_call_repository_impl.dart
//
// ============================================================

abstract class ProjectCallRepository {
  // ==========================================================
  // USUÁRIO ATUAL
  // ==========================================================

  String get currentUserId;

  // ==========================================================
  // BUSCAR CHAMADA
  // ==========================================================

  Future<ProjectCallModel?> getCallById({required String callId});

  // ==========================================================
  // CHAMADAS DO PROJETO
  // ==========================================================

  Future<List<ProjectCallModel>> getProjectCalls({required String projectId});

  // ==========================================================
  // CHAMADA ATIVA
  // ==========================================================

  Future<ProjectCallModel?> getActiveCall({required String projectId});

  // ==========================================================
  // REALTIME DO PROJETO
  // ==========================================================

  Stream<List<ProjectCallModel>> streamProjectCalls({
    required String projectId,
  });

  // ==========================================================
  // REALTIME DE UMA CHAMADA
  // ==========================================================

  Stream<ProjectCallModel?> streamCall({required String callId});

  // ==========================================================
  // CRIAR CHAMADA
  // ==========================================================

  Future<ProjectCallModel> createCall({
    required String projectId,
    required CallMediaType mediaType,
    String? targetUserId,
  });

  // ==========================================================
  // ACEITAR
  // ==========================================================

  Future<ProjectCallModel> acceptCall({required String callId});

  // ==========================================================
  // RECUSAR
  // ==========================================================

  Future<ProjectCallModel> rejectCall({required String callId});

  // ==========================================================
  // ENCERRAR
  // ==========================================================

  Future<ProjectCallModel> endCall({required String callId});

  // ==========================================================
  // EXISTE CHAMADA ATIVA?
  // ==========================================================

  Future<bool> hasActiveCall({required String projectId});
}
