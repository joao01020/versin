/// [HardwareStatusModel] represents the strongly-typed structural state of your physical hardware.
class HardwareStatusModel {
  final int id;
  final String status;
  final String machineName;
  final bool isOnline;

  HardwareStatusModel({
    required this.id,
    required this.status,
    required this.machineName,
    required this.isOnline,
  });

  /// Factory constructor to securely parse raw database maps into a strong Dart object.
  factory HardwareStatusModel.fromMap(Map<String, dynamic> map) {
    return HardwareStatusModel(
      id: map['id'] as int? ?? 0,
      status: map['status'] as String? ?? 'Desconhecido',
      machineName: map['machine_name'] as String? ?? 'VNode-Hub',
      isOnline: map['is_online'] as bool? ?? false,
    );
  }

  /// Converts the model back into a raw map schema format for database writes or syncing.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': status,
      'machine_name': machineName,
      'is_online': isOnline,
    };
  }
}