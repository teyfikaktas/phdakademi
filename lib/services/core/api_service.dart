import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Laravel API'nin base URL'ini buraya yazın
  static const String baseUrl = 'https://phdakademi.com/api';

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Token interceptor ekle
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  // ========== AUTH METHODS ==========

  // Öğrenci girişi
  Future<Map<String, dynamic>> studentLogin(String email, String password) async {
    try {
      final response = await _dio.post('/student/login', data: {
        'email': email,
        'password': password,
      });

      // Token'ı sakla
      if (response.data['token'] != null) {
        await _storage.write(key: 'auth_token', value: response.data['token']);
      }

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Öğrenci bilgilerini getir
  Future<Map<String, dynamic>> getStudentProfile() async {
    try {
      final response = await _dio.get('/student/me');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Çıkış yap
  Future<void> logout() async {
    try {
      await _dio.post('/student/logout');
    } catch (e) {
      // Logout error'ı kritik değil
    } finally {
      await _storage.delete(key: 'auth_token');
    }
  }

  Future<Map<String, dynamic>> getTeacherCategories(String teacherSlug) async {
    try {
      debugPrint('ApiClient: POST /student/videos/teacher-categories');
      debugPrint('ApiClient: Request data: {"teacher_slug": "$teacherSlug"}');

      final response = await _dio.post('/student/videos/teacher-categories', data: {
        'teacher_slug': teacherSlug,
      });

      debugPrint('ApiClient: Response status: ${response.statusCode}');
      debugPrint('ApiClient: Response data type: ${response.data.runtimeType}');
      debugPrint('ApiClient: Response data: ${response.data}');

      // Response.data'nın tipini kontrol et
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        // Eğer string ise JSON decode et
        final decoded = json.decode(response.data);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }

      throw Exception('Invalid response format: ${response.data.runtimeType}');

    } on DioException catch (e) {
      debugPrint('ApiClient: DioException: ${e.message}');
      debugPrint('ApiClient: Response: ${e.response?.data}');
      throw _handleError(e);
    } catch (e) {
      debugPrint('ApiClient: General Exception: $e');
      rethrow;
    }
  }

  // Kategori içeriğini getir (alt kategoriler + videolar)
  Future<Map<String, dynamic>> getCategoryContent(String teacherSlug, int categoryId) async {
    try {
      debugPrint('ApiClient: POST /student/videos/category-content');
      debugPrint('ApiClient: Request data: {"teacher_slug": "$teacherSlug", "category_id": $categoryId}');

      final response = await _dio.post('/student/videos/category-content', data: {
        'teacher_slug': teacherSlug,
        'category_id': categoryId,
      });

      debugPrint('ApiClient: Response status: ${response.statusCode}');
      debugPrint('ApiClient: Response data type: ${response.data.runtimeType}');

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        final decoded = json.decode(response.data);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }

      throw Exception('Invalid response format: ${response.data.runtimeType}');

    } on DioException catch (e) {
      debugPrint('ApiClient: DioException: ${e.message}');
      throw _handleError(e);
    }
  }

  // Video detayını getir
  Future<Map<String, dynamic>> getVideoDetail(String teacherSlug, int videoId) async {
    try {
      debugPrint('ApiClient: POST /student/videos/video-detail');
      debugPrint('ApiClient: Request data: {"teacher_slug": "$teacherSlug", "video_id": $videoId}');

      final response = await _dio.post('/student/videos/video-detail', data: {
        'teacher_slug': teacherSlug,
        'video_id': videoId,
      });

      debugPrint('ApiClient: Response status: ${response.statusCode}');

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        final decoded = json.decode(response.data);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }

      throw Exception('Invalid response format: ${response.data.runtimeType}');

    } on DioException catch (e) {
      debugPrint('ApiClient: DioException: ${e.message}');
      throw _handleError(e);
    }
  }

  // Video arama
  Future<Map<String, dynamic>> searchVideos({
    required String teacherSlug,
    required String query,
    int? limit,
  }) async {
    try {
      debugPrint('ApiClient: POST /student/videos/search');

      final requestData = {
        'teacher_slug': teacherSlug,
        'query': query,
        if (limit != null) 'limit': limit,
      };

      debugPrint('ApiClient: Request data: $requestData');

      final response = await _dio.post('/student/videos/search', data: requestData);

      debugPrint('ApiClient: Response status: ${response.statusCode}');

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        final decoded = json.decode(response.data);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }

      throw Exception('Invalid response format: ${response.data.runtimeType}');

    } on DioException catch (e) {
      debugPrint('ApiClient: DioException: ${e.message}');
      throw _handleError(e);
    }
  }
  // ========== ROADMAP METHODS ==========

  // Roadmap getir
  Future<Map<String, dynamic>> getRoadmap() async {
    try {
      final response = await _dio.get('/student/roadmap');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Roadmap adımı başlat
  Future<Map<String, dynamic>> startRoadmapStep(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/student/roadmap/start-step', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Roadmap adımı tamamla
  Future<Map<String, dynamic>> completeRoadmapStep(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/student/roadmap/complete-step', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Günlük yorum ekle
  Future<Map<String, dynamic>> addDailyComment(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/student/roadmap/add-daily-comment', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Adım yorumlarını getir
  Future<Map<String, dynamic>> getStepComments() async {
    try {
      final response = await _dio.get('/student/roadmap/step-comments');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ========== UTILITY METHODS ==========

  // Token'ın varlığını kontrol et
  Future<bool> hasToken() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  // Token'ı manuel olarak kaydet
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  // Token'ı getir
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Hata yönetimi
  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Bağlantı zaman aşımı';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return 'Oturum süresi doldu. Lütfen tekrar giriş yapın.';
        } else if (statusCode == 422) {
          return 'Girilen bilgiler hatalı';
        } else if (statusCode == 404) {
          return 'İstenen içerik bulunamadı';
        } else if (statusCode == 500) {
          return 'Sunucu hatası oluştu';
        }
        return error.response?.data['message'] ?? 'Bilinmeyen hata oluştu';
      case DioExceptionType.cancel:
        return 'İstek iptal edildi';
      case DioExceptionType.unknown:
        return 'İnternet bağlantısını kontrol edin';
      default:
        return 'Bilinmeyen hata oluştu';
    }
  }
}