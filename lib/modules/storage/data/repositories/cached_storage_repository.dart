import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:versin/core/cache/app_cache_service.dart';
import 'package:versin/core/cache/cache_keys.dart';
import 'package:versin/core/cache/cache_policy.dart';
import 'package:versin/core/cache/request_deduplicator.dart';

import '../models/stored_work_model.dart';
import 'storage_repository.dart';

class CachedStorageRepository implements StorageRepository {
  final StorageRepository _remote;
  final AppCacheService _cache;
  final RequestDeduplicator _deduplicator;

  CachedStorageRepository({
    required StorageRepository remote,
    AppCacheService? cache,
    RequestDeduplicator? deduplicator,
  }) : _remote = remote,
       _cache = cache ?? AppCacheService.instance,
       _deduplicator = deduplicator ?? RequestDeduplicator.instance;

  String? get _currentUserId {
    final value = Supabase.instance.client.auth.currentUser?.id.trim();
    return value == null || value.isEmpty ? null : value;
  }

  @override
  Future<List<StoredWorkModel>> getWorks({required String userId}) async {
    final id = userId.trim();
    final key = CacheKeys.storageWorks(id);
    final cached = await _cache.read(key, policy: CachePolicy.storageWorks);
    if (cached != null) {
      final works = _decode(cached.value);
      if (cached.isFresh) return works;
      unawaited(_refresh(id));
      return works;
    }
    return _refresh(id);
  }

  Future<List<StoredWorkModel>> _refresh(String userId) {
    final key = CacheKeys.storageWorks(userId);
    return _deduplicator.run<List<StoredWorkModel>>('remote:$key', () async {
      try {
        final works = await _remote.getWorks(userId: userId);
        await _cache.write(key, works.map((e) => e.toMap()).toList());
        return works;
      } catch (_) {
        final stale = await _cache.read(
          key,
          policy: CachePolicy.storageWorks,
          allowStale: true,
        );
        if (stale != null) return _decode(stale.value);
        rethrow;
      }
    });
  }

  @override
  Future<StoredWorkModel?> getWorkById({required String workId}) async {
    final userId = _currentUserId;
    if (userId != null) {
      final cached = await _cache.read(
        CacheKeys.storageWorks(userId),
        policy: CachePolicy.storageWorks,
      );
      if (cached != null) {
        for (final work in _decode(cached.value)) {
          if (work.id == workId.trim()) return work;
        }
        if (cached.isFresh) return null;
      }
    }
    return _deduplicator.run<StoredWorkModel?>(
      'storage:id:${workId.trim()}',
      () => _remote.getWorkById(workId: workId),
    );
  }

  @override
  Future<StoredWorkModel?> getWorkByHash({required String contentHash}) async {
    final userId = _currentUserId;
    final hash = contentHash.trim().toLowerCase();
    if (userId != null) {
      final cached = await _cache.read(
        CacheKeys.storageWorks(userId),
        policy: CachePolicy.storageWorks,
      );
      if (cached != null) {
        for (final work in _decode(cached.value)) {
          if (work.contentHash.trim().toLowerCase() == hash) return work;
        }
        if (cached.isFresh) return null;
      }
    }
    return _deduplicator.run<StoredWorkModel?>(
      'storage:hash:$hash',
      () => _remote.getWorkByHash(contentHash: contentHash),
    );
  }

  @override
  Future<List<StoredWorkModel>> getLyrics({required String userId}) async =>
      (await getWorks(
        userId: userId,
      )).where((e) => e.type == StoredWorkType.lyrics).toList(growable: false);

  @override
  Future<List<StoredWorkModel>> getBeats({required String userId}) async =>
      (await getWorks(
        userId: userId,
      )).where((e) => e.type == StoredWorkType.beat).toList(growable: false);

  @override
  Future<StoredWorkModel> saveWork(StoredWorkModel work) async {
    final saved = await _remote.saveWork(work);
    await _upsert(saved);
    return saved;
  }

  @override
  Future<StoredWorkModel> updateWork(StoredWorkModel work) async {
    final updated = await _remote.updateWork(work);
    await _upsert(updated);
    return updated;
  }

  @override
  Future<void> deleteWork({required String workId}) async {
    await _remote.deleteWork(workId: workId);
    final userId = _currentUserId;
    if (userId == null) return;
    final key = CacheKeys.storageWorks(userId);
    final cached = await _cache.read(key, policy: CachePolicy.storageWorks);
    if (cached == null) return;
    final works = _decode(
      cached.value,
    ).where((e) => e.id != workId.trim()).toList();
    await _cache.write(key, works.map((e) => e.toMap()).toList());
  }

  @override
  Future<StoredWorkModel> transferWork({
    required String workId,
    required String toUserId,
    String? note,
  }) async {
    final transferred = await _remote.transferWork(
      workId: workId,
      toUserId: toUserId,
      note: note,
    );
    final userId = _currentUserId;
    if (userId != null) {
      final key = CacheKeys.storageWorks(userId);
      final cached = await _cache.read(key, policy: CachePolicy.storageWorks);
      if (cached != null) {
        final works = _decode(
          cached.value,
        ).where((e) => e.id != workId.trim()).toList();
        await _cache.write(key, works.map((e) => e.toMap()).toList());
      }
    }
    return transferred;
  }

  @override
  Future<bool> hashExists({required String contentHash}) async =>
      (await getWorkByHash(contentHash: contentHash)) != null;

  @override
  Future<int> countWorks({required String userId}) async =>
      (await getWorks(userId: userId)).length;

  @override
  Future<int> countLyrics({required String userId}) async =>
      (await getLyrics(userId: userId)).length;

  @override
  Future<int> countBeats({required String userId}) async =>
      (await getBeats(userId: userId)).length;

  @override
  Future<int> countVerifiedWorks({required String userId}) async =>
      (await getWorks(userId: userId)).where((e) => e.integrityVerified).length;

  Future<void> _upsert(StoredWorkModel work) async {
    final userId = _currentUserId;
    if (userId == null || work.ownerUserId != userId) return;
    final key = CacheKeys.storageWorks(userId);
    final cached = await _cache.read(key, policy: CachePolicy.storageWorks);
    final works = cached == null ? <StoredWorkModel>[] : _decode(cached.value);
    final index = works.indexWhere((e) => e.id == work.id);
    if (index >= 0) {
      works[index] = work;
    } else {
      works.insert(0, work);
    }
    works.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _cache.write(key, works.map((e) => e.toMap()).toList());
  }

  List<StoredWorkModel> _decode(dynamic raw) {
    if (raw is! List) return <StoredWorkModel>[];
    final result = <StoredWorkModel>[];
    for (final item in raw) {
      if (item is! Map) continue;
      try {
        result.add(StoredWorkModel.fromMap(Map<String, dynamic>.from(item)));
      } catch (_) {}
    }
    return result;
  }
}
