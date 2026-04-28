import 'package:intl/intl.dart';

class AppConstants {
  // Expense Categories
  static const List<String> expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Travel',
    'Personal Care',
    'Groceries',
    'Rent',
    'Insurance',
    'Gifts & Donations',
    'Other',
  ];

  // Budget Period
  static const List<String> budgetPeriods = [
    'Daily',
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
  ];

  // Currency
  static const String currencySymbol = 'MK';
  static const String currencyCode = 'MWK';

  // Date Formats
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String formatDayMonth(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  // Currency Format
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$currencySymbol${formatter.format(amount)}';
  }

  static String formatCurrencyCompact(double amount) {
    if (amount >= 1000000) {
      return '$currencySymbol${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '$currencySymbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatCurrency(amount);
  }

  // Animations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Sizes
  static const double iconSizeSmall = 16;
  static const double iconSizeMedium = 24;
  static const double iconSizeLarge = 32;
  static const double iconSizeXl = 48;

  // Chart Colors (Vibrant colors - no purple)
  static const List<int> chartColors = [
    0xFF00BCD4, // Cyan
    0xFFFF5722, // Deep Orange
    0xFF4CAF50, // Green
    0xFFFFC107, // Amber
    0xFFF44336, // Red
    0xFF2196F3, // Blue
    0xFF009688, // Teal
    0xFFFF9800, // Orange
    0xFF8BC34A, // Light Green
    0xFFFFEB3B, // Yellow
    0xFF03A9F4, // Light Blue
    0xFFE91E63, // Pink
  ];

  // Progress Bar Colors
  static const int progressGreen = 0xFF4CAF50;
  static const int progressYellow = 0xFFFFC107;
  static const int progressOrange = 0xFFFF9800;
  static const int progressRed = 0xFFF44336;

  // Task Priority Icons
  static const Map<String, String> priorityIcons = {
    'low': '⬇',
    'medium': '▶',
    'high': '⬆',
    'urgent': '‼',
  };

  // Task Status Icons
  static const Map<String, String> statusIcons = {
    'todo': '○',
    'inProgress': '◐',
    'completed': '●',
  };
}
