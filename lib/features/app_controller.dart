import 'package:flutter/services.dart'; // HapticFeedback + VoidCallback
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
