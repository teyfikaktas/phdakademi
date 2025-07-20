import 'package:flutter/foundation.dart';

import '../features/video/data/models/ApiResponse.dart';
import '../features/video/data/models/teacher.dart';
import '../features/video/data/models/video.dart';
import '../features/video/data/models/video_category.dart';
import 'core/api_service.dart';

class VideoService {
  final ApiClient _apiClient;

  VideoService(this._apiClient);

  // ========== TEACHER METHODS ==========

  /// Öğretmenin kategorilerini getir
  Future<TeacherCategoriesResponse> getTeacherCategories(String teacherSlug) async {
    try {
      debugPrint('VideoService: Getting categories for teacher: $teacherSlug');

      final response = await _apiClient.getTeacherCategories(teacherSlug);

      debugPrint('VideoService: API Response: $response');

      if (response['success'] == true && response['data'] != null) {
        // API response'u güvenli şekilde parse et
        final data = response['data'] as Map<String, dynamic>;
        return TeacherCategoriesResponse.fromJson(data);
      } else {
        throw Exception(response['message'] ?? 'Kategoriler getirilemedi');
      }
    } catch (e) {
      debugPrint('VideoService.getTeacherCategories error: $e');
      rethrow;
    }
  }

  // ========== CATEGORY METHODS ==========

  /// Kategori içeriğini getir (alt kategoriler + videolar)
  Future<CategoryContentResponse> getCategoryContent({
    required String teacherSlug,
    required int categoryId,
  }) async {
    try {
      debugPrint('VideoService: Getting category content for: $teacherSlug, categoryId: $categoryId');

      final response = await _apiClient.getCategoryContent(teacherSlug, categoryId);

      debugPrint('VideoService: API Response: $response');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        return CategoryContentResponse.fromJson(data);
      } else {
        throw Exception(response['message'] ?? 'Kategori içeriği getirilemedi');
      }
    } catch (e) {
      debugPrint('VideoService.getCategoryContent error: $e');
      rethrow;
    }
  }

  // ========== VIDEO METHODS ==========

  /// Video detayını getir
  Future<VideoDetailResponse> getVideoDetail({
    required String teacherSlug,
    required int videoId,
  }) async {
    try {
      debugPrint('VideoService: Getting video detail for: $teacherSlug, videoId: $videoId');

      final response = await _apiClient.getVideoDetail(teacherSlug, videoId);

      debugPrint('VideoService: API Response: $response');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        return VideoDetailResponse.fromJson(data);
      } else {
        throw Exception(response['message'] ?? 'Video detayı getirilemedi');
      }
    } catch (e) {
      debugPrint('VideoService.getVideoDetail error: $e');
      rethrow;
    }
  }

  /// Video arama
  Future<SearchResponse> searchVideos({
    required String teacherSlug,
    required String query,
    int limit = 20,
  }) async {
    try {
      if (query.trim().length < 2) {
        throw Exception('Arama terimi en az 2 karakter olmalıdır');
      }

      debugPrint('VideoService: Searching videos for: $teacherSlug, query: $query');

      final response = await _apiClient.searchVideos(
        teacherSlug: teacherSlug,
        query: query.trim(),
        limit: limit,
      );

      debugPrint('VideoService: API Response: $response');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        return SearchResponse.fromJson(data);
      } else {
        throw Exception(response['message'] ?? 'Arama yapılamadı');
      }
    } catch (e) {
      debugPrint('VideoService.searchVideos error: $e');
      rethrow;
    }
  }

  // ========== UTILITY METHODS ==========

  /// Video listesini kategoriye göre filtrele
  List<Video> filterVideosByCategory(List<Video> videos, int categoryId) {
    try {
      return videos.where((video) => video.kategori == categoryId).toList();
    } catch (e) {
      debugPrint('VideoService.filterVideosByCategory error: $e');
      return [];
    }
  }

  /// Video listesini tarihe göre sırala (en yeni önce)
  List<Video> sortVideosByDate(List<Video> videos, {bool ascending = false}) {
    try {
      final sortedVideos = List<Video>.from(videos);
      sortedVideos.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return ascending ? -1 : 1;
        if (b.createdAt == null) return ascending ? 1 : -1;

        final dateA = DateTime.tryParse(a.createdAt!) ?? DateTime.now();
        final dateB = DateTime.tryParse(b.createdAt!) ?? DateTime.now();

        return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      });
      return sortedVideos;
    } catch (e) {
      debugPrint('VideoService.sortVideosByDate error: $e');
      return videos;
    }
  }

  /// Video başlığını temizle (null kontrolü)
  String getVideoTitle(Video video) {
    try {
      return video.baslik?.trim().isNotEmpty == true
          ? video.baslik!
          : 'İsimsiz Video';
    } catch (e) {
      debugPrint('VideoService.getVideoTitle error: $e');
      return 'İsimsiz Video';
    }
  }

  /// Video açıklamasını temizle (null kontrolü)
  String getVideoDescription(Video video) {
    try {
      return video.aciklama?.trim().isNotEmpty == true
          ? video.aciklama!
          : 'Açıklama bulunmuyor';
    } catch (e) {
      debugPrint('VideoService.getVideoDescription error: $e');
      return 'Açıklama bulunmuyor';
    }
  }

  /// Video tarihini formatla
  String formatVideoDate(Video video) {
    try {
      if (video.createdAt == null) return 'Tarih belirtilmemiş';

      final date = DateTime.parse(video.createdAt!);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 30) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} gün önce';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} saat önce';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} dakika önce';
      } else {
        return 'Az önce';
      }
    } catch (e) {
      debugPrint('VideoService.formatVideoDate error: $e');
      return 'Tarih belirtilmemiş';
    }
  }

  /// Kategori adını temizle (null kontrolü)
  String getCategoryName(VideoCategory category) {
    try {
      return category.name.trim().isNotEmpty
          ? category.name
          : 'İsimsiz Kategori';
    } catch (e) {
      debugPrint('VideoService.getCategoryName error: $e');
      return 'İsimsiz Kategori';
    }
  }

  /// Öğretmen adını temizle (null kontrolü)
  String getTeacherName(Teacher teacher) {
    try {
      return teacher.name.trim().isNotEmpty
          ? teacher.name
          : 'İsimsiz Öğretmen';
    } catch (e) {
      debugPrint('VideoService.getTeacherName error: $e');
      return 'İsimsiz Öğretmen';
    }
  }
}