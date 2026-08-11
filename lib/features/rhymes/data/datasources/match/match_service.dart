import 'package:flutter/foundation.dart';

import '../../models/match_card_model.dart';

class MatchService {
  double calculateMatchScore(
    MatchCardModel user,
    MatchCardModel target,
  ) {
    if (user.role ==
        target.role) {
      return 0.0;
    }

    double score = 0.0;

    if (user.genres.isNotEmpty) {
      final commonGenres = user.genres
          .where(
            (
              genre,
            ) => target.genres.contains(
              genre,
            ),
          )
          .length;

      score +=
          (commonGenres /
              user.genres.length) *
          0.5;
    }

    if ((user.bpm -
                target.bpm)
            .abs() <=
        5) {
      score += 0.5;
    }

    return score;
  }

  Future<
    void
  >
  uploadFile(
    dynamic file,
    UserRole role,
  ) async {
    final fileType =
        role ==
            UserRole.artista
        ? 'letra .txt'
        : 'beat .mp3';

    debugPrint(
      'Enviando $fileType',
    );
  }
}
