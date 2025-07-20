// ========== VIDEO MODEL ==========
class Video {
  final int id;
  final String? baslik;
  final String? aciklama;
  final int kategori;
  final int userId;
  final String? createdAt;

  Video({
    required this.id,
    this.baslik,
    this.aciklama,
    required this.kategori,
    required this.userId,
    this.createdAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: _parseInt(json['id']) ?? 0,
      baslik: json['baslik']?.toString(),
      aciklama: json['aciklama']?.toString(),
      kategori: _parseInt(json['kategori']) ?? 0,
      userId: _parseInt(json['user_id']) ?? 0,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'baslik': baslik,
      'aciklama': aciklama,
      'kategori': kategori,
      'user_id': userId,
      'created_at': createdAt,
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
