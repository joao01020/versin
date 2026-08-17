import '../data/models/communication_permission_model.dart';
import '../data/models/communication_request_model.dart';

// ============================================================
// COMMUNICATION PERMISSION REPOSITORY
// ============================================================
//
// Contrato da camada de persistência responsável por:
//
// - permissões de áudio;
// - permissões de vídeo;
// - pedidos de desbloqueio de vídeo;
// - aceite/rejeição de consentimento;
// - observação Realtime das permissões;
// - observação Realtime dos pedidos.
//
// IMPORTANTE:
//
// Esta interface NÃO conhece Supabase.
//
// A implementação concreta fica em:
//
// data/repositories/
// communication_permission_repository_impl.dart
//
// ============================================================

abstract class CommunicationPermissionRepository {
  // ==========================================================
  // USUÁRIO ATUAL
  // ==========================================================

  String get currentUserId;

  // ==========================================================
  // PERMISSÃO DE UM USUÁRIO
  // ==========================================================

  Future<
    CommunicationPermissionModel?
  >
  getPermission({
    required String projectId,
    required String userId,
  });

  // ==========================================================
  // PERMISSÃO DO USUÁRIO AUTENTICADO
  // ==========================================================

  Future<
    CommunicationPermissionModel?
  >
  getCurrentUserPermission({
    required String projectId,
  });

  // ==========================================================
  // TODAS AS PERMISSÕES DO PROJETO
  // ==========================================================

  Future<
    List<
      CommunicationPermissionModel
    >
  >
  getProjectPermissions({
    required String projectId,
  });

  // ==========================================================
  // REALTIME DAS PERMISSÕES
  // ==========================================================

  Stream<
    List<
      CommunicationPermissionModel
    >
  >
  streamProjectPermissions({
    required String projectId,
  });

  // ==========================================================
  // PEDIDO POR ID
  // ==========================================================

  Future<
    CommunicationRequestModel?
  >
  getRequestById({
    required String requestId,
  });

  // ==========================================================
  // PEDIDOS DO PROJETO
  // ==========================================================

  Future<
    List<
      CommunicationRequestModel
    >
  >
  getProjectRequests({
    required String projectId,
  });

  // ==========================================================
  // PEDIDOS RECEBIDOS
  // ==========================================================

  Future<
    List<
      CommunicationRequestModel
    >
  >
  getReceivedRequests({
    required String projectId,
  });

  // ==========================================================
  // REALTIME DE PEDIDOS RECEBIDOS
  // ==========================================================

  Stream<
    List<
      CommunicationRequestModel
    >
  >
  streamReceivedRequests({
    required String projectId,
  });

  // ==========================================================
  // SOLICITAR DESBLOQUEIO DE VÍDEO
  // ==========================================================

  Future<
    CommunicationRequestModel
  >
  requestVideo({
    required String projectId,
    required String targetUserId,
  });

  // ==========================================================
  // ACEITAR DESBLOQUEIO DE VÍDEO
  // ==========================================================

  Future<
    CommunicationRequestModel
  >
  acceptVideoRequest({
    required String requestId,
  });

  // ==========================================================
  // RECUSAR DESBLOQUEIO DE VÍDEO
  // ==========================================================

  Future<
    CommunicationRequestModel
  >
  rejectVideoRequest({
    required String requestId,
  });

  // ==========================================================
  // VERIFICAR VÍDEO
  // ==========================================================

  Future<
    bool
  >
  isVideoAllowed({
    required String projectId,
    required String userId,
  });

  // ==========================================================
  // VERIFICAR ÁUDIO
  // ==========================================================

  Future<
    bool
  >
  isAudioAllowed({
    required String projectId,
    required String userId,
  });
}
