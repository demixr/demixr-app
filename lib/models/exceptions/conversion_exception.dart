class ConversionException implements Exception {
  final String message;

  ConversionException(this.message);

  @override
  String toString() => 'ConversionException: $message';
}
