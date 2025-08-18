import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Guide')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('How Priority Matrix works', style: t.headlineSmall),
          const SizedBox(height: 12),
          Text(
            '• Add tasks using the + button. New tasks appear in Inbox.\n'
            '• Drag tasks from Inbox into any quadrant.\n'
            '• Reorder tasks within a quadrant (use the drag handle ⋮⋮).\n'
            '• Long-press on a task to drag it between quadrants.\n'
            '• Tap a task to mark it done/undone.\n'
            '• Hide/Unhide completed using the eye icon.\n'
            '• Undo/Redo any action from the top bar.\n',
            style: t.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text('Quadrants', style: t.titleLarge),
          const SizedBox(height: 8),
          Text(
            'High Impact × Easy (Q1)\n'
            'High Impact × Difficult (Q2)\n'
            'Low Impact × Easy (Q3)\n'
            'Low Impact × Difficult (Q4)\n',
            style: t.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text('Tips', style: t.titleLarge),
          const SizedBox(height: 8),
          Text(
            '• Keep titles short and actionable.\n'
            '• Revisit the matrix daily, hide completed to focus.\n'
            '• Use Inbox as a quick capture, then drag to prioritize.',
            style: t.bodyLarge,
          ),
        ],
      ),
    );
  }
}
