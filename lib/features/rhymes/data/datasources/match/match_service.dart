import '../../models/match_card_model.dart';

class MatchService {
  // Algoritmo que calcula a afinidade entre dois perfis
  double calculateMatchScore(MatchCardModel user, MatchCardModel target) {
    if (user.role == target.role)
      return 0.0; // Artista busca Beatmaker e vice-versa

    double score = 0.0;

    // Afinidade por Gênero (50%)
    final commonGenres = user.genres
        .where((g) => target.genres.contains(g))
        .length;
    score += (commonGenres / user.genres.length) * 0.5;

    // Afinidade por BPM (50%) - Margem de erro de 5 BPM
    if ((user.bpm - target.bpm).abs() <= 5) {
      score += 0.5;
    }

    return score;
  }

  // Simulação de upload (Integra com o seu SupabaseStorageService depois)
  Future<void> uploadFile(dynamic file, UserRole role) async {
    // Lógica de FilePicker e Supabase aqui
    print("Enviando ${role == UserRole.artista ? 'letra .txt' : 'beat .mp3'}");
  }
}
