class Album {
  final String id;
  final String name;
  final int count;

  const Album({required this.id, required this.name, required this.count});

  @override
  bool operator ==(Object other) => other is Album && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
