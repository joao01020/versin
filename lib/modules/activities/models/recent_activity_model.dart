import 'recent_activity_type.dart';

// ============================================================
// RECENT ACTIVITY MODEL
// ============================================================
//
// Representa uma atividade recente do usuário.
//
// Exemplo:
//
// Bem-vindo ao Versin
// Seu espaço criativo está pronto.
//
// Perfil profissional atualizado
// Função principal definida como Produtor.
//
// Nova conexão
// Você se conectou com Astryvo.
//
// ============================================================

class RecentActivityModel {
  // ============================================================
  // IDENTIFICAÇÃO
  // ============================================================

  final String id;

  // ============================================================
  // USUÁRIO
  // ============================================================

  final String userId;

  // ============================================================
  // TIPO
  // ============================================================

  final RecentActivityType type;

  // ============================================================
  // CONTEÚDO
  // ============================================================

  final String title;

  final String description;

  // ============================================================
  // METADATA
  // ============================================================
  //
  // Guarda informações extras específicas de cada atividade.
  //
  // Exemplo:
  //
  // profileUpdated:
  //
  // {
  //   "primary_role": "producer"
  // }
  //
  // connection:
  //
  // {
  //   "target_user_id": "...",
  //   "target_name": "Astryvo"
  // }
  //
  // fileAdded:
  //
  // {
  //   "file_name": "beat_final.wav"
  // }
  //
  // ============================================================

  final Map<
    String,
    dynamic
  >
  metadata;

  // ============================================================
  // DATA
  // ============================================================

  final DateTime createdAt;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const RecentActivityModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
    this.metadata =
        const <
          String,
          dynamic
        >{},
  });

  // ============================================================
  // LABEL DO TIPO
  // ============================================================

  String get typeLabel {
    return type.label;
  }

  // ============================================================
  // METADATA EXISTE
  // ============================================================

  bool get hasMetadata {
    return metadata.isNotEmpty;
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory RecentActivityModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return RecentActivityModel(
      id: _parseString(
        map['id'],
      ),

      userId: _parseString(
        map['user_id'],
      ),

      type: RecentActivityType.fromKey(
        map['type']?.toString(),
      ),

      title: _parseString(
        map['title'],
      ),

      description: _parseString(
        map['description'],
      ),

      metadata: _parseMetadata(
        map['metadata'],
      ),

      createdAt: _parseDateTime(
        map['created_at'],
      ),
    );
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory RecentActivityModel.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    return RecentActivityModel.fromMap(
      json,
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return <
      String,
      dynamic
    >{
      'id': id,

      'user_id': userId,

      'type': type.key,

      'title': title,

      'description': description,

      'metadata': metadata,

      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // MAP PARA PERSISTÊNCIA REMOTA
  // ============================================================
  //
  // Não envia:
  //
  // id
  // created_at
  //
  // porque o banco pode gerar esses valores.
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toRemoteMap() {
    return <
      String,
      dynamic
    >{
      'user_id': userId,

      'type': type.key,

      'title': title,

      'description': description,

      'metadata': metadata,
    };
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<
    String,
    dynamic
  >
  toJson() {
    return toMap();
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  RecentActivityModel copyWith({
    String? id,
    String? userId,
    RecentActivityType? type,
    String? title,
    String? description,
    Map<
      String,
      dynamic
    >?
    metadata,
    DateTime? createdAt,
  }) {
    return RecentActivityModel(
      id:
          id ??
          this.id,

      userId:
          userId ??
          this.userId,

      type:
          type ??
          this.type,

      title:
          title ??
          this.title,

      description:
          description ??
          this.description,

      metadata:
          metadata ??
          this.metadata,

      createdAt:
          createdAt ??
          this.createdAt,
    );
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'RecentActivityModel('
        'id: $id, '
        'userId: $userId, '
        'type: ${type.key}, '
        'title: $title, '
        'description: $description, '
        'metadata: $metadata, '
        'createdAt: $createdAt'
        ')';
  }

  // ============================================================
  // EQUALITY
  // ============================================================

  @override
  bool operator ==(
    Object other,
  ) {
    if (identical(
      this,
      other,
    )) {
      return true;
    }

    return other
            is RecentActivityModel &&
        other.id ==
            id;
  }

  // ============================================================
  // HASH CODE
  // ============================================================

  @override
  int get hashCode {
    return id.hashCode;
  }

  // ============================================================
  // PARSE STRING
  // ============================================================

  static String _parseString(
    dynamic value,
  ) {
    if (value ==
        null) {
      return '';
    }

    return value.toString().trim();
  }

  // ============================================================
  // PARSE METADATA
  // ============================================================

  static Map<
    String,
    dynamic
  >
  _parseMetadata(
    dynamic value,
  ) {
    if (value ==
        null) {
      return <
        String,
        dynamic
      >{};
    }

    if (value
        is Map<
          String,
          dynamic
        >) {
      return Map<
        String,
        dynamic
      >.from(
        value,
      );
    }

    if (value
        is Map) {
      return value.map(
        (
          key,
          item,
        ) {
          return MapEntry(
            key.toString(),
            item,
          );
        },
      );
    }

    return <
      String,
      dynamic
    >{};
  }

  // ============================================================
  // PARSE DATE
  // ============================================================

  static DateTime _parseDateTime(
    dynamic value,
  ) {
    if (value
        is DateTime) {
      return value;
    }

    if (value !=
        null) {
      final parsed = DateTime.tryParse(
        value.toString(),
      );

      if (parsed !=
          null) {
        return parsed;
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(
      0,
      isUtc: true,
    );
  }
}
