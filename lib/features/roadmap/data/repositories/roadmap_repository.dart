import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/roadmap_category.dart';
import '../models/roadmap_step.dart';

/// RoadmapRepository - API işlemlerini yöneten sınıf
///
/// Bu sınıf tüm roadmap ile ilgili backend işlemlerini yapar:
/// - Kategorileri getir
/// - Adımları tamamla
/// - İlerleme takibi
/// - Todo listesi yönetimi
class RoadmapRepository {
  // SharedPreferences'ta token'ın key'i
  static const String _tokenKey = 'auth_token';

  /// Token'ı SharedPreferences'tan al
  ///
  /// Returns: Kullanıcının auth token'ı veya null
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// HTTP header'larını oluştur
  ///
  /// [token] - Bearer token
  /// Returns: API için gerekli header'lar
  Map<String, String> _getHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Tüm roadmap kategorilerini getir
  ///
  /// Bu method:
  /// 1. Token'ı al
  /// 2. API'ye GET request at
  /// 3. Response'u parse et
  /// 4. RoadmapCategory listesi döndür
  ///
  /// Throws: Exception - Token yoksa, API hatası varsa
  Future<List<RoadmapCategory>> getRoadmapCategories() async {
    try {
      // MOCK DATA İÇİN:
      await Future.delayed(Duration(milliseconds: 1500));



      // 1. Token kontrolü
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı - Tekrar giriş yapın');
      }

      // Debug: URL'yi logla
      final url = '${ApiConstants.baseUrl}/roadmap';
      debugPrint('API Call: GET $url');

      // 2. API çağrısı
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token),
      );

      // Debug: Response'u logla
      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      // 3. Response kontrolü
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // 4. JSON'dan model'e dönüştür
          return (data['data'] as List)
              .map((item) => RoadmapCategory.fromJson(item))
              .toList();
        } else {
          throw Exception('API Hatası: ${data['message'] ?? 'Bilinmeyen hata'}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Oturum süresi dolmuş - Tekrar giriş yapın');
      } else if (response.statusCode == 404) {
        throw Exception('API endpoint bulunamadı - Backend\'e roadmap API\'si eklenmeli');
      } else if (response.statusCode == 500) {
        throw Exception('Sunucu hatası - Backend loglarını kontrol edin');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

    } catch (e) {
      // Hata yakalama ve yeniden fırlatma
      if (e is Exception) {
        rethrow; // Kendi exception'ımızı koru
      } else {
        throw Exception('Beklenmeyen hata: $e');
      }
    }
  }

  /// Mock data - API hazır olmadığı için test amaçlı
  List<RoadmapCategory> _getMockData() {
    return [
      RoadmapCategory(
        id: 1,
        title: "Reading Skills",
        description: "Okuma becerilerini geliştir",
        steps: [
          RoadmapStep(
            id: 1,
            title: "Temel Kelime Bilgisi",
            description: "Günlük 50 kelime öğren",
            categoryId: 1,
            levelId: 1,
            order: 1,
            isCompleted: true,
            completedAt: DateTime.now().subtract(Duration(days: 2)),
          ),
          RoadmapStep(
            id: 2,
            title: "Hızlı Okuma Teknikleri",
            description: "Okuma hızını artır",
            categoryId: 1,
            levelId: 1,
            order: 2,
            isCompleted: false,
          ),
          RoadmapStep(
            id: 3,
            title: "Anlam Çıkarma",
            description: "Metinden anlam çıkarma pratiği",
            categoryId: 1,
            levelId: 1,
            order: 3,
            isCompleted: false,
          ),
        ],
      ),
      RoadmapCategory(
        id: 2,
        title: "Writing Skills",
        description: "Yazma becerilerini geliştir",
        steps: [
          RoadmapStep(
            id: 4,
            title: "Temel Gramer",
            description: "Temel gramer kuralları",
            categoryId: 2,
            levelId: 1,
            order: 1,
            isCompleted: true,
            completedAt: DateTime.now().subtract(Duration(days: 1)),
          ),
          RoadmapStep(
            id: 5,
            title: "Paragraf Yazma",
            description: "Düzenli paragraf yazma",
            categoryId: 2,
            levelId: 1,
            order: 2,
            isCompleted: false,
          ),
        ],
      ),
      RoadmapCategory(
        id: 3,
        title: "Speaking Practice",
        description: "Konuşma pratiği yap",
        steps: [
          RoadmapStep(
            id: 6,
            title: "Telaffuz Egzersizleri",
            description: "Doğru telaffuz pratiği",
            categoryId: 3,
            levelId: 1,
            order: 1,
            isCompleted: false,
          ),
          RoadmapStep(
            id: 7,
            title: "Günlük Konuşma",
            description: "Günlük konuşma pratiği",
            categoryId: 3,
            levelId: 1,
            order: 2,
            isCompleted: false,
          ),
        ],
      ),
    ];
  }

  /// Belirli bir kategorinin detaylarını getir
  ///
  /// [categoryId] - Kategori ID'si
  /// Returns: RoadmapCategory - Detaylı kategori bilgisi
  Future<RoadmapCategory> getCategoryDetails(int categoryId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/student/roadmap/category/$categoryId'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return RoadmapCategory.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Kategori bulunamadı');
        }
      } else {
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kategori detay hatası: $e');
    }
  }

  /// Bir adımı tamamlanmış olarak işaretle
  ///
  /// [stepId] - Adım ID'si
  /// [categoryId] - Kategori ID'si
  /// [comment] - Opsiyonel yorum
  ///
  /// Returns: bool - İşlem başarılı mı?
  ///
  /// Backend'e şu veri gönderilir:
  /// {
  ///   "step_id": 123,
  ///   "category_id": 45,
  ///   "comment": "Tamamladım!",
  ///   "status": 1
  /// }
  Future<bool> completeStep(int stepId, int categoryId, {String? comment}) async {
    try {
      // MOCK DATA - UI testi için
      await Future.delayed(Duration(milliseconds: 800));
      debugPrint('MOCK: Step $stepId tamamlandı. Yorum: ${comment ?? "yok"}');
      return true; // Her zaman başarılı

      /* GERÇEK API İÇİN:
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final requestBody = <String, dynamic>{
        'step_id': stepId,
        'category_id': categoryId,
        'status': 1, // 1 = Tamamlandı
      };

      if (comment != null && comment.isNotEmpty) {
        requestBody['comment'] = comment;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/roadmap/complete-step'),
        headers: _getHeaders(token),
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Tamamlama hatası: ${response.statusCode}');
      }
      */
    } catch (e) {
      throw Exception('Adım tamamlama hatası: $e');
    }
  }

  /// Adımı todo listesine ekle (başlatılmış ama tamamlanmamış)
  ///
  /// [stepId] - Adım ID'si
  /// [categoryId] - Kategori ID'si
  /// [comment] - Opsiyonel yorum
  ///
  /// Backend'e status: 0 gönderilir (başlatıldı ama tamamlanmadı)
  Future<bool> addStepToTodo(int stepId, int categoryId, {String? comment}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final requestBody = <String, dynamic>{
        'step_id': stepId,
        'category_id': categoryId,
        'status': 0, // 0 = Başlatıldı ama tamamlanmadı
      };

      if (comment != null && comment.isNotEmpty) {
        requestBody['comment'] = comment;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/student/roadmap/add-todo'),
        headers: _getHeaders(token),
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Todo ekleme hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Todo ekleme hatası: $e');
    }
  }

  /// Kullanıcının genel ilerleme özetini getir
  ///
  /// Returns: Map - İlerleme bilgileri
  /// {
  ///   "total_categories": 5,
  ///   "completed_categories": 2,
  ///   "total_steps": 50,
  ///   "completed_steps": 25,
  ///   "progress_percentage": 50.0
  /// }
  Future<Map<String, dynamic>> getProgressSummary() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/student/roadmap/progress'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        } else {
          throw Exception(data['message'] ?? 'İlerleme bilgisi alınamadı');
        }
      } else {
        throw Exception('İlerleme hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('İlerleme bilgisi hatası: $e');
    }
  }

  /// Belirli bir adımın detaylarını getir
  ///
  /// [stepId] - Adım ID'si
  /// Returns: RoadmapStep - Adım detayları
  Future<RoadmapStep> getStepDetails(int stepId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/student/roadmap/step/$stepId'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return RoadmapStep.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Adım bulunamadı');
        }
      } else {
        throw Exception('Adım detay hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Adım detay hatası: $e');
    }
  }

  /// Local ve server verilerini senkronize et
  ///
  /// Bu method offline yapılan değişiklikleri server'a gönderir
  /// Returns: bool - Senkronizasyon başarılı mı?
  Future<bool> syncProgress() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/student/roadmap/sync'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Sync hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Senkronizasyon hatası: $e');
    }
  }

  /// Adımı todo listesinden kaldır
  ///
  /// [stepId] - Kaldırılacak adım ID'si
  /// Returns: bool - İşlem başarılı mı?
  Future<bool> removeStepFromTodo(int stepId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/student/roadmap/todo/$stepId'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Silme hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Todo silme hatası: $e');
    }
  }

  /// Tamamlanan adımların geçmişini getir
  ///
  /// Returns: List<RoadmapStep> - Tamamlanan adımlar kronolojik sırada
  Future<List<RoadmapStep>> getCompletedStepsHistory() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/student/roadmap/completed'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => RoadmapStep.fromJson(item))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Geçmiş bulunamadı');
        }
      } else {
        throw Exception('Geçmiş hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Geçmiş alma hatası: $e');
    }
  }

  /// Bugün önerilen adımları getir
  ///
  /// Backend AI/algoritma ile kullanıcıya günlük plan önerir
  /// Returns: List<RoadmapStep> - Bugün yapılması önerilen adımlar
  Future<List<RoadmapStep>> getTodaysSteps() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/student/roadmap/today'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => RoadmapStep.fromJson(item))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Günlük plan bulunamadı');
        }
      } else {
        throw Exception('Günlük plan hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Günlük plan hatası: $e');
    }
  }

  /// Kullanıcı istatistiklerini getir
  ///
  /// Returns: Map - Detaylı istatistikler
  /// {
  ///   "streak_days": 7,           // Kaç gündür sürekli çalışıyor
  ///   "this_week_steps": 12,      // Bu hafta tamamlanan adım
  ///   "this_month_steps": 45,     // Bu ay tamamlanan adım
  ///   "total_study_time": 1200,   // Toplam çalışma süresi (dakika)
  ///   "level": 3,                 // Kullanıcı seviyesi
  ///   "badges": ["early_bird"]    // Kazanılan rozetler
  /// }
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/student/roadmap/stats'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        } else {
          throw Exception(data['message'] ?? 'İstatistik alınamadı');
        }
      } else {
        throw Exception('İstatistik hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('İstatistik hatası: $e');
    }
  }
}