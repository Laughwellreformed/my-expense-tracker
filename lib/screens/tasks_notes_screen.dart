import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import '../providers/app_provider.dart';
import '../models/task.dart';
import '../models/note.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/task_form_dialog.dart';
import 'note_editor_screen.dart';

class TasksNotesScreen extends StatefulWidget {
  const TasksNotesScreen({super.key});

  @override
  State<TasksNotesScreen> createState() => _TasksNotesScreenState();
}

class _TasksNotesScreenState extends State<TasksNotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper function to extract plain text from rich text JSON
  String _extractPlainText(String content) {
    try {
      final List<dynamic> delta = jsonDecode(content);
      final StringBuffer plainText = StringBuffer();

      for (var item in delta) {
        if (item is Map<String, dynamic> && item['insert'] != null) {
          final insert = item['insert'];
          if (insert is String) {
            plainText.write(insert);
          }
        }
      }

      return plainText.toString().trim();
    } catch (e) {
      // If parsing fails, return content as is
      return content;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(AppTheme.spacingM),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.task_alt, size: 20),
                  text: 'Tasks',
                  height: 48,
                ),
                Tab(
                  icon: Icon(Icons.note, size: 20),
                  text: 'Notes',
                  height: 48,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildTasksTab(), _buildNotesTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddTaskDialog(context);
          } else {
            _showAddNoteDialog(context);
          }
        },
        child: const Icon(Icons.add),
      ).animate().scale(delay: 300.ms, duration: 300.ms),
    );
  }

  Widget _buildTasksTab() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_outlined, size: 64, color: AppTheme.lightGray),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'No tasks yet',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.mediumGray,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                TextButton(
                  onPressed: () => _showAddTaskDialog(context),
                  child: const Text('Create your first task'),
                ),
              ],
            ),
          );
        }

        final todoTasks = provider.tasks
            .where((t) => t.status == TaskStatus.todo)
            .toList();
        final inProgressTasks = provider.tasks
            .where((t) => t.status == TaskStatus.inProgress)
            .toList();
        final completedTasks = provider.tasks
            .where((t) => t.status == TaskStatus.completed)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.getOverdueTasks().isNotEmpty) ...[
                _buildTaskSection('Overdue', provider.getOverdueTasks(), true),
                const SizedBox(height: AppTheme.spacingL),
              ],
              if (inProgressTasks.isNotEmpty) ...[
                _buildTaskSection('In Progress', inProgressTasks, false),
                const SizedBox(height: AppTheme.spacingL),
              ],
              if (todoTasks.isNotEmpty) ...[
                _buildTaskSection('To Do', todoTasks, false),
                const SizedBox(height: AppTheme.spacingL),
              ],
              if (completedTasks.isNotEmpty)
                _buildTaskSection('Completed', completedTasks, false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskSection(String title, List<Task> tasks, bool isOverdue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: AppTheme.heading3),
            const SizedBox(width: AppTheme.spacingS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingS,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isOverdue
                    ? const Color(0xFFF44336)
                    : (Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkGray
                          : AppTheme.lightGray),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                tasks.length.toString(),
                style: AppTheme.caption.copyWith(
                  color: isOverdue
                      ? AppTheme.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        ...tasks.map((task) => _buildTaskCard(context, task)),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.urgent:
        priorityColor = const Color(0xFFF44336); // Red
        break;
      case TaskPriority.high:
        priorityColor = const Color(0xFFFF9800); // Orange
        break;
      case TaskPriority.medium:
        priorityColor = const Color(0xFFFFC107); // Amber
        break;
      case TaskPriority.low:
        priorityColor = const Color(0xFF4CAF50); // Green
        break;
    }

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingM),
        decoration: BoxDecoration(
          color: const Color(0xFFF44336),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        child: const Icon(Icons.delete, color: AppTheme.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Task'),
              content: const Text('Are you sure you want to delete this task?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Color(0xFFF44336)),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        context.read<AppProvider>().deleteTask(task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
        child: InkWell(
          onTap: () => _showEditTaskDialog(context, task),
          onLongPress: () => _showTaskOptions(context, task),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              border: Border(left: BorderSide(color: priorityColor, width: 4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Row(
                children: [
                  Checkbox(
                    value: task.status == TaskStatus.completed,
                    onChanged: (value) {
                      final updatedTask = value == true
                          ? task.copyWith(
                              status: TaskStatus.completed,
                              completedAt: DateTime.now(),
                            )
                          : task.copyWith(
                              status: TaskStatus.todo,
                              clearCompletedAt: true,
                            );
                      context.read<AppProvider>().updateTask(updatedTask);
                    },
                    activeColor: const Color(0xFF4CAF50),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: task.status == TaskStatus.completed
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.status == TaskStatus.completed
                                ? AppTheme.mediumGray
                                : null,
                          ),
                        ),
                        if (task.description != null) ...[
                          const SizedBox(height: AppTheme.spacingXs),
                          Text(
                            task.description!,
                            style: AppTheme.bodySmall.copyWith(
                              decoration: task.status == TaskStatus.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (task.completedAt != null) ...[
                          const SizedBox(height: AppTheme.spacingXs),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: const Color(0xFF4CAF50),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Completed ${AppConstants.formatDate(task.completedAt!)}',
                                style: AppTheme.bodySmall.copyWith(
                                  color: const Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (task.dueDate != null || task.tags.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacingS),
                          Row(
                            children: [
                              if (task.dueDate != null &&
                                  task.status != TaskStatus.completed) ...[
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: task.isOverdue
                                      ? const Color(0xFFF44336)
                                      : AppTheme.mediumGray,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppConstants.formatDate(task.dueDate!),
                                  style: AppTheme.bodySmall.copyWith(
                                    color: task.isOverdue
                                        ? const Color(0xFFF44336)
                                        : AppTheme.mediumGray,
                                  ),
                                ),
                              ],
                              if (task.tags.isNotEmpty && task.dueDate != null)
                                const SizedBox(width: AppTheme.spacingS),
                              if (task.tags.isNotEmpty)
                                Expanded(
                                  child: Wrap(
                                    spacing: 4,
                                    children: task.tags.take(2).map((tag) {
                                      return Chip(
                                        label: Text(
                                          tag,
                                          style: AppTheme.caption.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: const Color(
                                          0xFF9C27B0,
                                        ),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onPressed: () => _showTaskOptions(context, task),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesTab() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note_outlined, size: 64, color: AppTheme.lightGray),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'No notes yet',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.mediumGray,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                TextButton(
                  onPressed: () => _showAddNoteDialog(context),
                  child: const Text('Create your first note'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: provider.notes.length,
          itemBuilder: (context, index) {
            final note = provider.notes[index];
            return _buildNoteCard(context, note);
          },
        );
      },
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note) {
    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingM),
        decoration: BoxDecoration(
          color: const Color(0xFFF44336),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        child: const Icon(Icons.delete, color: AppTheme.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Note'),
              content: const Text('Are you sure you want to delete this note?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Color(0xFFF44336)),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        context.read<AppProvider>().deleteNote(note.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
        child: InkWell(
          onTap: () => _showEditNoteDialog(context, note),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (note.isPinned)
                      Icon(
                        Icons.push_pin,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    if (note.isPinned) const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Text(
                        note.title,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (note.content.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    _extractPlainText(note.content),
                    style: AppTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppTheme.spacingS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppConstants.formatDateTime(note.updatedAt),
                      style: AppTheme.bodySmall,
                    ),
                    if (note.tags.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: note.tags.take(2).map((tag) {
                          return Chip(
                            label: Text(
                              tag,
                              style: AppTheme.caption.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: const Color(0xFFFF9800),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0),
    );
  }

  void _showTaskOptions(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Task'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditTaskDialog(context, task);
                },
              ),
              ListTile(
                leading: Icon(
                  task.status == TaskStatus.completed
                      ? Icons.restart_alt
                      : Icons.check_circle,
                ),
                title: Text(
                  task.status == TaskStatus.completed
                      ? 'Mark as Incomplete'
                      : 'Mark as Complete',
                ),
                onTap: () {
                  Navigator.pop(context);
                  final updatedTask = task.status == TaskStatus.completed
                      ? task.copyWith(
                          status: TaskStatus.todo,
                          clearCompletedAt: true,
                        )
                      : task.copyWith(
                          status: TaskStatus.completed,
                          completedAt: DateTime.now(),
                        );
                  context.read<AppProvider>().updateTask(updatedTask);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFFF44336)),
                title: const Text(
                  'Delete Task',
                  style: TextStyle(color: Color(0xFFF44336)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.read<AppProvider>().deleteTask(task.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const TaskFormDialog());
  }

  void _showEditTaskDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskFormDialog(task: task),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NoteEditorScreen()),
    );
  }

  void _showEditNoteDialog(BuildContext context, Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteEditorScreen(note: note)),
    );
  }
}
