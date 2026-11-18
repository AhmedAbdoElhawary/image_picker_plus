/// a gallery album.
class Album {
  /// the gallery's own id.
  final String id;

  /// shown in the album picker.
  final String name;

  /// an album as the gallery reports it.
  const Album({required this.id, required this.name});

  @override
  bool operator ==(Object other) => other is Album && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
