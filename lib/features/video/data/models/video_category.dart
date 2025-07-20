// ========== CATEGORY MODEL ==========
class VideoCategory {
  final int id;
  final String name;
  final int cins;
  final int userId;

  VideoCategory({
    required this.id,
    required this.name,
    required this.cins,
    required this.userId,
  });

  factory VideoCategory.fromJson(Map<String, dynamic> json) {
    return VideoCategory(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      cins: _parseInt(json['cins']) ?? 0,
      userId: _parseInt(json['user_id']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cins': cins,
      'user_id': userId,
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