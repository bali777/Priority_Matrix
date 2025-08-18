import 'package:flutter/foundation.dart';

enum ListId {
  inbox,
  highImpactEasy,        // Q1
  highImpactDifficult,   // Q2
  lowImpactEasy,         // Q3
  lowImpactDifficult,    // Q4
}

extension ListIdX on ListId {
  String get label {
    switch (this) {
      case ListId.inbox:
        return 'Inbox';
      case ListId.highImpactEasy:
        return 'High Impact • Easy';
      case ListId.highImpactDifficult:
        return 'High Impact • Difficult';
      case ListId.lowImpactEasy:
        return 'Low Impact • Easy';
      case ListId.lowImpactDifficult:
        return 'Low Impact • Difficult';
    }
  }
}

@immutable
class Task {
  final String id;
  final String title;
  final ListId listId;
  final int sortIndex;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.title,
    required this.listId,
    required this.sortIndex,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  Task copyWith({
    String? id,
    String? title,
    ListId? listId,
    int? sortIndex,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      listId: listId ?? this.listId,
      sortIndex: sortIndex ?? this.sortIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'listId': listId.index,
      'sortIndex': sortIndex,
      'isCompleted': isCompleted,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  static Task fromMap(Map<dynamic, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      listId: ListId.values[(map['listId'] as num).toInt()],
      sortIndex: (map['sortIndex'] as num).toInt(),
      isCompleted: (map['isCompleted'] as bool?) ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num).toInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((map['updatedAt'] as num).toInt()),
    );
  }
}
