import 'roadmap_level.dart';
import 'roadmap_step.dart';

class RoadmapCategory {
  final int id;
  final String title;
  final String description;
  final List<RoadmapLevel> levels; // ✅ Artık levels kullanıyoruz
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ✅ Tüm steps'leri levels'lardan topla
  List<RoadmapStep> get allSteps {
    return levels.expand((level) => level.steps).toList();
  }

  // İstatistikler - tüm levels'lardan hesapla
  int get completedStepsCount =>
      allSteps.where((step) => step.isCompleted).length;

  int get totalStepsCount => allSteps.length;

  int get inProgressStepsCount =>
      allSteps.where((step) => step.isInProgress).length;

  int get notStartedStepsCount =>
      allSteps.where((step) => step.isNotStarted).length;

  int get totalLevelsCount => levels.length;

  int get completedLevelsCount =>
      levels.where((level) => level.isCompleted).length;

  double get progressPercentage =>
      totalStepsCount > 0 ? (completedStepsCount / totalStepsCount) * 100 : 0.0;

  bool get isCompleted =>
      totalStepsCount > 0 && completedStepsCount == totalStepsCount;

  bool get hasInProgress => inProgressStepsCount > 0;

  bool get isNotStarted =>
      completedStepsCount == 0 && inProgressStepsCount == 0;

  // Durum text'i
  String get statusText {
    if (isCompleted) return 'Tamamlandı';
    if (hasInProgress) return 'Devam Ediyor';
    if (isNotStarted) return 'Başlanmadı';
    return 'Kısmen Tamamlandı';
  }

  RoadmapCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.levels,
    this.createdAt,
    this.updatedAt,
  });

  factory RoadmapCategory.fromJson(Map<String, dynamic> json) {
    return RoadmapCategory(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      levels: (json['levels'] as List?) // ✅ levels array'ini parse et
          ?.map((level) => RoadmapLevel.fromJson(level))
          .toList() ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'levels': levels.map((level) => level.toJson()).toList(), // ✅ levels'ı serialize et
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'statistics': {
        'total_steps': totalStepsCount,
        'completed_steps': completedStepsCount,
        'in_progress_steps': inProgressStepsCount,
        'not_started_steps': notStartedStepsCount,
        'total_levels': totalLevelsCount,
        'completed_levels': completedLevelsCount,
        'progress_percentage': progressPercentage,
        'is_completed': isCompleted,
      },
    };
  }

  RoadmapCategory copyWith({
    int? id,
    String? title,
    String? description,
    List<RoadmapLevel>? levels,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoadmapCategory(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      levels: levels ?? this.levels,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ✅ Level güncelleme metodları
  RoadmapCategory updateLevel(RoadmapLevel updatedLevel) {
    final updatedLevels = levels.map((level) {
      return level.id == updatedLevel.id ? updatedLevel : level;
    }).toList();

    return copyWith(levels: updatedLevels);
  }

  // ✅ Step güncelleme metodu
  RoadmapCategory updateStep(RoadmapStep updatedStep) {
    final updatedLevels = levels.map((level) {
      // Bu level'da bu step var mı?
      final stepExists = level.steps.any((step) => step.id == updatedStep.id);
      if (stepExists) {
        return level.updateStep(updatedStep);
      }
      return level;
    }).toList();

    return copyWith(levels: updatedLevels);
  }

  // ✅ Step bulma metodları
  RoadmapStep? findStepById(int stepId) {
    for (final level in levels) {
      final step = level.findStepById(stepId);
      if (step != null) return step;
    }
    return null;
  }

  RoadmapLevel? findLevelById(int levelId) {
    try {
      return levels.firstWhere((level) => level.id == levelId);
    } catch (e) {
      return null;
    }
  }

  RoadmapLevel? findLevelByStepId(int stepId) {
    for (final level in levels) {
      if (level.steps.any((step) => step.id == stepId)) {
        return level;
      }
    }
    return null;
  }

  // ✅ Sıralı levels (order'a göre)
  List<RoadmapLevel> get sortedLevels {
    final sortedList = List<RoadmapLevel>.from(levels);
    sortedList.sort((a, b) => a.order.compareTo(b.order));
    return sortedList;
  }

  // ✅ Gelecek adım (bir sonraki başlanabilir step)
  RoadmapStep? get nextAvailableStep {
    for (final level in sortedLevels) {
      for (final step in level.steps) {
        if (step.canStart) return step;
      }
    }
    return null;
  }

  // ✅ Devam eden step'ler
  List<RoadmapStep> get inProgressSteps {
    return allSteps.where((step) => step.isInProgress).toList();
  }

  // ✅ Debug bilgisi
  Map<String, dynamic> get debugInfo => {
    'id': id,
    'title': title,
    'totalLevels': totalLevelsCount,
    'totalSteps': totalStepsCount,
    'completedSteps': completedStepsCount,
    'inProgressSteps': inProgressStepsCount,
    'progressPercentage': progressPercentage,
    'status': statusText,
    'levelInfo': levels.map((l) => l.debugInfo).toList(),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoadmapCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RoadmapCategory(id: $id, title: $title, levels: ${totalLevelsCount}, steps: ${completedStepsCount}/${totalStepsCount})';
  }
}