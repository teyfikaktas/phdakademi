import 'roadmap_step.dart';

class RoadmapLevel {
  final int id;
  final String title;
  final String description;
  final int order;
  final List<RoadmapStep> steps;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // İstatistik getters
  int get totalStepsCount => steps.length;

  int get completedStepsCount =>
      steps.where((step) => step.isCompleted).length;

  int get inProgressStepsCount =>
      steps.where((step) => step.isInProgress).length;

  int get notStartedStepsCount =>
      steps.where((step) => step.isNotStarted).length;

  double get completionPercentage =>
      totalStepsCount > 0 ? (completedStepsCount / totalStepsCount) * 100 : 0.0;

  bool get isCompleted =>
      totalStepsCount > 0 && completedStepsCount == totalStepsCount;

  bool get hasInProgress => inProgressStepsCount > 0;

  bool get isNotStarted => completedStepsCount == 0 && inProgressStepsCount == 0;

  // Durum text'i
  String get statusText {
    if (isCompleted) return 'Tamamlandı';
    if (hasInProgress) return 'Devam Ediyor';
    if (isNotStarted) return 'Başlanmadı';
    return 'Kısmen Tamamlandı';
  }

  // Display title (sıra numarası ile)
  String get displayTitle => '$order. $title';

  RoadmapLevel({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.steps,
    this.createdAt,
    this.updatedAt,
  });

  factory RoadmapLevel.fromJson(Map<String, dynamic> json) {
    return RoadmapLevel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      order: json['order'] ?? 0,
      steps: (json['steps'] as List?)
          ?.map((step) => RoadmapStep.fromJson(step))
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
      'order': order,
      'steps': steps.map((step) => step.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'statistics': {
        'total_steps': totalStepsCount,
        'completed_steps': completedStepsCount,
        'in_progress_steps': inProgressStepsCount,
        'not_started_steps': notStartedStepsCount,
        'completion_percentage': completionPercentage,
      },
    };
  }

  RoadmapLevel copyWith({
    int? id,
    String? title,
    String? description,
    int? order,
    List<RoadmapStep>? steps,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoadmapLevel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      steps: steps ?? this.steps,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Belirli bir step'i güncelleme
  RoadmapLevel updateStep(RoadmapStep updatedStep) {
    final updatedSteps = steps.map((step) {
      return step.id == updatedStep.id ? updatedStep : step;
    }).toList();

    return copyWith(steps: updatedSteps);
  }

  // Step ID'sine göre step bulma
  RoadmapStep? findStepById(int stepId) {
    try {
      return steps.firstWhere((step) => step.id == stepId);
    } catch (e) {
      return null;
    }
  }

  // Debug bilgisi
  Map<String, dynamic> get debugInfo => {
    'id': id,
    'title': title,
    'order': order,
    'totalSteps': totalStepsCount,
    'completedSteps': completedStepsCount,
    'inProgressSteps': inProgressStepsCount,
    'completionPercentage': completionPercentage,
    'status': statusText,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoadmapLevel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RoadmapLevel(id: $id, title: $title, order: $order, steps: ${totalStepsCount}, completed: ${completedStepsCount})';
  }
}