class Model {
  final String name;
  final String description;
  final String url;
  final bool isDefault;

  const Model({
    required this.name,
    required this.description,
    required this.url,
    this.isDefault = false,
  });
}
