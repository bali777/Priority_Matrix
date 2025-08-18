import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

abstract class ITaskRepository {
  List<Task> getAll();
  Future<void> create(Task task);
  Future<void> update(Task task);
  Future<void> delete(String id);
  Future<void> replaceAll(List<Task> tasks);
  ValueListenable<Box> listenable();
}

class HiveTaskRepository implements ITaskRepository {
  static const String boxName = 'tasksBox';
  Box get _box => Hive.box(boxName);

  @override
  List<Task> getAll() {
    final List<Task> tasks = [];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw is Map) {
        tasks.add(Task.fromMap(Map<String, dynamic>.from(raw as Map)));
      }
    }
    return tasks;
  }

  @override
  Future<void> create(Task task) async {
    await _box.put(task.id, task.toMap());
  }

  @override
  Future<void> update(Task task) async {
    await _box.put(task.id, task.toMap());
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> replaceAll(List<Task> tasks) async {
    await _box.clear();
    for (final t in tasks) {
      await _box.put(t.id, t.toMap());
    }
  }

  @override
  ValueListenable<Box> listenable() => _box.listenable();
}
