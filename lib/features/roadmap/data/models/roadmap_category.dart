import 'roadmap_step.dart';

class RoadmapCategory {
  final int id;
  final String title;
  final String description;
  final List<RoadmapStep> steps;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get completedStepsCount =>
      steps.where((step) => step.isCompleted).length;

  int get totalStepsCount => steps.length;

  double get progressPercentage =>
      totalStepsCount > 0 ? (completedStepsCount / totalStepsCount) * 100 : 0.0;

  bool get isCompleted =>
      totalStepsCount > 0 && completedStepsCount == totalStepsCount;

  RoadmapCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
    this.createdAt,
    this.updatedAt,
  });

  factory RoadmapCategory.fromJson(Map<String, dynamic> json) {
    return RoadmapCategory(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
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
      'steps': steps.map((step) => step.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'completed_steps_count': completedStepsCount,
      'total_steps_count': totalStepsCount,
      'progress_percentage': progressPercentage,
      'is_completed': isCompleted,
    };
  }

  RoadmapCategory copyWith({
    int? id,
    String? title,
    String? description,
    List<RoadmapStep>? steps,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoadmapCategory(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoadmapCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RoadmapCategory(id: $id, title: $title, completedSteps: $completedStepsCount/$totalStepsCount)';
  }
}