import 'package:flutter/material.dart';

class RoadmapStep {
  final int id;
  final String title;
  final String description;
  final String? text;
  final int categoryId;
  final int levelId;
  final int order;
  final String status; // 'not_started', 'in_progress', 'completed'
  final bool isCompleted;
  final bool isInProgress;
  final bool? canAddDailyComment; // YENİ: Günlük comment ekleyebilir mi?
  final String? lastComment; // YENİ: Son eklenen comment
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RoadmapStep({
    required this.id,
    required this.title,
    required this.description,
    this.text,
    this.categoryId = 0,
    this.levelId = 0,
    this.order = 0,
    this.status = 'not_started',
    this.isCompleted = false,
    this.isInProgress = false,
    this.canAddDailyComment, // YENİ
    this.lastComment, // YENİ
    this.startedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory RoadmapStep.fromJson(Map<String, dynamic> json) {
    return RoadmapStep(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      text: json['text'],
      categoryId: json['category_id'] ?? 0,
      levelId: json['level_id'] ?? 0,
      order: json['order'] ?? 0,
      status: json['status'] ?? 'not_started',
      isCompleted: json['is_completed'] ?? false,
      isInProgress: json['is_in_progress'] ?? false,
      canAddDailyComment: json['can_add_daily_comment'], // YENİ
      lastComment: json['last_comment'], // YENİ
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
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
      'text': text,
      'category_id': categoryId,
      'level_id': levelId,
      'order': order,
      'status': status,
      'is_completed': isCompleted,
      'is_in_progress': isInProgress,
      'can_add_daily_comment': canAddDailyComment, // YENİ
      'last_comment': lastComment, // YENİ
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  RoadmapStep copyWith({
    int? id,
    String? title,
    String? description,
    String? text,
    int? categoryId,
    int? levelId,
    int? order,
    String? status,
    bool? isCompleted,
    bool? isInProgress,
    bool? canAddDailyComment, // YENİ
    String? lastComment, // YENİ
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoadmapStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      text: text ?? this.text,
      categoryId: categoryId ?? this.categoryId,
      levelId: levelId ?? this.levelId,
      order: order ?? this.order,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      isInProgress: isInProgress ?? this.isInProgress,
      canAddDailyComment: canAddDailyComment ?? this.canAddDailyComment, // YENİ
      lastComment: lastComment ?? this.lastComment, // YENİ
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convenience methods
  String get displayTitle => '$order. $title';

  bool get hasDescription => description.isNotEmpty;

  bool get hasText => text != null && text!.isNotEmpty;

  String get fullContent => hasText ? text! : description;

  bool get isNotStarted => status == 'not_started';

  // YENİ: Comment ile ilgili metodlar
  bool get hasLastComment => lastComment != null && lastComment!.isNotEmpty;

  bool get canAddDailyCommentToday =>
      isInProgress && (canAddDailyComment ?? false);

  String get dailyCommentButtonText {
    if (!isInProgress) return '';
    if (canAddDailyComment == true) {
      return 'Günlük İlerleme';
    } else {
      return 'Bugün Eklendi';
    }
  }

  Duration? get timeSinceCompleted {
    if (completedAt == null) return null;
    return DateTime.now().difference(completedAt!);
  }

  Duration? get timeSinceStarted {
    if (startedAt == null) return null;
    return DateTime.now().difference(startedAt!);
  }

  String get statusText {
    switch (status) {
      case 'completed':
        if (completedAt != null) {
          final diff = DateTime.now().difference(completedAt!);
          if (diff.inDays > 0) {
            return '${diff.inDays} gün önce tamamlandı';
          } else if (diff.inHours > 0) {
            return '${diff.inHours} saat önce tamamlandı';
          } else {
            return 'Az önce tamamlandı';
          }
        }
        return 'Tamamlandı';

      case 'in_progress':
        String baseText;
        if (startedAt != null) {
          final diff = DateTime.now().difference(startedAt!);
          if (diff.inDays > 0) {
            baseText = '${diff.inDays} gün önce başladı';
          } else if (diff.inHours > 0) {
            baseText = '${diff.inHours} saat önce başladı';
          } else {
            baseText = 'Az önce başladı';
          }
        } else {
          baseText = 'Devam ediyor';
        }

        // YENİ: Günlük comment durumu ekleme
        if (canAddDailyComment == false) {
          baseText += ' • Bugün yorum eklendi';
        } else if (canAddDailyComment == true) {
          baseText += ' • Günlük yorum ekleyebilirsiniz';
        }

        return baseText;

      default:
        return 'Başlanmadı';
    }
  }

  String get statusDisplayText {
    switch (status) {
      case 'completed':
        return 'Tamamlandı';
      case 'in_progress':
        return 'Devam Ediyor';
      default:
        return 'Başlanmadı';
    }
  }

  // YENİ: Detaylı status bilgisi
  String get detailedStatusText {
    String baseStatus = statusDisplayText;

    if (isInProgress) {
      if (canAddDailyComment == true) {
        baseStatus += ' (Günlük yorum ekleyebilirsiniz)';
      } else if (canAddDailyComment == false) {
        baseStatus += ' (Bugün yorum eklendi)';
      }
    }

    if (hasLastComment) {
      baseStatus += '\nSon yorum: ${_truncateComment(lastComment!, 50)}';
    }

    return baseStatus;
  }

  // YENİ: Comment'i kısaltma metodu
  String _truncateComment(String comment, int maxLength) {
    if (comment.length <= maxLength) return comment;
    return '${comment.substring(0, maxLength)}...';
  }

  // Status kontrol metodları
  bool get canStart => status == 'not_started';
  bool get canComplete => status == 'in_progress';
  bool get canRestart => status == 'completed';

  // YENİ: Buton durumları
  bool get shouldShowDailyCommentButton =>
      isInProgress && (canAddDailyComment == true);

  bool get shouldShowCommentsHistoryButton =>
      isInProgress || isCompleted;

  bool get shouldShowStartButton => canStart;

  bool get shouldShowCompleteButton => canComplete;

  // YENİ: İkon belirleme
  IconData get statusIcon {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.play_circle_outline;
      default:
        return Icons.play_arrow;
    }
  }

  // YENİ: Renk belirleme
  Color getStatusColor(BuildContext context) {
    switch (status) {
      case 'completed':
        return Theme.of(context).colorScheme.primary;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // YENİ: Progress yüzdesi hesaplama (gelecekte kullanım için)
  double get progressPercentage {
    switch (status) {
      case 'completed':
        return 1.0;
      case 'in_progress':
        return 0.5; // Gelecekte daha detaylı hesaplama yapılabilir
      default:
        return 0.0;
    }
  }

  // YENİ: Debug bilgisi
  Map<String, dynamic> get debugInfo => {
    'id': id,
    'title': title,
    'status': status,
    'canAddDailyComment': canAddDailyComment,
    'hasLastComment': hasLastComment,
    'isInProgress': isInProgress,
    'isCompleted': isCompleted,
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoadmapStep && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RoadmapStep(id: $id, title: $title, status: $status, canAddDailyComment: $canAddDailyComment)';
  }
}