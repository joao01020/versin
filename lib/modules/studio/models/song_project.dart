import 'package:versin/modules/studio/models/mind_map_node.dart';

// ============================================================
// PROJETO DE MÚSICA
// ============================================================

class SongProject {
  final String id;

  String title;
  String lyrics;

  int bpm;

  String? vibe;
  String? technique;

  DateTime createdAt;
  DateTime updatedAt;

  final List<
    String
  >
  timelineWords;
  final List<
    MindMapNode
  >
  mindMapNodes;

  SongProject({
    required this.id,
    required this.title,
    this.lyrics = '',
    this.bpm = 120,
    this.vibe,
    this.technique,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<
      String
    >?
    timelineWords,
    List<
      MindMapNode
    >?
    mindMapNodes,
  }) : createdAt =
           createdAt ??
           DateTime.now(),
       updatedAt =
           updatedAt ??
           DateTime.now(),
       timelineWords =
           timelineWords ??
           [],
       mindMapNodes =
           mindMapNodes ??
           [];

  // ==========================================================
  // FACTORY — NOVO PROJETO
  // ==========================================================

  factory SongProject.create({
    String title = 'MINHA MÚSICA',
    int bpm = 120,
  }) {
    final now = DateTime.now();

    return SongProject(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      bpm: bpm,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ==========================================================
  // LETRA
  // ==========================================================

  void updateLyrics(
    String value,
  ) {
    lyrics = value;
    touch();
  }

  bool get hasLyrics {
    return lyrics.trim().isNotEmpty;
  }

  // ==========================================================
  // TÍTULO
  // ==========================================================

  void updateTitle(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return;
    }

    title = normalized;
    touch();
  }

  // ==========================================================
  // BPM
  // ==========================================================

  void updateBpm(
    int value,
  ) {
    if (value <=
        0) {
      return;
    }

    bpm = value;
    touch();
  }

  // ==========================================================
  // TIMELINE
  // ==========================================================

  bool hasTimelineWord(
    String word,
  ) {
    final normalized = _normalizeWord(
      word,
    );

    return timelineWords.any(
      (
        item,
      ) =>
          _normalizeWord(
            item,
          ) ==
          normalized,
    );
  }

  bool addTimelineWord(
    String word,
  ) {
    final normalized = word.trim();

    if (normalized.isEmpty) {
      return false;
    }

    if (hasTimelineWord(
      normalized,
    )) {
      return false;
    }

    timelineWords.add(
      normalized,
    );

    touch();

    return true;
  }

  bool removeTimelineWord(
    String word,
  ) {
    final normalized = _normalizeWord(
      word,
    );

    final index = timelineWords.indexWhere(
      (
        item,
      ) =>
          _normalizeWord(
            item,
          ) ==
          normalized,
    );

    if (index ==
        -1) {
      return false;
    }

    timelineWords.removeAt(
      index,
    );

    touch();

    return true;
  }

  void clearTimeline() {
    if (timelineWords.isEmpty) {
      return;
    }

    timelineWords.clear();
    touch();
  }

  // ==========================================================
  // MAPA MENTAL
  // ==========================================================

  MindMapNode? findMindMapNode(
    String nodeId,
  ) {
    for (final node in mindMapNodes) {
      if (node.id ==
          nodeId) {
        return node;
      }
    }

    return null;
  }

  bool addMindMapNode(
    MindMapNode node,
  ) {
    final exists = mindMapNodes.any(
      (
        item,
      ) =>
          item.id ==
          node.id,
    );

    if (exists) {
      return false;
    }

    mindMapNodes.add(
      node,
    );

    touch();

    return true;
  }

  bool removeMindMapNode(
    String nodeId,
  ) {
    final index = mindMapNodes.indexWhere(
      (
        node,
      ) =>
          node.id ==
          nodeId,
    );

    if (index ==
        -1) {
      return false;
    }

    mindMapNodes.removeAt(
      index,
    );

    // Remove conexões que apontavam para o nó excluído.
    for (final node in mindMapNodes) {
      node.disconnectFrom(
        nodeId,
      );
    }

    touch();

    return true;
  }

  bool connectMindMapNodes(
    String firstNodeId,
    String secondNodeId,
  ) {
    if (firstNodeId ==
        secondNodeId) {
      return false;
    }

    final firstNode = findMindMapNode(
      firstNodeId,
    );

    final secondNode = findMindMapNode(
      secondNodeId,
    );

    if (firstNode ==
            null ||
        secondNode ==
            null) {
      return false;
    }

    // A conexão é mantida nos dois sentidos.
    firstNode.connectTo(
      secondNodeId,
    );

    secondNode.connectTo(
      firstNodeId,
    );

    touch();

    return true;
  }

  bool disconnectMindMapNodes(
    String firstNodeId,
    String secondNodeId,
  ) {
    final firstNode = findMindMapNode(
      firstNodeId,
    );

    final secondNode = findMindMapNode(
      secondNodeId,
    );

    if (firstNode ==
            null ||
        secondNode ==
            null) {
      return false;
    }

    firstNode.disconnectFrom(
      secondNodeId,
    );

    secondNode.disconnectFrom(
      firstNodeId,
    );

    touch();

    return true;
  }

  void clearMindMap() {
    if (mindMapNodes.isEmpty) {
      return;
    }

    mindMapNodes.clear();
    touch();
  }

  // ==========================================================
  // PALAVRA USADA NA LETRA
  // ==========================================================

  bool isTimelineWordUsed(
    String word,
  ) {
    final normalizedWord = _normalizeWord(
      word,
    );

    if (normalizedWord.isEmpty) {
      return false;
    }

    final words = lyrics
        .toLowerCase()
        .split(
          RegExp(
            r'[^a-zA-ZÀ-ÿ0-9]+',
          ),
        )
        .where(
          (
            item,
          ) => item.isNotEmpty,
        );

    return words.any(
      (
        item,
      ) =>
          _normalizeWord(
            item,
          ) ==
          normalizedWord,
    );
  }

  // ==========================================================
  // DATA DE ALTERAÇÃO
  // ==========================================================

  void touch() {
    updatedAt = DateTime.now();
  }

  // ==========================================================
  // COPY
  // ==========================================================

  SongProject copyWith({
    String? id,
    String? title,
    String? lyrics,
    int? bpm,
    String? vibe,
    String? technique,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<
      String
    >?
    timelineWords,
    List<
      MindMapNode
    >?
    mindMapNodes,
  }) {
    return SongProject(
      id:
          id ??
          this.id,
      title:
          title ??
          this.title,
      lyrics:
          lyrics ??
          this.lyrics,
      bpm:
          bpm ??
          this.bpm,
      vibe:
          vibe ??
          this.vibe,
      technique:
          technique ??
          this.technique,
      createdAt:
          createdAt ??
          this.createdAt,
      updatedAt:
          updatedAt ??
          this.updatedAt,
      timelineWords:
          timelineWords ??
          List<
            String
          >.from(
            this.timelineWords,
          ),
      mindMapNodes:
          mindMapNodes ??
          this.mindMapNodes
              .map(
                (
                  node,
                ) => node.copyWith(),
              )
              .toList(),
    );
  }

  // ==========================================================
  // JSON
  // ==========================================================

  Map<
    String,
    dynamic
  >
  toJson() {
    return {
      'id': id,
      'title': title,
      'lyrics': lyrics,
      'bpm': bpm,
      'vibe': vibe,
      'technique': technique,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'timeline_words': timelineWords,
      'mind_map_nodes': mindMapNodes
          .map(
            (
              node,
            ) => node.toJson(),
          )
          .toList(),
    };
  }

  factory SongProject.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    return SongProject(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title:
          json['title']?.toString() ??
          'MINHA MÚSICA',
      lyrics:
          json['lyrics']?.toString() ??
          '',
      bpm:
          _toInt(
            json['bpm'],
          ) ??
          120,
      vibe: json['vibe']?.toString(),
      technique: json['technique']?.toString(),
      createdAt: _toDateTime(
        json['created_at'],
      ),
      updatedAt: _toDateTime(
        json['updated_at'],
      ),
      timelineWords:
          (json['timeline_words']
                  as List?)
              ?.map(
                (
                  item,
                ) => item.toString(),
              )
              .toList() ??
          [],
      mindMapNodes:
          (json['mind_map_nodes']
                  as List?)
              ?.whereType<
                Map<
                  String,
                  dynamic
                >
              >()
              .map(
                MindMapNode.fromJson,
              )
              .toList() ??
          [],
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  static String _normalizeWord(
    String value,
  ) {
    return value.trim().toLowerCase();
  }

  static int? _toInt(
    dynamic value,
  ) {
    if (value
        is int) {
      return value;
    }

    if (value
        is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ??
          '',
    );
  }

  static DateTime? _toDateTime(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}
