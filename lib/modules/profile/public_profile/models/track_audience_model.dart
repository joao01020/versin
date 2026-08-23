// ============================================================
// TRACK AUDIENCE MODEL
// ============================================================
//
// Representa quais grupos profissionais podem ouvir uma demo.
//
// Exemplo:
//
// [
//   artist,
//   beatmaker,
// ]
//
// A lógica de segurança definitiva também deve existir no
// Supabase/RLS. Este model representa apenas o estado no app.
//
// ============================================================

class TrackAudienceModel {
  // ============================================================
  // ROLES
  // ============================================================

  final List<String> roles;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const TrackAudienceModel({this.roles = const <String>[]});

  // ============================================================
  // EMPTY
  // ============================================================

  const TrackAudienceModel.empty() : roles = const <String>[];

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isEmpty => roles.isEmpty;

  bool get isNotEmpty => roles.isNotEmpty;

  int get count => roles.length;

  // ============================================================
  // CONTÉM ROLE
  // ============================================================

  bool contains(String role) {
    final normalizedRole = _normalizeRole(role);

    if (normalizedRole.isEmpty) {
      return false;
    }

    return roles.contains(normalizedRole);
  }

  // ============================================================
  // PODE OUVIR
  // ============================================================

  bool canListen(Iterable<String> userRoles) {
    if (roles.isEmpty) {
      return false;
    }

    for (final role in userRoles) {
      if (contains(role)) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // TOGGLE
  // ============================================================

  TrackAudienceModel toggle(String role) {
    final normalizedRole = _normalizeRole(role);

    if (normalizedRole.isEmpty) {
      return this;
    }

    final updated = <String>[...roles];

    if (updated.contains(normalizedRole)) {
      updated.remove(normalizedRole);
    } else {
      updated.add(normalizedRole);
    }

    return TrackAudienceModel(roles: _normalizeRoles(updated));
  }

  // ============================================================
  // ADD
  // ============================================================

  TrackAudienceModel add(String role) {
    final normalizedRole = _normalizeRole(role);

    if (normalizedRole.isEmpty || roles.contains(normalizedRole)) {
      return this;
    }

    return TrackAudienceModel(
      roles: _normalizeRoles([...roles, normalizedRole]),
    );
  }

  // ============================================================
  // REMOVE
  // ============================================================

  TrackAudienceModel remove(String role) {
    final normalizedRole = _normalizeRole(role);

    return TrackAudienceModel(
      roles: roles
          .where((currentRole) {
            return currentRole != normalizedRole;
          })
          .toList(growable: false),
    );
  }

  // ============================================================
  // CLEAR
  // ============================================================

  TrackAudienceModel clear() {
    return const TrackAudienceModel.empty();
  }

  // ============================================================
  // FROM DYNAMIC
  // ============================================================

  factory TrackAudienceModel.fromDynamic(dynamic value) {
    if (value == null) {
      return const TrackAudienceModel.empty();
    }

    if (value is List) {
      return TrackAudienceModel(
        roles: _normalizeRoles(
          value.map((item) {
            return item.toString();
          }),
        ),
      );
    }

    return const TrackAudienceModel.empty();
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory TrackAudienceModel.fromMap(Map<String, dynamic> map) {
    return TrackAudienceModel.fromDynamic(map['audience_roles']);
  }

  // ============================================================
  // TO LIST
  // ============================================================

  List<String> toList() {
    return List<String>.unmodifiable(roles);
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  TrackAudienceModel copyWith({List<String>? roles}) {
    return TrackAudienceModel(
      roles: roles == null ? this.roles : _normalizeRoles(roles),
    );
  }

  // ============================================================
  // NORMALIZE ROLE
  // ============================================================

  static String _normalizeRole(String value) {
    return value.trim().toLowerCase().replaceAll(' ', '_');
  }

  // ============================================================
  // NORMALIZE ROLES
  // ============================================================

  static List<String> _normalizeRoles(Iterable<String> values) {
    final normalized = values
        .map(_normalizeRole)
        .where((role) {
          return role.isNotEmpty;
        })
        .toSet()
        .toList();

    normalized.sort();

    return List<String>.unmodifiable(normalized);
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'TrackAudienceModel('
        'roles: $roles'
        ')';
  }
}
