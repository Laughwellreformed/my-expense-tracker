import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class TaskFormDialog extends StatefulWidget {
  final Task? task;

  const TaskFormDialog({super.key, this.task});

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TaskPriority _selectedPriority;
  late TaskStatus _selectedStatus;
  DateTime? _dueDate;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _selectedPriority = widget.task?.priority ?? TaskPriority.medium;
    _selectedStatus = widget.task?.status ?? TaskStatus.todo;
    _dueDate = widget.task?.dueDate;
    _tags = List.from(widget.task?.tags ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.task_alt,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.task == null ? 'Add Task' : 'Edit Task',
                        style: AppTheme.heading2,
                      ),
                    ),
                    if (widget.task != null)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          context.read<AppProvider>().deleteTask(
                            widget.task!.id,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Task deleted'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingL),

                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'What needs to be done?',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Add more details',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Priority Selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Priority', style: AppTheme.bodyMedium),
                    const SizedBox(height: AppTheme.spacingS),
                    Row(
                      children: TaskPriority.values.map((priority) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: AppTheme.spacingS,
                            ),
                            child: _buildPriorityButton(priority),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Status Selector
                if (widget.task != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status', style: AppTheme.bodyMedium),
                      const SizedBox(height: AppTheme.spacingS),
                      SegmentedButton<TaskStatus>(
                        segments: const [
                          ButtonSegment(
                            value: TaskStatus.todo,
                            label: Text(
                              'To Do',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          ButtonSegment(
                            value: TaskStatus.inProgress,
                            label: Text(
                              'In Progress',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          ButtonSegment(
                            value: TaskStatus.completed,
                            label: Text('Done', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                        selected: {_selectedStatus},
                        onSelectionChanged: (Set<TaskStatus> newSelection) {
                          setState(() => _selectedStatus = newSelection.first);
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                    ],
                  ),

                // Due Date Selector
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Due Date (Optional)',
                    style: AppTheme.bodyMedium,
                  ),
                  subtitle: _dueDate != null
                      ? Text(AppConstants.formatDate(_dueDate!))
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => setState(() => _dueDate = null),
                        ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _dueDate = date);
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacingL),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    ElevatedButton(
                      onPressed: _saveTask,
                      child: Text(widget.task == null ? 'Add' : 'Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityButton(TaskPriority priority) {
    final isSelected = _selectedPriority == priority;
    String label;

    switch (priority) {
      case TaskPriority.low:
        label = 'Low';
        break;
      case TaskPriority.medium:
        label = 'Med';
        break;
      case TaskPriority.high:
        label = 'High';
        break;
      case TaskPriority.urgent:
        label = 'Urgent';
        break;
    }

    return InkWell(
      onTap: () => setState(() => _selectedPriority = priority),
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlack : AppTheme.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlack : AppTheme.lightGray,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.bodySmall.copyWith(
            color: isSelected ? AppTheme.white : AppTheme.primaryBlack,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<AppProvider>();

      final task = Task(
        id: widget.task?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        priority: _selectedPriority,
        status: _selectedStatus,
        dueDate: _dueDate,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        completedAt: _selectedStatus == TaskStatus.completed
            ? DateTime.now()
            : null,
        tags: _tags,
      );

      if (widget.task == null) {
        provider.addTask(task);
      } else {
        provider.updateTask(task);
      }

      Navigator.pop(context);
    }
  }
}
