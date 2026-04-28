import 'package:flutter/material.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planner'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Set your budget goals!'),
            ElevatedButton(
              onPressed: () {
                // Navigate to add budget screen
              },
              child: const Text('Add Budget'),
            ),
          ],
        ),
      ),
    );
  }
}
