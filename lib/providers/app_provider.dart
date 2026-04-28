import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/task.dart';
import '../models/note.dart';
import '../models/organization.dart';
import '../models/notification.dart';
import '../models/account.dart';
import '../models/settings.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storage;
  final NotificationService _notificationService = NotificationService();

  AppProvider(this._storage) {
    _loadData();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    // Schedule daily and weekly summaries
    await _notificationService.scheduleDailyExpenseSummary();
    await _notificationService.scheduleWeeklyExpenseSummary();
  }

  List<Expense> _expenses = [];
  List<Budget> _budgets = [];
  List<Task> _tasks = [];
  List<Note> _notes = [];
  List<Organization> _organizations = [];
  List<String> _customCategories = [];
  List<AppNotification> _notifications = [];
  List<Account> _accounts = [];
  double _accountBalance = 0.0;
  bool _isLoading = false;
  Settings _settings = Settings();

  List<Expense> get expenses => _expenses;
  List<Budget> get budgets => _budgets;
  List<Task> get tasks => _tasks;
  List<Note> get notes => _notes;
  List<Organization> get organizations => _organizations;
  List<String> get customCategories => _customCategories;
  List<AppNotification> get notifications => _notifications;
  List<Account> get accounts => _accounts;
  double get accountBalance => _accountBalance;
  bool get isLoading => _isLoading;
  Settings get settings => _settings;

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    _expenses = await _storage.getAllExpenses();
    _budgets = await _storage.getAllBudgets();
    _tasks = await _storage.getAllTasks();
    _notes = await _storage.getAllNotes();
    _organizations = await _storage.getAllOrganizations();
    _customCategories = await _storage.getCustomCategories();
    _notifications = await _storage.getAllNotifications();
    _accounts = await _storage.getAllAccounts();
    _accountBalance = await _storage.getAccountBalance();
    _settings = await _storage.getSettings();

    _isLoading = false;
    notifyListeners();

    // Apply daily reminder settings
    if (_settings.dailyReminderEnabled) {
      await _notificationService.scheduleDailyExpenseReminder(
        hour: _settings.reminderHour,
        minute: _settings.reminderMinute,
      );
    }
  }

  // Expense Methods
  Future<void> addExpense(Expense expense) async {
    await _storage.saveExpense(expense);

    // Deduct from account balance for both personal expenses and company refunds
    await deductFromAccount(expense.amount);

    // Reload expenses and budgets
    _expenses = await _storage.getAllExpenses();
    _budgets = await _storage.getAllBudgets();

    // Reload organizations to update refund totals
    if (expense.type == ExpenseType.companyRefund) {
      _organizations = await _storage.getAllOrganizations();
    }

    // Check for alerts and create notifications
    await _checkAndCreateNotifications();

    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    // Find the old expense to calculate balance adjustment
    final oldExpense = _expenses.firstWhere((e) => e.id == expense.id);

    await _storage.saveExpense(expense);

    // Adjust account balance based on the difference
    final amountDifference = expense.amount - oldExpense.amount;

    if (amountDifference != 0) {
      if (amountDifference > 0) {
        // New amount is higher, deduct the difference
        await deductFromAccount(amountDifference);
      } else {
        // New amount is lower, credit back the difference
        await addToAccount(amountDifference.abs());
      }
    }

    // If expense type changed, handle the full amount adjustment
    if (oldExpense.type != expense.type) {
      // Credit back the old expense
      await addToAccount(oldExpense.amount);
      // Deduct the new expense
      await deductFromAccount(expense.amount);
    }

    _expenses = await _storage.getAllExpenses();
    _budgets = await _storage.getAllBudgets();
    // Reload organizations to update refund totals
    _organizations = await _storage.getAllOrganizations();

    // Check for alerts
    await _checkAndCreateNotifications();

    notifyListeners();
  }

  Future<void> deleteExpense(String id, {bool creditAccount = true}) async {
    // Find the expense to check if we need to credit back
    final expense = _expenses.firstWhere((e) => e.id == id);

    await _storage.deleteExpense(id);

    // Credit back to account balance based on expense type
    if (expense.type == ExpenseType.personal && creditAccount) {
      // For personal expenses, only credit if user chose to
      await addToAccount(expense.amount);
    } else if (expense.type == ExpenseType.companyRefund &&
        !expense.isRefunded) {
      // For company expenses, only credit if not yet refunded
      await addToAccount(expense.amount);
    }

    _expenses = await _storage.getAllExpenses();
    _budgets = await _storage.getAllBudgets();
    // Reload organizations to update refund totals
    _organizations = await _storage.getAllOrganizations();
    notifyListeners();
  }

  // Budget Methods
  Future<void> addBudget(Budget budget) async {
    // Calculate initial spent amount from existing personal expenses
    final matchingExpenses = _expenses.where(
      (expense) =>
          expense.type == ExpenseType.personal &&
          expense.category == budget.category &&
          expense.date.isAfter(
            budget.startDate.subtract(const Duration(days: 1)),
          ) &&
          expense.date.isBefore(budget.endDate.add(const Duration(days: 1))),
    );

    final totalSpent = matchingExpenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );

    // Create budget with calculated spent amount
    final budgetWithSpent = budget.copyWith(spent: totalSpent);

    await _storage.saveBudget(budgetWithSpent);
    _budgets = await _storage.getAllBudgets();
    notifyListeners();
  }

  Future<void> updateBudget(Budget budget) async {
    await _storage.saveBudget(budget);
    _budgets = await _storage.getAllBudgets();
    notifyListeners();
  }

  Future<void> deleteBudget(String id) async {
    await _storage.deleteBudget(id);
    _budgets = await _storage.getAllBudgets();
    notifyListeners();
  }

  // Task Methods
  Future<void> addTask(Task task) async {
    await _storage.saveTask(task);
    _tasks = await _storage.getAllTasks();

    // Schedule notification if task has due date
    if (task.dueDate != null) {
      await _notificationService.scheduleTaskReminder(
        taskId: task.id,
        taskTitle: task.title,
        dueDate: task.dueDate!,
      );
    }

    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    await _storage.saveTask(task);
    _tasks = await _storage.getAllTasks();

    // Cancel old notifications and reschedule if needed
    await _notificationService.cancelNotification(task.id.hashCode);
    await _notificationService.cancelNotification(task.id.hashCode + 1);

    if (task.dueDate != null && task.status != 'completed') {
      await _notificationService.scheduleTaskReminder(
        taskId: task.id,
        taskTitle: task.title,
        dueDate: task.dueDate!,
      );
    }

    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    await _storage.deleteTask(id);
    _tasks = await _storage.getAllTasks();

    // Cancel task notifications
    await _notificationService.cancelNotification(id.hashCode);
    await _notificationService.cancelNotification(id.hashCode + 1);

    notifyListeners();
  }

  // Note Methods
  Future<void> addNote(Note note) async {
    await _storage.saveNote(note);
    _notes = await _storage.getAllNotes();
    notifyListeners();
  }

  Future<void> updateNote(Note note) async {
    await _storage.saveNote(note);
    _notes = await _storage.getAllNotes();
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    await _storage.deleteNote(id);
    _notes = await _storage.getAllNotes();
    notifyListeners();
  }

  // Organization Methods
  Future<void> addOrganization(Organization org) async {
    await _storage.saveOrganization(org);
    _organizations = await _storage.getAllOrganizations();
    notifyListeners();
  }

  Future<void> updateOrganization(Organization org) async {
    await _storage.saveOrganization(org);
    _organizations = await _storage.getAllOrganizations();
    notifyListeners();
  }

  Future<void> deleteOrganization(String id) async {
    await _storage.deleteOrganization(id);
    _organizations = await _storage.getAllOrganizations();
    notifyListeners();
  }

  // Analytics
  double get totalExpenses {
    return _expenses
        .where(
          (e) =>
              e.type == ExpenseType.personal ||
              (e.type == ExpenseType.companyRefund && !e.isRefunded),
        )
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  double get totalPersonalExpenses {
    return _expenses
        .where((e) => e.type == ExpenseType.personal)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  double get totalCompanyRefunds {
    return _expenses
        .where((e) => e.type == ExpenseType.companyRefund && !e.isRefunded)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  double get totalRefundedAmount {
    return _expenses
        .where((e) => e.type == ExpenseType.companyRefund && e.isRefunded)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  double get totalBudgetAmount {
    return _budgets.fold(0, (sum, budget) => sum + budget.amount);
  }

  double get totalBudgetSpent {
    return _budgets.fold(0, (sum, budget) => sum + budget.spent);
  }

  int get completedTasksCount {
    return _tasks.where((t) => t.status == TaskStatus.completed).length;
  }

  int get pendingTasksCount {
    return _tasks.where((t) => t.status != TaskStatus.completed).length;
  }

  Map<String, double> getExpensesByCategory() {
    final map = <String, double>{};
    for (var expense in _expenses) {
      map[expense.category] = (map[expense.category] ?? 0) + expense.amount;
    }
    return map;
  }

  List<Expense> getExpensesByType(ExpenseType type) {
    return _expenses.where((e) => e.type == type).toList();
  }

  List<Expense> getExpensesByDateRange(DateTime start, DateTime end) {
    return _expenses
        .where(
          (e) =>
              e.date.isAfter(start.subtract(const Duration(days: 1))) &&
              e.date.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
  }

  List<Budget> getActiveBudgets() {
    final now = DateTime.now();
    return _budgets
        .where((b) => b.startDate.isBefore(now) && b.endDate.isAfter(now))
        .toList();
  }

  List<Task> getOverdueTasks() {
    return _tasks.where((t) => t.isOverdue).toList();
  }

  // Account Balance Methods
  Future<void> addToAccount(double amount) async {
    await _storage.addToAccountBalance(amount);
    _accountBalance = await _storage.getAccountBalance();

    // Also update the Main Account balance
    final mainAccount = _accounts.firstWhere(
      (a) => a.type == AccountType.main,
      orElse: () => Account(
        id: 'main',
        name: 'Main Account',
        type: AccountType.main,
        balance: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final updatedMainAccount = mainAccount.copyWith(
      balance: _accountBalance,
      updatedAt: DateTime.now(),
    );
    await _storage.saveAccount(updatedMainAccount);
    _accounts = await _storage.getAllAccounts();

    notifyListeners();
  }

  Future<void> deductFromAccount(double amount) async {
    await _storage.deductFromAccountBalance(amount);
    _accountBalance = await _storage.getAccountBalance();

    // Also update the Main Account balance
    final mainAccount = _accounts.firstWhere(
      (a) => a.type == AccountType.main,
      orElse: () => Account(
        id: 'main',
        name: 'Main Account',
        type: AccountType.main,
        balance: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final updatedMainAccount = mainAccount.copyWith(
      balance: _accountBalance,
      updatedAt: DateTime.now(),
    );
    await _storage.saveAccount(updatedMainAccount);
    _accounts = await _storage.getAllAccounts();

    notifyListeners();
  }

  Future<void> setAccountBalance(double amount) async {
    await _storage.setAccountBalance(amount);
    _accountBalance = await _storage.getAccountBalance();
    notifyListeners();
  }

  // Custom Categories Methods
  Future<void> addCustomCategory(String category) async {
    await _storage.addCustomCategory(category);
    _customCategories = await _storage.getCustomCategories();
    notifyListeners();
  }

  Future<void> removeCustomCategory(String category) async {
    await _storage.removeCustomCategory(category);
    _customCategories = await _storage.getCustomCategories();
    notifyListeners();
  }

  // Mark expense as refunded
  Future<void> markExpenseAsRefunded(
    String expenseId,
    String organizationId,
  ) async {
    final expense = _expenses.firstWhere((e) => e.id == expenseId);
    final org = _organizations.firstWhere((o) => o.id == organizationId);

    // Update expense to mark as refunded
    final updatedExpense = Expense(
      id: expense.id,
      title: expense.title,
      category: expense.category,
      amount: expense.amount,
      date: expense.date,
      type: expense.type,
      organizationId: expense.organizationId,
      organizationName: expense.organizationName,
      description: expense.description,
      receiptUrl: expense.receiptUrl,
      isRefunded: true,
    );
    await _storage.saveExpense(updatedExpense);

    // Update organization
    final updatedOrg = org.copyWith(
      totalRefunded: org.totalRefunded + expense.amount,
      refundedExpenseIds: [...org.refundedExpenseIds, expenseId],
    );
    await _storage.saveOrganization(updatedOrg);

    // Credit account
    await addToAccount(expense.amount);

    // Reload data
    _expenses = await _storage.getAllExpenses();
    _organizations = await _storage.getAllOrganizations();
    notifyListeners();
  }

  // Undo marking expense as refunded
  Future<void> unmarkExpenseAsRefunded(
    String expenseId,
    String organizationId,
  ) async {
    final expense = _expenses.firstWhere((e) => e.id == expenseId);
    final org = _organizations.firstWhere((o) => o.id == organizationId);

    // Update expense to unmark as refunded
    final updatedExpense = Expense(
      id: expense.id,
      title: expense.title,
      category: expense.category,
      amount: expense.amount,
      date: expense.date,
      type: expense.type,
      organizationId: expense.organizationId,
      organizationName: expense.organizationName,
      description: expense.description,
      receiptUrl: expense.receiptUrl,
      isRefunded: false,
    );
    await _storage.saveExpense(updatedExpense);

    // Update organization
    final updatedRefundedIds = List<String>.from(org.refundedExpenseIds)
      ..remove(expenseId);
    final updatedOrg = org.copyWith(
      totalRefunded: org.totalRefunded - expense.amount,
      refundedExpenseIds: updatedRefundedIds,
    );
    await _storage.saveOrganization(updatedOrg);

    // Deduct from account
    await deductFromAccount(expense.amount);

    // Reload data
    _expenses = await _storage.getAllExpenses();
    _organizations = await _storage.getAllOrganizations();
    notifyListeners();
  }

  // Check if overspending
  bool isOverspending() {
    // Check if account balance is negative
    if (_accountBalance < 0) return true;

    // Check active budgets
    final activeBudgets = getActiveBudgets();
    for (final budget in activeBudgets) {
      final spent = getSpentOnBudget(budget);
      if (spent > budget.amount) return true;
    }

    return false;
  }

  // Get overspending details
  String? getOverspendingMessage() {
    if (_accountBalance < 0) {
      return 'Your account balance is negative! You\'re overspending by MK ${AppConstants.formatCurrency(_accountBalance.abs())}.';
    }

    final activeBudgets = getActiveBudgets();
    for (final budget in activeBudgets) {
      final spent = getSpentOnBudget(budget);
      if (spent > budget.amount) {
        final overspent = spent - budget.amount;
        return 'You\'ve exceeded your ${budget.category} budget by ${overspent.toStringAsFixed(2)}!';
      }
    }

    // Check if account balance is low (less than 20% of average monthly expenses)
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthlyExpenses = getExpensesByDateRange(monthStart, now)
        .where((e) => e.type == ExpenseType.personal)
        .fold<double>(0, (sum, e) => sum + e.amount);

    if (_accountBalance > 0 && _accountBalance < monthlyExpenses * 0.2) {
      return 'Warning: Your account balance is low. Consider reducing expenses.';
    }

    return null;
  }

  double getSpentOnBudget(Budget budget) {
    return _expenses
        .where(
          (e) =>
              e.type == ExpenseType.personal &&
              e.category == budget.category &&
              e.date.isAfter(
                budget.startDate.subtract(const Duration(days: 1)),
              ) &&
              e.date.isBefore(budget.endDate.add(const Duration(days: 1))),
        )
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  // Notification Methods
  Future<void> addNotification(AppNotification notification) async {
    await _storage.saveNotification(notification);
    _notifications = await _storage.getAllNotifications();
    notifyListeners();
  }

  Future<void> markNotificationAsRead(String id) async {
    await _storage.markNotificationAsRead(id);
    _notifications = await _storage.getAllNotifications();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    await _storage.deleteNotification(id);
    _notifications = await _storage.getAllNotifications();
    notifyListeners();
  }

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  AppNotification? get mostRecentNotification =>
      _notifications.isNotEmpty ? _notifications.first : null;

  // Check conditions and create notifications
  Future<void> _checkAndCreateNotifications() async {
    final now = DateTime.now();

    // Check for negative account balance
    if (_accountBalance < 0) {
      final notification = AppNotification(
        id: 'negative_balance_${now.millisecondsSinceEpoch}',
        title: 'Negative Account Balance',
        message:
            'Your account balance is negative! You\'re overspending by ${AppConstants.formatCurrency(_accountBalance.abs())}.',
        type: NotificationType.accountNegative,
        timestamp: now,
      );
      await _storage.saveNotification(notification);
      _notifications = await _storage.getAllNotifications();

      // Trigger local notification
      await _notificationService.showNegativeBalanceAlert(
        balance: _accountBalance,
      );
      return;
    }

    // Check for budget overspending
    final activeBudgets = getActiveBudgets();
    for (final budget in activeBudgets) {
      final spent = getSpentOnBudget(budget);
      if (spent > budget.amount) {
        final overspent = spent - budget.amount;
        final notification = AppNotification(
          id: 'budget_overspent_${budget.id}_${now.millisecondsSinceEpoch}',
          title: 'Budget Exceeded',
          message:
              'You\'ve exceeded your ${budget.category} budget by ${AppConstants.formatCurrency(overspent)}!',
          type: NotificationType.budgetOverspent,
          timestamp: now,
        );
        await _storage.saveNotification(notification);
        _notifications = await _storage.getAllNotifications();

        // Trigger local notification
        await _notificationService.showBudgetAlert(
          category: budget.category,
          spent: spent,
          limit: budget.amount,
        );
        return; // Only create one notification at a time
      }
    }

    // Check for low balance
    final monthStart = DateTime(now.year, now.month, 1);
    final monthlyExpenses = getExpensesByDateRange(monthStart, now)
        .where((e) => e.type == ExpenseType.personal)
        .fold<double>(0, (sum, e) => sum + e.amount);

    if (_accountBalance > 0 &&
        monthlyExpenses > 0 &&
        _accountBalance < monthlyExpenses * 0.2) {
      final notification = AppNotification(
        id: 'low_balance_${now.millisecondsSinceEpoch}',
        title: 'Low Account Balance',
        message:
            'Warning: Your account balance is low. Consider reducing expenses.',
        type: NotificationType.lowBalance,
        timestamp: now,
      );
      await _storage.saveNotification(notification);
      _notifications = await _storage.getAllNotifications();

      // Trigger local notification
      await _notificationService.showLowBalanceAlert(
        balance: _accountBalance,
        threshold: monthlyExpenses * 0.2,
      );
    }
  }

  // Account Methods
  Future<void> addAccount(Account account) async {
    await _storage.saveAccount(account);
    _accounts = await _storage.getAllAccounts();
    notifyListeners();
  }

  Future<void> updateAccount(Account account) async {
    await _storage.saveAccount(account);
    _accounts = await _storage.getAllAccounts();
    notifyListeners();
  }

  Future<void> deleteAccount(String id) async {
    // Don't allow deleting main account
    final account = await _storage.getAccount(id);
    if (account?.type == AccountType.main) {
      throw Exception('Cannot delete main account');
    }

    await _storage.deleteAccount(id);
    _accounts = await _storage.getAllAccounts();
    notifyListeners();
  }

  Future<void> transferMoney(
    String fromAccountId,
    String toAccountId,
    double amount,
    String note,
  ) async {
    await _storage.transferBetweenAccounts(
      fromAccountId,
      toAccountId,
      amount,
      note,
    );
    _accounts = await _storage.getAllAccounts();

    // Update main account balance display
    final mainAccount = _accounts.firstWhere((a) => a.type == AccountType.main);
    _accountBalance = mainAccount.balance;

    notifyListeners();
  }

  Account? get mainAccount => _accounts.firstWhere(
    (a) => a.type == AccountType.main,
    orElse: () => Account(
      id: 'main',
      name: 'Main Account',
      type: AccountType.main,
      balance: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  );

  // Backup & Restore
  Future<void> restoreFromBackup(Map<String, dynamic> backupData) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Clear existing data
      await _storage.clearAllData();

      // Restore expenses
      if (backupData['expenses'] != null) {
        final expensesList = (backupData['expenses'] as List)
            .map((e) => Expense.fromJson(e as Map<String, dynamic>))
            .toList();
        for (var expense in expensesList) {
          await _storage.saveExpense(expense);
        }
      }

      // Restore budgets
      if (backupData['budgets'] != null) {
        final budgetsList = (backupData['budgets'] as List)
            .map((b) => Budget.fromJson(b as Map<String, dynamic>))
            .toList();
        for (var budget in budgetsList) {
          await _storage.saveBudget(budget);
        }
      }

      // Restore tasks
      if (backupData['tasks'] != null) {
        final tasksList = (backupData['tasks'] as List)
            .map((t) => Task.fromJson(t as Map<String, dynamic>))
            .toList();
        for (var task in tasksList) {
          await _storage.saveTask(task);
        }
      }

      // Restore notes
      if (backupData['notes'] != null) {
        final notesList = (backupData['notes'] as List)
            .map((n) => Note.fromJson(n as Map<String, dynamic>))
            .toList();
        for (var note in notesList) {
          await _storage.saveNote(note);
        }
      }

      // Restore organizations
      if (backupData['organizations'] != null) {
        final orgsList = (backupData['organizations'] as List)
            .map((o) => Organization.fromJson(o as Map<String, dynamic>))
            .toList();
        for (var org in orgsList) {
          await _storage.saveOrganization(org);
        }
      }

      // Restore accounts
      if (backupData['accounts'] != null) {
        final accountsList = (backupData['accounts'] as List)
            .map((a) => Account.fromJson(a as Map<String, dynamic>))
            .toList();
        for (var account in accountsList) {
          await _storage.saveAccount(account);
        }
      }

      // Restore custom categories
      if (backupData['customCategories'] != null) {
        final categories = List<String>.from(backupData['customCategories']);
        for (var category in categories) {
          await _storage.addCustomCategory(category);
        }
      }

      // Restore account balance
      if (backupData['accountBalance'] != null) {
        await _storage.setAccountBalance(
          (backupData['accountBalance'] as num).toDouble(),
        );
      }

      // Reload all data
      await _loadData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Settings Methods
  Future<void> toggleDailyReminder(bool enabled) async {
    _settings = _settings.copyWith(dailyReminderEnabled: enabled);
    await _storage.saveSettings(_settings);

    if (enabled) {
      await _notificationService.scheduleDailyExpenseReminder(
        hour: _settings.reminderHour,
        minute: _settings.reminderMinute,
      );
    } else {
      await _notificationService.cancelDailyExpenseReminder();
    }

    notifyListeners();
  }

  Future<void> setReminderTime(int hour, int minute) async {
    _settings = _settings.copyWith(reminderHour: hour, reminderMinute: minute);
    await _storage.saveSettings(_settings);

    // Reschedule notification with new time if enabled
    if (_settings.dailyReminderEnabled) {
      await _notificationService.cancelDailyExpenseReminder();
      await _notificationService.scheduleDailyExpenseReminder(
        hour: hour,
        minute: minute,
      );
    }

    notifyListeners();
  }

  // Test daily reminder
  Future<void> testDailyReminder() async {
    await _notificationService.showNotification(
      id: 9999,
      title: '💰 Expense Reminder (Test)',
      body: 'Don\'t forget to record your expenses today!',
    );
  }

  // Get pending notifications
  Future<List<dynamic>> getPendingNotifications() async {
    return await _notificationService.getPendingNotifications();
  }
}
