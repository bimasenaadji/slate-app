class TaskModel {
  final String id;
  final String title;
  final bool isDone;
  final DateTime createdAt;
  final int orderIndex;
  final bool isCarriedOver;
  final DateTime? scheduledDate;
  final String? reminderAnchor; // 'morning' | 'afternoon' | 'evening' | null

  TaskModel({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.createdAt,
    this.orderIndex = 0,
    this.isCarriedOver = false,
    this.scheduledDate,
    this.reminderAnchor,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    bool? isDone,
    DateTime? createdAt,
    int? orderIndex,
    bool? isCarriedOver,
    DateTime? scheduledDate,
    bool clearScheduledDate = false,
    String? reminderAnchor,
    bool clearReminderAnchor = false,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      orderIndex: orderIndex ?? this.orderIndex,
      isCarriedOver: isCarriedOver ?? this.isCarriedOver,
      scheduledDate: clearScheduledDate
          ? null
          : (scheduledDate ?? this.scheduledDate),
      reminderAnchor: clearReminderAnchor
          ? null
          : (reminderAnchor ?? this.reminderAnchor),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone,
      'createdAt': createdAt.toIso8601String(),
      'orderIndex': orderIndex,
      'isCarriedOver': isCarriedOver,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'reminderAnchor': reminderAnchor,
    };
  }

  factory TaskModel.fromMap(Map<dynamic, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      isDone: map['isDone'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      orderIndex: map['orderIndex'] as int? ?? 0,
      isCarriedOver: map['isCarriedOver'] as bool? ?? false,
      scheduledDate: map['scheduledDate'] != null
          ? DateTime.parse(map['scheduledDate'] as String)
          : null,
      reminderAnchor: map['reminderAnchor'] as String?,
    );
  }
}
