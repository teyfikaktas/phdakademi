// ========== API RESPONSE MODELS ==========
import 'package:phd_akademi/features/video/data/models/teacher.dart';
import 'package:phd_akademi/features/video/data/models/video.dart';
import 'package:phd_akademi/features/video/data/models/video_category.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic)? fromJsonT,
      ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}

// ========== TEACHER CATEGORIES RESPONSE ==========
class TeacherCategoriesResponse {
  final Teacher teacher;
  final List<VideoCategory> categories;

  TeacherCategoriesResponse({
    required this.teacher,
    required this.categories,
  });

  factory TeacherCategoriesResponse.fromJson(Map<String, dynamic> json) {
    return TeacherCategoriesResponse(
      teacher: Teacher.fromJson(json['teacher'] ?? {}),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((category) => VideoCategory.fromJson(category as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ========== CATEGORY CONTENT RESPONSE ==========
class CategoryContentResponse {
  final Teacher teacher;
  final List<VideoCategory> subCategories;
  final List<Video> videos;

  CategoryContentResponse({
    required this.teacher,
    required this.subCategories,
    required this.videos,
  });

  factory CategoryContentResponse.fromJson(Map<String, dynamic> json) {
    return CategoryContentResponse(
      teacher: Teacher.fromJson(json['teacher'] ?? {}),
      subCategories: (json['sub_categories'] as List<dynamic>? ?? [])
          .map((category) => VideoCategory.fromJson(category as Map<String, dynamic>))
          .toList(),
      videos: (json['videos'] as List<dynamic>? ?? [])
          .map((video) => Video.fromJson(video as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ========== VIDEO DETAIL RESPONSE ==========
class VideoDetailResponse {
  final Teacher teacher;
  final Video video;
  final VideoCategory? category;

  VideoDetailResponse({
    required this.teacher,
    required this.video,
    this.category,
  });

  factory VideoDetailResponse.fromJson(Map<String, dynamic> json) {
    return VideoDetailResponse(
      teacher: Teacher.fromJson(json['teacher'] ?? {}),
      video: Video.fromJson(json['video'] ?? {}),
      category: json['category'] != null
          ? VideoCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ========== SEARCH RESPONSE ==========
class SearchResponse {
  final String query;
  final int totalResults;
  final List<Video> videos;

  SearchResponse({
    required this.query,
    required this.totalResults,
    required this.videos,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      query: json['query']?.toString() ?? '',
      totalResults: _parseInt(json['total_results']) ?? 0,
      videos: (json['videos'] as List<dynamic>? ?? [])
          .map((video) => Video.fromJson(video as Map<String, dynamic>))
          .toList(),
    );
  }

  // Helper method for parsing int
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

// ========== STUDENT MODEL ==========
class Student {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;

  Student({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatar: json['avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
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