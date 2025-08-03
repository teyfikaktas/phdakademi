import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/roadmap_category.dart';
import '../models/roadmap_level.dart';
import '../models/roadmap_step.dart';

/// RoadmapRepository - API işlemlerini yöneten sınıf
///
/// Bu sınıf tüm roadmap ile ilgili backend işlemlerini yapar:
/// - Kategorileri getir (levels yapısı ile)
/// - Adımları başlat/tamamla
/// - Günlük comment ekleme
/// - İlerleme takibi
class RoadmapRepository {
  // SharedPreferences'ta token'ın key'i
  static const String _tokenKey = 'auth_token';

  /// Token'ı SharedPreferences'tan al
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// HTTP header'larını oluştur
  Map<String, String> _getHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Tüm roadmap kategorilerini getir (levels yapısı ile)
  ///
  /// Bu method:
  /// 1. Token'ı al
  /// 2. API'ye GET request at (/roadmap)
  /// 3. Response'u parse et (levels array'i ile)
  /// 4. RoadmapCategory listesi döndür
  ///
  /// Backend Response Format:
  /// {
  ///   "success": true,
  ///   "data": [
  ///     {
  ///       "id": 1,
  ///       "title": "İngilizce",
  ///       "levels": [
  ///         {
  ///           "id": 1,
  ///           "title": "1. Aşama",
  ///           "order": 1,
  ///           "steps": [...]
  ///         }
  ///       ]
  ///     }
  ///   ]
  /// }
  Future<List<RoadmapCategory>> getRoadmapCategories() async {
    try {
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
          // 4. JSON'dan model'e dönüştür (levels yapısı ile)
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

  /// ✅ YENİ: Adımı başlat
  ///
  /// Backend API: POST /roadmap/start-step
  /// Request: { "step_id": 123, "category_id": 45 }
  /// Response: { "success": true, "data": {...} }
  Future<bool> startStep(int stepId, int categoryId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final requestBody = {
        'step_id': stepId,
        'category_id': categoryId,
      };

      debugPrint('Starting step: $requestBody');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/roadmap/start-step'),
        headers: _getHeaders(token),
        body: json.encode(requestBody),
      );

      debugPrint('Start step response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Adım başlatılamadı');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Adım başlatma hatası: $e');
    }
  }

  /// ✅ YENİ: Adımı tamamla
  ///
  /// Backend API: POST /roadmap/complete-step
  /// Request: { "step_id": 123, "category_id": 45, "comment": "..." }
  /// Response: { "success": true, "data": {...} }
  Future<bool> completeStep(int stepId, int categoryId, {String? comment}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final requestBody = <String, dynamic>{
        'step_id': stepId,
        'category_id': categoryId,
      };

      if (comment != null && comment.isNotEmpty) {
        requestBody['comment'] = comment;
      }

      debugPrint('Completing step: $requestBody');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/roadmap/complete-step'),
        headers: _getHeaders(token),
        body: json.encode(requestBody),
      );

