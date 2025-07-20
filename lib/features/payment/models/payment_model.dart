// lib/features/payment/models/payment_model.dart

import 'package:flutter/material.dart';
import '../../auth/domain/entities/user_entity.dart';

class PaymentModel {
  final int id;
  final String tutar;
  final String aciklama;
  final String? monthComment;
  final int odeme_durum;
  final int odemeonayi;
  final int kullanici_id;
  final int ogretmen_id;
  final String created_at;
  final String updated_at;
  final UserEntity? kullanici;

  PaymentModel({
    required this.id,
    required this.tutar,
    required this.aciklama,
    this.monthComment,
    required this.odeme_durum,
    required this.odemeonayi,
    required this.kullanici_id,
    required this.ogretmen_id,
    required this.created_at,
    required this.updated_at,
    this.kullanici,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? 0,
      tutar: json['tutar']?.toString() ?? '0',
      aciklama: json['aciklama'] ?? '',
      monthComment: json['MonthComment'],
      odeme_durum: json['odeme_durum'] ?? 0,
      odemeonayi: json['odemeonayi'] ?? 0,
      kullanici_id: json['kullanici_id'] ?? 0,
      ogretmen_id: json['ogretmen_id'] ?? 0,
      created_at: json['created_at'] ?? '',
      updated_at: json['updated_at'] ?? '',
      kullanici: json['kullanici'] != null
          ? UserEntity.fromJson(json['kullanici'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tutar': tutar,
      'aciklama': aciklama,
      'MonthComment': monthComment,
      'odeme_durum': odeme_durum,
      'odemeonayi': odemeonayi,
      'kullanici_id': kullanici_id,
      'ogretmen_id': ogretmen_id,
      'created_at': created_at,
      'updated_at': updated_at,
      'kullanici': kullanici != null ? {
        'id': kullanici!.id,
        'adsoyad': kullanici!.name,
        'telefon': kullanici!.telefon,
        'email': kullanici!.email,
      } : null,
    };
  }

  // Durum kontrolü için helper methodlar - sadece odeme_durum'a bak
  bool get isApproved => odeme_durum == 1;
  bool get isPending => odeme_durum == 0;
  bool get isRejected => odeme_durum != 1 && odeme_durum != 0;

  // Durum text'i - sadece odeme_durum'a göre
  String get statusText {
    switch (odeme_durum) {
      case 1:
        return 'Onaylandı';
      case 0:
        return 'Bekliyor';
      default:
        return 'Reddedildi';
    }
  }

  // Durum rengi - sadece odeme_durum'a göre
  Color get statusColor {
    switch (odeme_durum) {
      case 1:
        return Colors.green;
      case 0:
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  // Para formatı
  String get formattedAmount {
    double value = double.tryParse(tutar) ?? 0;
    return '₺${value.toStringAsFixed(0)}';
  }

  // Kullanıcı adı (UserEntity'den)
  String get kullaniciAdi => kullanici?.name ?? 'İsimsiz';

  // Kullanıcı telefonu (UserEntity'den)
  String? get kullaniciTelefon => kullanici?.telefon;

  // Kullanıcı email (UserEntity'den)
  String get kullaniciEmail => kullanici?.email ?? '';
}

// Özet bilgileri için model
class PaymentSummaryModel {
  final double toplam_odeme;
  final double bekleyen_odeme;
  final PaymentModel? son_odeme;
  final int? paket_durum;
  final String? sonraki_odeme_tarihi;

  // Öğretmen için ek alanlar
  final int? toplam_ogrenci;
  final int? aktif_ogrenci;

  PaymentSummaryModel({
    required this.toplam_odeme,
    required this.bekleyen_odeme,
    this.son_odeme,
    this.paket_durum,
    this.sonraki_odeme_tarihi,
    this.toplam_ogrenci,
    this.aktif_ogrenci,
  });

  factory PaymentSummaryModel.fromJson(Map<String, dynamic> json) {
    return PaymentSummaryModel(
      toplam_odeme: double.tryParse(json['toplam_odeme']?.toString() ?? '0') ?? 0,
      bekleyen_odeme: double.tryParse(json['bekleyen_odeme']?.toString() ?? '0') ?? 0,
      son_odeme: json['son_odeme'] != null
          ? PaymentModel.fromJson(json['son_odeme'])
          : null,
      paket_durum: json['paket_durum'],
      sonraki_odeme_tarihi: json['sonraki_odeme_tarihi'],
      toplam_ogrenci: json['toplam_ogrenci'],
      aktif_ogrenci: json['aktif_ogrenci'],
    );
  }

  // Toplam ödeme formatı
  String get formattedToplamOdeme => '₺${toplam_odeme.toStringAsFixed(0)}';

  // Bekleyen ödeme formatı
  String get formattedBekleyenOdeme => '₺${bekleyen_odeme.toStringAsFixed(0)}';
}

// API Response wrapper
class PaymentResponse {
  final bool success;
  final String message;
  final dynamic data;
  final Map<String, dynamic>? errors;

  PaymentResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
      errors: json['errors'],
    );
  }
}

// Pagination için model
class PaymentListResponse {
  final List<PaymentModel> payments;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  PaymentListResponse({
    required this.payments,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  factory PaymentListResponse.fromJson(Map<String, dynamic> json) {
    var paymentsData = json['data'] as List? ?? [];
    List<PaymentModel> payments = paymentsData
        .map((payment) => PaymentModel.fromJson(payment))
        .toList();

    return PaymentListResponse(
      payments: payments,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      total: json['total'] ?? 0,
      perPage: json['per_page'] ?? 20,
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}