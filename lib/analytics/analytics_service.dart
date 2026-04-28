import 'package:hive/hive.dart';
import '../models/expense.dart';

class AnalyticsService {
  final Box _expenseBox;

  AnalyticsService(this._expenseBox);

  // Get expenses for a specific period
  List<Expense> getExpensesForPeriod(DateTime start, DateTime end) {
    final expenses = <Expense>[];
    for (var key in _expenseBox.keys) {
      final json = _expenseBox.get(key);
      if (json != null) {
        try {
          final expense = Expense.fromJson(Map<String, dynamic>.from(json));
          if (expense.date.isAfter(start.subtract(const Duration(days: 1))) &&
              expense.date.isBefore(end.add(const Duration(days: 1)))) {
            expenses.add(expense);
          }
        } catch (e) {
          // Skip invalid entries
        }
      }
    }
    return expenses;
  }

  // Calculate daily trends
  Map<String, double> calculateDailyTrends() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final expenses = getExpensesForPeriod(startOfDay, today);
    return _calculateTrends(expenses);
  }

  // Calculate weekly trends
  Map<String, double> calculateWeeklyTrends() {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final expenses = getExpensesForPeriod(startOfWeek, today);
    return _calculateTrends(expenses);
  }

  // Calculate monthly trends
  Map<String, double> calculateMonthlyTrends() {
    final today = DateTime.now();
    final startOfMonth = DateTime(today.year, today.month, 1);
    final expenses = getExpensesForPeriod(startOfMonth, today);
    return _calculateTrends(expenses);
  }

  // Calculate annual trends
  Map<String, double> calculateAnnualTrends() {
    final today = DateTime.now();
    final startOfYear = DateTime(today.year, 1, 1);
    final expenses = getExpensesForPeriod(startOfYear, today);
    return _calculateTrends(expenses);
  }

  // Calculate bi-annual trends
  Map<String, double> calculateBiAnnualTrends() {
    final today = DateTime.now();
    final startOfHalfYear = today.month <= 6
        ? DateTime(today.year, 1, 1)
        : DateTime(today.year, 7, 1);
    final expenses = getExpensesForPeriod(startOfHalfYear, today);
    return _calculateTrends(expenses);
  }

  // Helper: Calculate trends by category
  Map<String, double> _calculateTrends(List<Expense> expenses) {
    final trends = <String, double>{};
    for (var expense in expenses) {
      trends[expense.category] =
          (trends[expense.category] ?? 0) + expense.amount;
    }
    return trends;
  }

  // Get average daily spending
  double getAverageDailySpending(int days) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    final expenses = getExpensesForPeriod(start, now);
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    return days > 0 ? total / days : 0;
  }

  // Get spending comparison (this month vs last month)
  Map<String, double> getMonthComparison() {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = thisMonthStart.subtract(const Duration(days: 1));

    final thisMonth = getExpensesForPeriod(thisMonthStart, now);
    final lastMonth = getExpensesForPeriod(lastMonthStart, lastMonthEnd);

    return {
      'thisMonth': thisMonth.fold(0.0, (sum, e) => sum + e.amount),
      'lastMonth': lastMonth.fold(0.0, (sum, e) => sum + e.amount),
    };
  }

  // Check if same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
