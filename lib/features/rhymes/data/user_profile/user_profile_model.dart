class UserProfileModel {
  final String id;
  final String username;
  final String walletAddress;
  final String iaMemory;
  final Map<String, dynamic> settings;

  UserProfileModel({
    required this.id,
    required this.username,
    required this.walletAddress,
    this.iaMemory = '',
    this.settings = const {},
  });

  // Gera o objeto a partir do username (Wallet automática)
  factory UserProfileModel.create(String name) {
    return UserProfileModel(
      id: '', // Gerado pelo banco
      username: name,
      walletAddress: "wallet@$name",
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'username': username,
      'wallet_address': walletAddress,
      'ia_memory': iaMemory,
      'settings': settings,
    };
  }
}
