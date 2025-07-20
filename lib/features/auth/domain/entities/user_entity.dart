// lib/features/auth/domain/entities/user_entity.dart
class UserEntity {
  final int id;
  final String name;
  final String email;
  final String? telefon;
  final String? address;
  final int? roleId;
  final int yoneticiMi;
  final int aktifMi;
  final int? smsVerify;
  final int? paketDurum;
  final int? isFree;
  final int? ogretmenId;
  final String? ogretmenAdi;
  final String? sonrakiOdemeTarihi;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String userType;
  final bool isActive;
  final int? daysRemaining;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.telefon,
    this.address,
    this.roleId,
    required this.yoneticiMi,
    required this.aktifMi,
    this.smsVerify,
    this.paketDurum,
    this.isFree,
    this.ogretmenId,
    this.ogretmenAdi,
    this.sonrakiOdemeTarihi,
    this.createdAt,
    this.updatedAt,
    required this.userType,
    required this.isActive,
    this.daysRemaining,
  });

  // JSON'dan UserEntity oluştur
  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: _parseToInt(json['id']) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      telefon: json['telefon'],
      address: json['address'],
      roleId: _parseToInt(json['role_id']),
      yoneticiMi: _parseToInt(json['yonetici_mi']) ?? 0,
      aktifMi: _parseToInt(json['aktif_mi']) ?? 0,
      smsVerify: _parseToInt(json['sms_verify']),
      paketDurum: _parseToInt(json['paket_durum']),
      isFree: _parseToInt(json['is_free']),
      ogretmenId: _parseToInt(json['ogretmen_id']),
      ogretmenAdi: json['ogretmen_adi'],
      sonrakiOdemeTarihi: json['sonraki_odeme_tarihi'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      userType: json['user_type'] ?? 'student',
      isActive: json['is_active'] ?? false,
      daysRemaining: _parseToInt(json['days_remaining']),
    );
  }

  // String'i int'e çeviren helper method
  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  // Kullanıcı admin mi?
  bool get isAdmin => yoneticiMi == 1;

  // Kullanıcı öğrenci mi?
  bool get isStudent => yoneticiMi == 0;

  // Paket aktif mi?
  bool get hasActivePackage => paketDurum == 1;

  // SMS doğrulanmış mı?
  bool get isSmsVerified => smsVerify == 1;

  // Öğretmen adından slug oluştur
  String? get ogretmenSlug {
    if (ogretmenAdi == null || ogretmenAdi!.isEmpty) {
      return null;
    }

    return ogretmenAdi!
        .toLowerCase()
        .trim()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll('İ', 'i')
        .replaceAll('Ç', 'c')
        .replaceAll('Ğ', 'g')
        .replaceAll('Ö', 'o')
        .replaceAll('Ş', 's')
        .replaceAll('Ü', 'u')
        .replaceAll(RegExp(r'\s+'), '-')  // Boşlukları tire ile değiştir
        .replaceAll(RegExp(r'[^a-z0-9-]'), '')  // Sadece harf, rakam ve tire
        .replaceAll(RegExp(r'-+'), '-')  // Birden fazla tireyi tek tire
        .replaceAll(RegExp(r'^-|-$'), '');  // Başındaki ve sonundaki tireleri kaldır
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity &&
        other.id == id &&
        other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode;
  }

  @override
  String toString() {
    return 'UserEntity(id: $id, name: $name, email: $email, userType: $userType, isActive: $isActive, ogretmenAdi: $ogretmenAdi, ogretmenSlug: $ogretmenSlug)';
  }
}