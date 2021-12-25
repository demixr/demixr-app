class Failure {
  final String message;

  Failure({required this.message});

  @override
  String toString() => 'Failure(message: $message)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Failure && o.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
