import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../models/note.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late QuillController _quillController;
  late bool _isPinned;
  List<String> _tags = [];
  late DateTime _createdAt;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _isPinned = widget.note?.isPinned ?? false;
    _tags = List.from(widget.note?.tags ?? []);
    _createdAt = widget.note?.createdAt ?? DateTime.now();

    // Initialize Quill editor with content or empty
    if (widget.note != null) {
      try {
        final contentJson = jsonDecode(widget.note!.content) as List;
        _quillController = QuillController(
          document: Document.fromJson(contentJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // Fallback for plain text
        _quillController = QuillController.basic();
        _quillController.document.insert(0, widget.note!.content);
      }
    } else {
      _quillController = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a title'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final content = jsonEncode(_quillController.document.toDelta().toJson());

    if (widget.note == null) {
      // Create new note
      final newNote = Note(
        id: const Uuid().v4(),
        title: _titleController.text,
        content: content,
        createdAt: _createdAt,
        updatedAt: DateTime.now(),
        tags: _tags,
        isPinned: _isPinned,
      );
      context.read<AppProvider>().addNote(newNote);
    } else {
      // Update existing note
      final updatedNote = widget.note!.copyWith(
        title: _titleController.text,
        content: content,
        updatedAt: DateTime.now(),
        tags: _tags,
        isPinned: _isPinned,
      );
      context.read<AppProvider>().updateNote(updatedNote);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.note == null ? 'Note created' : 'Note updated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Title Input
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
          ),

          // Editor Area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: QuillEditor.basic(controller: _quillController),
            ),
          ),

          // Rich Text Toolbar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.format_bold),
                      onPressed: () {
                        _quillController.formatSelection(Attribute.bold);
                      },
                      iconSize: 18,
                      tooltip: 'Bold',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_italic),
                      onPressed: () {
                        _quillController.formatSelection(Attribute.italic);
                      },
                      iconSize: 18,
                      tooltip: 'Italic',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_underlined),
                      onPressed: () {
                        _quillController.formatSelection(Attribute.underline);
                      },
                      iconSize: 18,
                      tooltip: 'Underline',
                    ),
                    const VerticalDivider(width: 4),
                    IconButton(
                      icon: const Icon(Icons.format_list_bulleted),
                      onPressed: () {
                        _quillController.formatSelection(Attribute.ul);
                      },
                      iconSize: 18,
                      tooltip: 'Bullet List',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_list_numbered),
                      onPressed: () {
                        _quillController.formatSelection(Attribute.ol);
                      },
                      iconSize: 18,
                      tooltip: 'Numbered List',
                    ),
                    const VerticalDivider(width: 4),
                    IconButton(
                      icon: const Icon(Icons.format_quote),
                      onPressed: () {
                        _quillController.formatSelection(Attribute.blockQuote);
                      },
                      iconSize: 18,
                      tooltip: 'Quote',
                    ),
                    IconButton(
                      icon: const Icon(Icons.code),
                      onPressed: () {
                        _quillController.formatSelection(Attribute.inlineCode);
                      },
                      iconSize: 18,
                      tooltip: 'Code',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Note Actions and Info Footer
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              children: [
                // Info row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.note == null
                            ? 'New note'
                            : 'Updated ${AppConstants.formatDateTime(widget.note!.updatedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (_tags.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: _tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            onDeleted: () {
                              setState(() => _tags.remove(tag));
                            },
                            labelStyle: const TextStyle(fontSize: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          );
                        }).toList(),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                // Action buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            color: _isPinned
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          onPressed: () =>
                              setState(() => _isPinned = !_isPinned),
                          tooltip: _isPinned ? 'Unpin note' : 'Pin note',
                        ),
                        if (widget.note != null)
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Note'),
                                  content: const Text(
                                    'Are you sure you want to delete this note?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context.read<AppProvider>().deleteNote(
                                          widget.note!.id,
                                        );
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            tooltip: 'Delete note',
                          ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: _saveNote,
                      icon: const Icon(Icons.check),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
