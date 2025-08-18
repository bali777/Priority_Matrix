import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/models/task.dart';
import '../core/repository/task_repository.dart';
import '../core/repository/settings_repository.dart';

class AppState {
  final List<Task> tasks;
  final bool hideCompleted;
  final bool inboxCollapsed;

  const AppState({
    required this.tasks,
    required this.hideCompleted,
    required this.inboxCollapsed,
  });

  AppState copyWith({
    List<Task>? tasks,
    bool? hideCompleted,
    bool? inboxCollapsed,
  }) {
    return AppState(
      tasks: tasks ?? this.tasks,
      hideCompleted: hideCompleted ?? this.hideCompleted,
      inboxCollapsed: inboxCollapsed ?? this.inboxCollapsed,
    );
  }
}

final taskRepositoryProvider =
    Provider<ITaskRepository>((ref) => HiveTaskRepository());
final settingsRepositoryProvider =
    Provider<ISettingsRepository>((ref) => HiveSettingsRepository());

final appControllerProvider =
    StateNotifierProvider<AppController, AppState>((ref) {
  final tasksRepo = ref.read(taskRepositoryProvider);
  final settingsRepo = ref.read(settingsRepositoryProvider);
  return AppController(tasksRepo, settingsRepo)..init();
});

class _Snapshot {
  final List<Task> tasks;
  final bool hideCompleted;
  final bool inboxCollapsed;
  _Snapshot(this.tasks, this.hideCompleted, this.inboxCollapsed);
}

class AppController extends StateNotifier<AppState> {
  AppController(this._tasksRepo, this._settingsRepo)
      : super(const AppState(
          tasks: [],
          hideCompleted: false,
          inboxCollapsed: false,
        ));

  final ITaskRepository _tasksRepo;
  final ISettingsRepository _settingsRepo;

  // History stacks
  final List<_Snapshot> _undoStack = <_Snapshot>[];
  final List<_Snapshot> _redoStack = <_Snapshot>[];
  static const int _historyLimit = 50;
  bool _applyingSnapshot = false;

  VoidCallback? _removeTasksListener;
  VoidCallback? _removeSettingsListener;

  void init() {
    // Initial load
    final tasks = _tasksRepo.getAll();
    final hide = _settingsRepo.getHideCompleted();
    final inboxCollapsed = _settingsRepo.getInboxCollapsed();
    state = state.copyWith(
      tasks: _sortAll(tasks),
      hideCompleted: hide,
      inboxCollapsed: inboxCollapsed,
    );

    // Listen to hive changes to refresh state
    final tl = _tasksRepo.listenable();
    void tasksListener() {
      if (_applyingSnapshot) return;
      state = state.copyWith(tasks: _sortAll(_tasksRepo.getAll()));
    }

    tl.addListener(tasksListener);
    _removeTasksListener = () => tl.removeListener(tasksListener);

    final sl = _settingsRepo.listenable();
    void settingsListener() {
      if (_applyingSnapshot) return;
      state = state.copyWith(
        hideCompleted: _settingsRepo.getHideCompleted(),
        inboxCollapsed: _settingsRepo.getInboxCollapsed(),
      );
    }

    sl.addListener(settingsListener);
    _removeSettingsListener = () => sl.removeListener(settingsListener);
  }

  @override
  void dispose() {
    _removeTasksListener?.call();
    _removeSettingsListener?.call();
    super.dispose();
  }

  // Utilities
  List<Task> _sortAll(List<Task> tasks) {
    final copy = [...tasks];
    copy.sort((a, b) {
      if (a.listId.index != b.listId.index) {
        return a.listId.index.compareTo(b.listId.index);
      }
      return a.sortIndex.compareTo(b.sortIndex);
    });
    return copy;
  }

  List<Task> tasksFor(ListId listId, {bool onlyVisible = false}) {
    final items = state.tasks
        .where((t) => t.listId == listId)
        .toList()
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    if (onlyVisible && state.hideCompleted) {
      return items.where((t) => !t.isCompleted).toList();
    }
    return items;
  }

