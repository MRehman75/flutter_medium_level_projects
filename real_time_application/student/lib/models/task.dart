class Task {
  final String id;
  final String studentId;
  final String title;
  final String description;
  final String status;
  final DateTime assignedAt;
  final DateTime? completedAt;
  final DateTime? dueDate;

  Task({
    required this.id,
    required this.studentId,
    required this.title,
    required this.description,
    required this.status,
    required this.assignedAt,
    this.completedAt,
    this.dueDate,
  });

  bool get isCompleted => status != 'pending';

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      studentId: json['student_id'],
      title: json['title'],
      description: json['description'] ?? '',
      status: json['status'],
      assignedAt: DateTime.parse(json['assigned_at']),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'student_id': studentId,
    'title': title,
    'description': description,
    'status': status,
    'assigned_at': assignedAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'due_date': dueDate?.toIso8601String(),
  };
}