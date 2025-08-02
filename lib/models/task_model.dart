import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus { pending, submitted, approved, expired }

class TaskModel {
  final String? id;
  final String siteId;
  final String title;
  final String description;
  final int duration; // in minutes
  final String monitorId;
  final String? monitorComment;
  final List<String> mediaUrls;
  final TaskStatus status;
  final DateTime? reportedDate;
  final DateTime createdAt;
  final DateTime? dueDate;

  TaskModel({
    this.id,
    required this.siteId,
    required this.title,
    required this.description,
    required this.duration,
    required this.monitorId,
    this.monitorComment,
    this.mediaUrls = const [],
    this.status = TaskStatus.pending,
    this.reportedDate,
    DateTime? createdAt,
    this.dueDate,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'siteId': siteId,
      'title': title,
      'description': description,
      'duration': duration,
      'monitorId': monitorId,
      'monitorComment': monitorComment,
      'mediaUrls': mediaUrls,
      'status': status.name,
      'reportedDate': reportedDate != null
          ? Timestamp.fromDate(reportedDate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      siteId: map['siteId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      duration: map['duration'] ?? 0,
      monitorId: map['monitorId'] ?? '',
      monitorComment: map['monitorComment'],
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => TaskStatus.pending,
      ),
      reportedDate: (map['reportedDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
    );
  }

  TaskModel copyWith({
    String? id,
    String? siteId,
    String? title,
    String? description,
    int? duration,
    String? monitorId,
    String? monitorComment,
    List<String>? mediaUrls,
    TaskStatus? status,
    DateTime? reportedDate,
    DateTime? createdAt,
    DateTime? dueDate,
  }) {
    return TaskModel(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      monitorId: monitorId ?? this.monitorId,
      monitorComment: monitorComment ?? this.monitorComment,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      status: status ?? this.status,
      reportedDate: reportedDate ?? this.reportedDate,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
