class DemixingException implements Exception {
  final String message;

  DemixingException(this.message);

  @override
  String toString() => 'DemixingException: $message';
}