  // History helpers
  void _pushHistory() {
    final snapshot = _Snapshot(
      state.tasks.map((t) => t).toList(),
      state.hideCompleted,
      state.inboxCollapsed,
    );
    _undoStack.add(snapshot);
    if (_undoStack.length > _historyLimit) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  Future<void> _applySnapshot(_Snapshot snap) async {
    _applyingSnapshot = true;
    try {
      await _tasksRepo.replaceAll(snap.tasks);
      await _settingsRepo.setHideCompleted(snap.hideCompleted);
      await _settingsRepo.setInboxCollapsed(snap.inboxCollapsed);
      state = state.copyWith(
        tasks: _sortAll(snap.tasks),
        hideCompleted: snap.hideCompleted,
        inboxCollapsed: snap.inboxCollapsed,
      );
    } finally {
      _applyingSnapshot = false;
    }
  }

  Future<void> undo() async {
    if (_undoStack.isEmpty) return;
    final current = _Snapshot(
      state.tasks.map((t) => t).toList(),
      state.hideCompleted,
      state.inboxCollapsed,
    );
    final snap = _undoStack.removeLast();
    _redoStack.add(current);
    await _applySnapshot(snap);
    HapticFeedback.selectionClick();
  }

  Future<void> redo() async {
    if (_redoStack.isEmpty) return;
    final current = _Snapshot(
      state.tasks.map((t) => t).toList(),
      state.hideCompleted,
      state.inboxCollapsed,
    );
    final snap = _redoStack.removeLast();
    _undoStack.add(current);
    await _applySnapshot(snap);
    HapticFeedback.selectionClick();
  }

  // Actions
  Future<void> addTask(String title) async {
    if (title.trim().isEmpty) return;
    _pushHistory();
    final now = DateTime.now();
    final newSort = tasksFor(ListId.inbox).length;
    final task = Task(
      id: const Uuid().v4(),
      title: title.trim(),
      listId: ListId.inbox,
      sortIndex: newSort,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
    await _tasksRepo.create(task);
  }

  Future<void> deleteTask(String id) async {
    _pushHistory();
    await _tasksRepo.delete(id);
  }

  Future<void> toggleCompleted(String id) async {
    _pushHistory();
    final t = state.tasks.firstWhere((e) => e.id == id);
    final updated = t.copyWith(
      isCompleted: !t.isCompleted,
      updatedAt: DateTime.now(),
    );
    await _tasksRepo.update(updated);
  }

  Future<void> moveTaskToList(
    String id,
    ListId listId, {
    bool toTop = false,
  }) async {
    _pushHistory();
    final now = DateTime.now();
    final items = tasksFor(listId);
    final newIndex = toTop ? 0 : items.length;

    // Shift indices if inserting at top
    final all = [...state.tasks];
    if (toTop) {
      for (final t in items) {
        final nt = t.copyWith(sortIndex: t.sortIndex + 1, updatedAt: now);
        all[all.indexWhere((x) => x.id == nt.id)] = nt;
        await _tasksRepo.update(nt);
      }
    }

    final idx = all.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final src = all[idx];
    final moved = src.copyWith(
      listId: listId,
      sortIndex: newIndex,
      updatedAt: now,
    );
    await _tasksRepo.update(moved);
    HapticFeedback.lightImpact();
  }

  Future<void> reorderWithinList({
    required ListId listId,
    required int oldIndex,
    required int newIndex,
  }) async {
    final visible = tasksFor(listId, onlyVisible: true);
    if (visible.isEmpty) return;

    if (newIndex > oldIndex) newIndex -= 1;

    _pushHistory();

    final moving = visible.removeAt(oldIndex);
    visible.insert(newIndex, moving);

    final hidden = state.hideCompleted
        ? tasksFor(listId).where((t) => t.isCompleted).toList()
        : <Task>[];

    final combined = <Task>[...visible, ...hidden];

    for (var i = 0; i < combined.length; i++) {
      final t = combined[i];
      if (t.sortIndex != i) {
        await _tasksRepo.update(
          t.copyWith(sortIndex: i, updatedAt: DateTime.now()),
        );
      }
    }
  }

  Future<void> setHideCompleted(bool value) async {
    _pushHistory();
    await _settingsRepo.setHideCompleted(value);
  }

  Future<void> toggleInboxCollapsed() async {
    _pushHistory();
    await _settingsRepo.setInboxCollapsed(!state.inboxCollapsed);
  }
}    });
    return copy;
  }

  List<Task> tasksFor(ListId listId, {bool onlyVisible = false}) {
    final items = state.tasks.where((t) => t.listId == listId).toList()
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    if (onlyVisible && state.hideCompleted) {
      return items.where((t) => !t.isCompleted).toList();
    }
    return items;
  }

  // History helpers
  void _pushHistory() {
    // Snapshot current state
    final snapshot = _Snapshot(
      state.tasks.map((t) => t).toList(), // shallow copy
      state.hideCompleted,
      state.inboxCollapsed,
    );
    _undoStack.add(snapshot);
    // Cap size
    if (_undoStack.length > _historyLimit) {
      _undoStack.removeAt(0);
    }
    // Any new action clears redo
    _redoStack.clear();
  }

  Future<void> _applySnapshot(_Snapshot snap) async {
    _applyingSnapshot = true;
    try {
      await _tasksRepo.replaceAll(snap.tasks);
      await _settingsRepo.setHideCompleted(snap.hideCompleted);
      await _settingsRepo.setInboxCollapsed(snap.inboxCollapsed);
      state = state.copyWith(
        tasks: _sortAll(snap.tasks),
        hideCompleted: snap.hideCompleted,
        inboxCollapsed: snap.inboxCollapsed,
      );
    } finally {
      _applyingSnapshot = false;
    }
  }

  Future<void> undo() async {
    if (_undoStack.isEmpty) return;
    final current = _Snapshot(state.tasks.map((t) => t).toList(), state.hideCompleted, state.inboxCollapsed);
    final snap = _undoStack.removeLast();
    _redoStack.add(current);
    await _applySnapshot(snap);
    HapticFeedback.selectionClick();
  }

  Future<void> redo() async {
    if (_redoStack.isEmpty) return;
    final current = _Snapshot(state.tasks.map((t) => t).toList(), state.hideCompleted, state.inboxCollapsed);
    final snap = _redoStack.removeLast();
    _undoStack.add(current);
    await _applySnapshot(snap);
    HapticFeedback.selectionClick();
  }

  // Actions
  Future<void> addTask(String title) async {
    if (title.trim().isEmpty) return;
    _pushHistory();
    final now = DateTime.now();
    final newSort = tasksFor(ListId.inbox).length; // append at end of inbox
    final task = Task(
      id: const Uuid().v4(),
      title: title.trim(),
      listId: ListId.inbox,
      sortIndex: newSort,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
    await _tasksRepo.create(task);
  }

  Future<void> deleteTask(String id) async {
    _pushHistory();
    await _tasksRepo.delete(id);
  }

  Future<void> toggleCompleted(String id) async {
    _pushHistory();
    final t = state.tasks.firstWhere((e) => e.id == id);
    final updated = t.copyWith(
      isCompleted: !t.isCompleted,
      updatedAt: DateTime.now(),
    );
    await _tasksRepo.update(updated);
  }

  Future<void> moveTaskToList(String id, ListId listId, {bool toTop = false}) async {
    _pushHistory();
    final now = DateTime.now();
    final items = tasksFor(listId);
    final newIndex = toTop ? 0 : items.length;
    // Shift indices if inserting at top
    List<Task> updatedAll = [...state.tasks];
    if (toTop) {
      for (final t in items) {
        final nt = t.copyWith(sortIndex: t.sortIndex + 1, updatedAt: now);
        updatedAll[updatedAll.indexWhere((x) => x.id == nt.id)] = nt;
      }
    }
    final idx = updatedAll.indexWhere((e) => e.id == id);
    final src = updatedAll[idx];
    final moved = src.copyWith(listId: listId, sortIndex: newIndex, updatedAt: now);
    updatedAll[idx] = moved;
    // Persist all affected
    // More efficient: update individually
    await _tasksRepo.update(moved);
    if (toTop) {
      for (final t in items) {
        await _tasksRepo.update(
          t.copyWith(sortIndex: t.sortIndex + 1, updatedAt: now),
        );
      }
    }
    HapticFeedback.lightImpact();
  }

  Future<void> reorderWithinList({
    required ListId listId,
    required int oldIndex,
    required int newIndex,
  }) async {
    // Build visible list (respects hideCompleted)
    final visible = tasksFor(listId, onlyVisible: true);
    if (visible.isEmpty) return;

    // Adjust newIndex when moving down (Flutter behavior)
    if (newIndex > oldIndex) newIndex -= 1;

    _pushHistory();

    // Reorder visible list in memory
    final moved = visible.removeAt(oldIndex);
    visible.insert(newIndex, moved);

    // Determine hidden (if hideCompleted)
    final hidden = state.hideCompleted
        ? tasksFor(listId).where((t) => t.isCompleted).toList()
        : <Task>[];

    // New final order for this list
    final combined = <Task>[...visible, ...hidden];

    // Reindex and persist only changed list items
    for (var i = 0; i < combined.length; i++) {
      final t = combined[i];
      if (t.sortIndex != i) {
        await _tasksRepo.update(t.copyWith(sortIndex: i, updatedAt: DateTime.now()));
      }
    }
  }

  Future<void> setHideCompleted(bool value) async {
    _pushHistory();
    await _settingsRepo.setHideCompleted(value);
  }

  Future<void> toggleInboxCollapsed() async {
    _pushHistory();
    await _settingsRepo.setInboxCollapsed(!state.inboxCollapsed);
  }
}
