// ========== TEACHER MODEL ==========
class Teacher {
  final int id;
  final String name;
  final String slug;

  Teacher({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }

  // Helper method for parsing int
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
