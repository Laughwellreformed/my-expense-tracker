import 'package:flutter/material.dart';
import '../models/expense.dart';

class ExpenseScreen extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseScreen({Key? key, required this.expenses}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
      ),
      body: ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return ListTile(
            title: Text(expense.category),
            subtitle: Text(expense.date.toIso8601String()),
            trailing: Text('\u20B9${expense.amount.toStringAsFixed(2)}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add expense screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
