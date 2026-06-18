class Model {
  final String name;
  final String description;
  final String url;
  final bool isDefault;

  /// File extension used for the locally-downloaded model file.
  final String fileExtension;

  /// Ordered stem names this model produces. The order must match the rows of
  /// the model's output tensor. Defaults to the standard 4.
  final List<String> stems;

  const Model({
    required this.name,
    required this.description,
    required this.url,
    this.isDefault = false,
    this.fileExtension = '.onnx',
    this.stems = const ['vocals', 'drums', 'bass', 'other'],
  });
}
