import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/models/task.dart';
import '../app_controller.dart';
import '../tasks/widgets/task_tile.dart';
import '../help/help_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _inboxScroll = ScrollController();
  final _q1Scroll = ScrollController();
  final _q2Scroll = ScrollController();
  final _q3Scroll = ScrollController();
  final _q4Scroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final ctr = ref.read(appControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Priority Matrix'),
        actions: [
          IconButton(
            tooltip: 'Help',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpPage())),
          ),
          IconButton(
            tooltip: app.hideCompleted ? 'Show completed' : 'Hide completed',
            icon: Icon(app.hideCompleted ? Icons.visibility_off : Icons.visibility),
            onPressed: () => ctr.setHideCompleted(!app.hideCompleted),
          ),
          IconButton(
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: () => ctr.undo(),
          ),
          IconButton(
            tooltip: 'Redo',
            icon: const Icon(Icons.redo),
            onPressed: () => ctr.redo(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTaskSheet(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Matrix Grid
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Effort labels
                    Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(child: _AxisChip(label: 'Easy')),
                        const SizedBox(width: 12),
                        Expanded(child: _AxisChip(label: 'Difficult')),
                        const SizedBox(width: 12),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Top row (Q1 & Q2) equal height
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _QuadrantContainer(
                              title: ListId.highImpactEasy.label,
                              listId: ListId.highImpactEasy,
                              scrollController: _q1Scroll,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuadrantContainer(
                              title: ListId.highImpactDifficult.label,
                              listId: ListId.highImpactDifficult,
                              scrollController: _q2Scroll,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Bottom row (Q3 & Q4) equal height
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _QuadrantContainer(
                              title: ListId.lowImpactEasy.label,
                              listId: ListId.lowImpactEasy,
                              scrollController: _q3Scroll,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuadrantContainer(
                              title: ListId.lowImpactDifficult.label,
                              listId: ListId.lowImpactDifficult,
                              scrollController: _q4Scroll,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Impact labels
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _AxisChip(label: 'High Impact'),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _AxisChip(label: 'Low Impact'),
                    ),
                  ],
                ),
              ),
            ),
            // Inbox strip
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: app.inboxCollapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: _InboxSection(scrollController: _inboxScroll),
              secondChild: _InboxHeaderCollapsed(onExpand: ref.read(appControllerProvider.notifier).toggleInboxCollapsed),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddTaskSheet(BuildContext context) async {
    final ctr = ref.read(appControllerProvider.notifier);
    final titleCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16, right: 16, top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24, borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Add Task', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) async {
                    if (formKey.currentState?.validate() != true) return;
                    await ctr.addTask(titleCtrl.text);
                    if (context.mounted) Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() != true) return;
                      await ctr.addTask(titleCtrl.text);
                      if (context.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Add to Inbox'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AxisChip extends StatelessWidget {
  const _AxisChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _QuadrantContainer extends ConsumerWidget {
  const _QuadrantContainer({
    required this.title,
    required this.listId,
    required this.scrollController,
  });

  final String title;
  final ListId listId;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final ctr = ref.read(appControllerProvider.notifier);
    final tasks = ctr.tasksFor(listId, onlyVisible: app.hideCompleted);

    return DragTarget<String>(
      onWillAccept: (_) => true,
      onAccept: (taskId) => ctr.moveTaskToList(taskId, listId),
      builder: (context, candidate, rejected) {
        final highlight = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: highlight ? kElectricBlue : Colors.white12, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      )),
              const SizedBox(height: 8),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text('Drag tasks here',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38)),
                      )
                    : ReorderableListView.builder(
                        shrinkWrap: true,
                        buildDefaultDragHandles: false,
                        padding: EdgeInsets.zero,
                        itemCount: tasks.length,
                        onReorder: (oldIndex, newIndex) => ctr.reorderWithinList(
                          listId: listId,
                          oldIndex: oldIndex,
                          newIndex: newIndex,
                        ),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _buildReorderableItem(
                            key: ValueKey(task.id),
                            child: _DraggableTaskTile(
                              task: task,
                              number: index + 1,
                              onToggleDone: () => ctr.toggleCompleted(task.id),
                              onDelete: () => _deleteWithUndo(context, ref, task.id),
                              // Reorder handle for within-list
                              reorderHandleBuilder: (child) => ReorderableDragStartListener(
                                index: index,
                                child: child,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReorderableItem({required Key key, required Widget child}) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: child,
      ),
    );
  }

  void _deleteWithUndo(BuildContext context, WidgetRef ref, String id) async {
    final ctr = ref.read(appControllerProvider.notifier);
    await ctr.deleteTask(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => ctr.undo(),
          ),
        ),
      );
    }
  }
}

