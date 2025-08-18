import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/models/task.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.number,
    required this.onToggleDone,
    required this.onDelete,
    required this.moveDragDataBuilder,
    required this.reorderHandleBuilder,
    this.compact = false,
  });

  final Task task;
  final int number;
  final VoidCallback onToggleDone;
  final VoidCallback onDelete;
  final Widget Function(Widget child) moveDragDataBuilder; // wraps tile for cross-list drag
  final Widget Function(Widget child) reorderHandleBuilder; // wraps drag handle
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          color: task.isCompleted ? Colors.white60 : Colors.white,
        );

    final content = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          // Number
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12),
            ),
            child: Text('$number', style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(width: 10),
          // Title
          Expanded(
            child: GestureDetector(
              onTap: onToggleDone,
              child: Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: titleStyle),
            ),
          ),
          const SizedBox(width: 8),
          // Delete
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white60),
            onPressed: onDelete,
          ),
          // Reorder handle (within list)
          reorderHandleBuilder(
            Icon(Icons.drag_handle, size: 22, color: Colors.white54),
          ),
        ],
      ),
    );

    // Wrap for cross-list drag using long-press on tile body (not interfering reorder handle)
    return moveDragDataBuilder(content);
  }
}
