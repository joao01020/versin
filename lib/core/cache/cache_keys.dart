class CacheKeys {
  const CacheKeys._();

  static String vocabulary(String userId) => 'vocabulary:$userId';
  static String professionalProfile(String userId) =>
      'professional_profile:$userId';
  static String storageWorks(String userId) => 'storage_works:$userId';
  static String matchSearch({required String userId, required String query}) =>
      'match_search:$userId:${query.trim().toLowerCase()}';
}
