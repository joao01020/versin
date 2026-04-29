enum UserRole { artista, beatmaker }

class MatchCardModel {
  final String id;
  final String name;
  final UserRole role;
  final List<String> genres; // ex: ["Dark Trap", "Hardcore"]
  final int bpm;
  final String? fileUrl; // Caminho do .txt ou .mp3

  MatchCardModel({
    required this.id,
    required this.name,
    required this.role,
    required this.genres,
    required this.bpm,
    this.fileUrl,
  });
}
