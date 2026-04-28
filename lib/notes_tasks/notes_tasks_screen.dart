import 'package:flutter/material.dart';

class NotesTasksScreen extends StatelessWidget {
  const NotesTasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes & Tasks'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Manage your notes and tasks!'),
            ElevatedButton(
              onPressed: () {
                // Navigate to add note/task screen
              },
              child: const Text('Add Note/Task'),
            ),
          ],
        ),
      ),
    );
  }
}
