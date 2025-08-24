class Book {
  final int id;
  final String name;
  final String odiyaName;
  final String abbreviation;
  final int testament; // 1 for Old Testament, 2 for New Testament
  final int totalChapters;
  final int order;

  Book({
    required this.id,
    required this.name,
    required this.odiyaName,
    required this.abbreviation,
    required this.testament,
    required this.totalChapters,
    required this.order,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      name: json['name'],
      odiyaName: json['odiya_name'],
      abbreviation: json['abbreviation'],
      testament: json['testament'] is String 
          ? (json['testament'] == 'Old' ? 1 : 2)
          : json['testament'],
      totalChapters: json['total_chapters'],
      order: json['order_index'] ?? json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'odiya_name': odiyaName,
      'abbreviation': abbreviation,
      'testament': testament,
      'total_chapters': totalChapters,
      'order': order,
    };
  }

  @override
  String toString() {
    return 'Book{id: $id, name: $name, odiyaName: $odiyaName}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}