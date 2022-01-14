class ConvertionException implements Exception {
  final String message;

  ConvertionException(this.message);

  @override
  String toString() => 'ConvertionException: $message';
}
