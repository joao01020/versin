import 'package:flutter/material.dart';

// ============================================================
// TIPO DO NÓ
// ============================================================

enum MindMapNodeType {
  idea,
  scene,
  emotion,
  image,
  rhyme,
  concept,
}

// ============================================================
// MODEL
// ============================================================

class MindMapNode {
  final String id;

  String text;
  MindMapNodeType type;

  double x;
  double y;

  final List<
    String
  >
  connections;

  MindMapNode({
    required this.id,
    required this.text,
    this.type = MindMapNodeType.idea,
    this.x = 0,
    this.y = 0,
    List<
      String
    >?
    connections,
  }) : connections =
           connections ??
           [];

  // ==========================================================
  // POSIÇÃO
  // ==========================================================

  Offset get position {
    return Offset(
      x,
      y,
    );
  }

  void setPosition(
    Offset position,
  ) {
    x = position.dx;
    y = position.dy;
  }

  void move(
    Offset delta,
  ) {
    x += delta.dx;
    y += delta.dy;
  }

  // ==========================================================
  // CONEXÕES
  // ==========================================================

  bool isConnectedTo(
    String nodeId,
  ) {
    return connections.contains(
      nodeId,
    );
  }

  void connectTo(
    String nodeId,
  ) {
    if (nodeId ==
        id) {
      return;
    }

    if (connections.contains(
      nodeId,
    )) {
      return;
    }

    connections.add(
      nodeId,
    );
  }

  void disconnectFrom(
    String nodeId,
  ) {
    connections.remove(
      nodeId,
    );
  }

  void clearConnections() {
    connections.clear();
  }

  // ==========================================================
  // COPY
  // ==========================================================

  MindMapNode copyWith({
    String? id,
    String? text,
    MindMapNodeType? type,
    double? x,
    double? y,
    List<
      String
    >?
    connections,
  }) {
    return MindMapNode(
      id:
          id ??
          this.id,
      text:
          text ??
          this.text,
      type:
          type ??
          this.type,
      x:
          x ??
          this.x,
      y:
          y ??
          this.y,
      connections:
          connections ??
          List<
            String
          >.from(
            this.connections,
          ),
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
      'text': text,
      'type': type.name,
      'x': x,
      'y': y,
      'connections': connections,
    };
  }

  factory MindMapNode.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    return MindMapNode(
      id:
          json['id']?.toString() ??
          '',
      text:
          json['text']?.toString() ??
          '',
      type: _typeFromString(
        json['type']?.toString(),
      ),
      x: _toDouble(
        json['x'],
      ),
      y: _toDouble(
        json['y'],
      ),
      connections:
          (json['connections']
                  as List?)
              ?.map(
                (
                  item,
                ) => item.toString(),
              )
              .toList() ??
          [],
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  static double _toDouble(
    dynamic value,
  ) {
    if (value
        is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ??
              '',
        ) ??
        0;
  }

  static MindMapNodeType _typeFromString(
    String? value,
  ) {
    for (final type in MindMapNodeType.values) {
      if (type.name ==
          value) {
        return type;
      }
    }

    return MindMapNodeType.idea;
  }
}