      debugPrint('Complete step response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Adım tamamlanamadı');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Adım tamamlama hatası: $e');
    }
  }

  /// ✅ YENİ: Günlük comment ekleme
  ///
  /// Backend API: POST /roadmap/add-daily-comment
  /// Request: { "step_id": 123, "comment": "Bugün şunu yaptım..." }
  /// Response: { "success": true, "data": {...} }
  Future<bool> addDailyComment(int stepId, String comment) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final requestBody = {
        'step_id': stepId,
        'comment': comment,
      };

      debugPrint('Adding daily comment: $requestBody');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/roadmap/add-daily-comment'),
        headers: _getHeaders(token),
        body: json.encode(requestBody),
      );

      debugPrint('Daily comment response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Yorum eklenemedi');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Günlük yorum hatası: $e');
    }
  }

  /// ✅ YENİ: Adımın comment geçmişini getir
  ///
  /// Backend API: GET /roadmap/step-comments?step_id=123
  /// Response: { "success": true, "data": [...] }
  Future<List<Map<String, dynamic>>> getStepComments(int stepId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/roadmap/step-comments?step_id=$stepId'),
        headers: _getHeaders(token),
      );

      debugPrint('Step comments response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Yorumlar alınamadı');
        }
      } else {
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Yorum geçmişi hatası: $e');
    }
  }

  /// ✅ GÜNCELLENMIS: Mock data - levels yapısı ile test amaçlı
  List<RoadmapCategory> _getMockData() {
    return [
      RoadmapCategory(
        id: 1,
        title: "İngilizce Programı",
        description: "Temel seviyeden ileri seviyeye İngilizce öğrenin",
        levels: [
          RoadmapLevel(
            id: 1,
            title: "1. Aşama - Temel Seviye",
            description: "Temel gramer ve kelime bilgisi",
            order: 1,
            steps: [
              RoadmapStep(
                id: 1,
                title: "Temel Kelime Bilgisi",
                description: "Günlük 50 kelime öğren",
                categoryId: 1,
                levelId: 1,
                order: 1,
                status: 'completed',
                isCompleted: true,
                completedAt: DateTime.now().subtract(Duration(days: 2)),
              ),
              RoadmapStep(
                id: 2,
                title: "Basit Cümleler",
                description: "Temel cümle yapıları öğren",
                categoryId: 1,
                levelId: 1,
                order: 2,
                status: 'in_progress',
                isInProgress: true,
                canAddDailyComment: true,
                startedAt: DateTime.now().subtract(Duration(hours: 6)),
              ),
              RoadmapStep(
                id: 3,
                title: "Günlük Diyaloglar",
                description: "Günlük konuşma pratikleri",
                categoryId: 1,
                levelId: 1,
                order: 3,
                status: 'not_started',
              ),
            ],
          ),
          RoadmapLevel(
            id: 2,
            title: "2. Aşama - Orta Seviye",
            description: "Daha karmaşık gramer yapıları",
            order: 2,
            steps: [
              RoadmapStep(
                id: 4,
                title: "Zaman Kipler",
                description: "Geçmiş, şimdiki, gelecek zaman",
                categoryId: 1,
                levelId: 2,
                order: 1,
                status: 'not_started',
              ),
              RoadmapStep(
                id: 5,
                title: "Karmaşık Cümleler",
                description: "Bağlaçlı ve yan cümleli yapılar",
                categoryId: 1,
                levelId: 2,
                order: 2,
                status: 'not_started',
              ),
            ],
          ),
        ],
      ),
      RoadmapCategory(
        id: 2,
        title: "Matematik Programı",
        description: "Temel matematik becerilerini geliştirin",
        levels: [
          RoadmapLevel(
            id: 3,
            title: "1. Aşama - Sayılar",
            description: "Sayı sistemleri ve temel işlemler",
            order: 1,
            steps: [
              RoadmapStep(
                id: 6,
                title: "Doğal Sayılar",
                description: "Doğal sayılar ve özellikleri",
                categoryId: 2,
                levelId: 3,
                order: 1,
                status: 'not_started',
              ),
              RoadmapStep(
                id: 7,
                title: "Dört İşlem",
                description: "Toplama, çıkarma, çarpma, bölme",
                categoryId: 2,
                levelId: 3,
                order: 2,
                status: 'not_started',
              ),
            ],
          ),
        ],
      ),
    ];
  }

  /// Test amaçlı mock data kullan
  Future<List<RoadmapCategory>> getRoadmapCategoriesMock() async {
    await Future.delayed(Duration(milliseconds: 1500));
    return _getMockData();
  }

  /// ✅ ARTIK GEREKSİZ: Eski methodlar kaldırıldı
  /// - addStepToTodo() -> startStep() oldu
  /// - completeStep() güncellendi

  /// Kullanıcının genel ilerleme özetini getir
  Future<Map<String, dynamic>> getProgressSummary() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/roadmap/progress'),
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

  /// Belirli bir kategorinin detaylarını getir
  Future<RoadmapCategory> getCategoryDetails(int categoryId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/roadmap/category/$categoryId'),
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

  /// Belirli bir adımın detaylarını getir
  Future<RoadmapStep> getStepDetails(int stepId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/roadmap/step/$stepId'),
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
  Future<bool> syncProgress() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/roadmap/sync'),
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

  /// Kullanıcı istatistiklerini getir
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/roadmap/stats'),
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