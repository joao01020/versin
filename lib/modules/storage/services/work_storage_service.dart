import 'dart:typed_data';

import '../data/models/stored_work_model.dart';
import '../data/repositories/storage_repository.dart';
import 'beat_storage_service.dart';

class WorkStorageService {
  final StorageRepository repository;
  final BeatStorageService beatStorageService;

  WorkStorageService({
    required this.repository,
    required this.beatStorageService,
  });

  Future<
    StoredWorkModel
  >
  saveLyrics({
    required StoredWorkModel work,
  }) async {
    if (work.type !=
        StoredWorkType.lyrics) {
      throw ArgumentError(
        'A obra informada não é uma letra.',
      );
    }

    final lyrics = work.lyricsContent?.trim();
    if (lyrics ==
            null ||
        lyrics.isEmpty) {
      throw ArgumentError(
        'A letra não possui conteúdo.',
      );
    }

    return repository.saveWork(
      work,
    );
  }

  Future<
    StoredWorkModel
  >
  saveBeat({
    required StoredWorkModel work,
    required Uint8List bytes,
  }) async {
    if (work.type !=
        StoredWorkType.beat) {
      throw ArgumentError(
        'A obra informada não é um beat.',
      );
    }

    final fileName = work.fileName?.trim();
    if (fileName ==
            null ||
        fileName.isEmpty) {
      throw ArgumentError(
        'O beat precisa possuir fileName.',
      );
    }

    BeatUploadResult? upload;

    try {
      upload = await beatStorageService.uploadBeat(
        workId: work.id,
        userId: work.ownerUserId,
        fileName: fileName,
        bytes: bytes,
        contentType: work.mimeType,
      );

      final storedWork = work.copyWith(
        filePath: upload.objectKey,
        fileName: upload.fileName,
        mimeType: upload.contentType,
        fileSizeBytes: upload.fileSizeBytes,
        updatedAt: DateTime.now().toUtc(),
      );

      return await repository.saveWork(
        storedWork,
      );
    } catch (
      _
    ) {
      if (upload !=
          null) {
        try {
          await beatStorageService.deleteBeat(
            workId: work.id,
          );
        } catch (
          _
        ) {}
      }
      rethrow;
    }
  }

  Future<
    StoredWorkModel
  >
  updateWork(
    StoredWorkModel work,
  ) {
    return repository.updateWork(
      work.copyWith(
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<
    void
  >
  deleteWork(
    StoredWorkModel work,
  ) async {
    await repository.deleteWork(
      workId: work.id,
    );

    if (work.type ==
            StoredWorkType.beat &&
        work.hasFile) {
      try {
        await beatStorageService.deleteBeat(
          workId: work.id,
        );
      } catch (
        _
      ) {}
    }
  }

  Future<
    String
  >
  createBeatPlaybackUrl({
    required StoredWorkModel work,
  }) {
    if (work.type !=
        StoredWorkType.beat) {
      throw ArgumentError(
        'A obra informada não é um beat.',
      );
    }

    return beatStorageService.createPlaybackUrl(
      workId: work.id,
    );
  }

  Future<
    StoredWorkModel
  >
  transferWork({
    required String workId,
    required String toUserId,
    String? note,
  }) {
    return repository.transferWork(
      workId: workId,
      toUserId: toUserId,
      note: note,
    );
  }
}