class _InboxSection extends ConsumerWidget {
  const _InboxSection({required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final ctr = ref.read(appControllerProvider.notifier);
    final tasks = ctr.tasksFor(ListId.inbox, onlyVisible: app.hideCompleted);
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: DragTarget<String>(
        onWillAccept: (_) => true,
        onAccept: (taskId) => ctr.moveTaskToList(taskId, ListId.inbox),
        builder: (context, candidate, rejected) {
          final highlight = candidate.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: highlight ? kElectricBlue : Colors.white12, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Inbox (${tasks.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Collapse',
                      icon: const Icon(Icons.expand_more),
                      onPressed: () => ctr.toggleInboxCollapsed(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: Text(
                            'Add tasks with + then drag into a quadrant',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38),
                          ),
                        )
                      : ReorderableListView.builder(
                          shrinkWrap: true,
                          buildDefaultDragHandles: false,
                          padding: EdgeInsets.zero,
                          itemCount: tasks.length,
                          onReorder: (oldIndex, newIndex) => ctr.reorderWithinList(
                            listId: ListId.inbox,
                            oldIndex: oldIndex,
                            newIndex: newIndex,
                          ),
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return _buildReorderableItem(
                              key: ValueKey(task.id),
                              child: _DraggableTaskTile(
                                task: task,
                                number: index + 1,
                                onToggleDone: () => ctr.toggleCompleted(task.id),
                                onDelete: () => _deleteWithUndo(context, ref, task.id),
                                reorderHandleBuilder: (child) => ReorderableDragStartListener(
                                  index: index,
                                  child: child,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReorderableItem({required Key key, required Widget child}) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: child,
      ),
    );
  }

  void _deleteWithUndo(BuildContext context, WidgetRef ref, String id) async {
    final ctr = ref.read(appControllerProvider.notifier);
    await ctr.deleteTask(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => ctr.undo(),
          ),
        ),
      );
    }
  }
}

class _InboxHeaderCollapsed extends StatelessWidget {
  const _InboxHeaderCollapsed({required this.onExpand});
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text('Inbox', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          IconButton(
            tooltip: 'Expand',
            icon: const Icon(Icons.expand_less),
            onPressed: onExpand,
          ),
        ],
      ),
    );
  }
}

class _DraggableTaskTile extends StatelessWidget {
  const _DraggableTaskTile({
    required this.task,
    required this.number,
    required this.onToggleDone,
    required this.onDelete,
    required this.reorderHandleBuilder,
  });

  final Task task;
  final int number;
  final VoidCallback onToggleDone;
  final VoidCallback onDelete;
  final Widget Function(Widget child) reorderHandleBuilder;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<String>(
      data: task.id,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.9,
            child: TaskTile(
              task: task,
              number: number,
              onToggleDone: () {},
              onDelete: () {},
              moveDragDataBuilder: (child) => child,
              reorderHandleBuilder: (child) => child,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: TaskTile(
          task: task,
          number: number,
          onToggleDone: onToggleDone,
          onDelete: onDelete,
          moveDragDataBuilder: (child) => child,
          reorderHandleBuilder: reorderHandleBuilder,
        ),
      ),
      child: TaskTile(
        task: task,
        number: number,
        onToggleDone: onToggleDone,
        onDelete: onDelete,
        moveDragDataBuilder: (child) => child,
        reorderHandleBuilder: reorderHandleBuilder,
      ),
    );
  }
}
