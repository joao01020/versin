class CachePolicy {
  final Duration freshFor;
  final Duration staleFor;

  const CachePolicy({required this.freshFor, required this.staleFor});

  static const professionalProfile = CachePolicy(
    freshFor: Duration(minutes: 30),
    staleFor: Duration(days: 2),
  );

  static const vocabulary = CachePolicy(
    freshFor: Duration(minutes: 10),
    staleFor: Duration(days: 7),
  );

  static const storageWorks = CachePolicy(
    freshFor: Duration(minutes: 5),
    staleFor: Duration(days: 3),
  );

  static const matchSearch = CachePolicy(
    freshFor: Duration(seconds: 20),
    staleFor: Duration(minutes: 2),
  );
}
