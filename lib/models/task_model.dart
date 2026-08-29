class TaskModel {
  final String id;
  final String title;
  final bool isDone;
  final DateTime createdAt;
  final int orderIndex;

  TaskModel({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.createdAt,
    this.orderIndex = 0,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    bool? isDone,
    DateTime? createdAt,
    int? orderIndex,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone,
      'createdAt': createdAt.toIso8601String(),
      'orderIndex': orderIndex,
    };
  }

  factory TaskModel.fromMap(Map<dynamic, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      isDone: map['isDone'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      orderIndex: map['orderIndex'] as int? ?? 0,
    );
  }
}
