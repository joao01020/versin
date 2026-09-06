typedef AsyncLoader<T> = Future<T> Function();

class RequestDeduplicator {
  RequestDeduplicator._();

  static final RequestDeduplicator instance = RequestDeduplicator._();

  final Map<String, Future<dynamic>> _inFlight = <String, Future<dynamic>>{};

  Future<T> run<T>(String key, AsyncLoader<T> loader) {
    final current = _inFlight[key];
    if (current != null) return current as Future<T>;

    final future = loader();
    _inFlight[key] = future;
    future.whenComplete(() {
      if (identical(_inFlight[key], future)) _inFlight.remove(key);
    });
    return future;
  }
}
