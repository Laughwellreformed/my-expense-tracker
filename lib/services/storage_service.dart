import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/task.dart';
import '../models/note.dart';
import '../models/organization.dart';
import '../models/notification.dart';
import '../models/account.dart';
import '../models/settings.dart';

class StorageService {
  late Box _expenseBox;
  late Box _budgetBox;
  late Box _taskBox;
  late Box _noteBox;
  late Box _orgBox;
  late Box _settingsBox;
  late Box _notificationBox;
  late Box _accountBox;
  late Box _accountTransactionBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _expenseBox = await Hive.openBox('expenses');
    _budgetBox = await Hive.openBox('budgets');
    _taskBox = await Hive.openBox('tasks');
    _noteBox = await Hive.openBox('notes');
    _orgBox = await Hive.openBox('organizations');
    _settingsBox = await Hive.openBox('settings');
    _notificationBox = await Hive.openBox('notifications');
    _accountBox = await Hive.openBox('accounts');
    _accountTransactionBox = await Hive.openBox('account_transactions');

    // Create main account if it doesn't exist
    await _ensureMainAccount();
  }

  Future<void> _ensureMainAccount() async {
    final accounts = await getAllAccounts();
    if (accounts.isEmpty) {
      final mainAccount = Account(
        id: 'main',
        name: 'Main Account',
        type: AccountType.main,
        balance: await getAccountBalance(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await saveAccount(mainAccount);
    }
  }

  // Expense Methods
  Future<void> saveExpense(Expense expense) async {
    await _expenseBox.put(expense.id, jsonEncode(expense.toJson()));

    // Update organization's total if it's a company refund
    if (expense.type == ExpenseType.companyRefund &&
        expense.organizationId != null) {
      final org = await getOrganization(expense.organizationId!);
      if (org != null) {
        final updatedOrg = org.copyWith(
          totalRefundsDue: org.totalRefundsDue + expense.amount,
          refundExpenseIds: [...org.refundExpenseIds, expense.id],
        );
        await saveOrganization(updatedOrg);
      }
    }

    // Update budget spent amount (only for personal expenses, not company refunds)
    if (expense.type == ExpenseType.personal) {
      final budgets = await getAllBudgets();
      for (final budget in budgets) {
        if (budget.category == expense.category &&
            expense.date.isAfter(
              budget.startDate.subtract(const Duration(days: 1)),
            ) &&
            expense.date.isBefore(
              budget.endDate.add(const Duration(days: 1)),
            )) {
          final updatedBudget = budget.copyWith(
            spent: budget.spent + expense.amount,
          );
          await saveBudget(updatedBudget);
        }
      }
    }
  }

  Future<void> deleteExpense(String id) async {
    final expenseJson = _expenseBox.get(id);
    if (expenseJson != null) {
      final expense = Expense.fromJson(jsonDecode(expenseJson));

      // Update organization if company refund
      if (expense.type == ExpenseType.companyRefund &&
          expense.organizationId != null) {
        final org = await getOrganization(expense.organizationId!);
        if (org != null) {
          final updatedOrg = org.copyWith(
            totalRefundsDue: org.totalRefundsDue - expense.amount,
            refundExpenseIds: org.refundExpenseIds
                .where((e) => e != id)
                .toList(),
          );
          await saveOrganization(updatedOrg);
        }
      }

      // Update budget (only for personal expenses, not company refunds)
      if (expense.type == ExpenseType.personal) {
        final budgets = await getAllBudgets();
        for (final budget in budgets) {
          if (budget.category == expense.category &&
              expense.date.isAfter(
                budget.startDate.subtract(const Duration(days: 1)),
              ) &&
              expense.date.isBefore(
                budget.endDate.add(const Duration(days: 1)),
              )) {
            final updatedBudget = budget.copyWith(
              spent: budget.spent - expense.amount,
            );
            await saveBudget(updatedBudget);
          }
        }
      }
    }

    await _expenseBox.delete(id);
  }

  Future<Expense?> getExpense(String id) async {
    final json = _expenseBox.get(id);
    if (json == null) return null;
    return Expense.fromJson(jsonDecode(json));
  }

  Future<List<Expense>> getAllExpenses() async {
    final expenses = <Expense>[];
    for (var key in _expenseBox.keys) {
      final json = _expenseBox.get(key);
      if (json != null) {
        expenses.add(Expense.fromJson(jsonDecode(json)));
      }
    }
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  // Budget Methods
  Future<void> saveBudget(Budget budget) async {
    await _budgetBox.put(budget.id, jsonEncode(budget.toJson()));
  }

  Future<void> deleteBudget(String id) async {
    await _budgetBox.delete(id);
  }

  Future<Budget?> getBudget(String id) async {
    final json = _budgetBox.get(id);
    if (json == null) return null;
    return Budget.fromJson(jsonDecode(json));
  }

  Future<List<Budget>> getAllBudgets() async {
    final budgets = <Budget>[];
    for (var key in _budgetBox.keys) {
      final json = _budgetBox.get(key);
      if (json != null) {
        budgets.add(Budget.fromJson(jsonDecode(json)));
      }
    }
    return budgets;
  }

  // Task Methods
  Future<void> saveTask(Task task) async {
    await _taskBox.put(task.id, jsonEncode(task.toJson()));
  }

  Future<void> deleteTask(String id) async {
    await _taskBox.delete(id);
  }

  Future<Task?> getTask(String id) async {
    final json = _taskBox.get(id);
    if (json == null) return null;
    return Task.fromJson(jsonDecode(json));
  }

  Future<List<Task>> getAllTasks() async {
    final tasks = <Task>[];
    for (var key in _taskBox.keys) {
      final json = _taskBox.get(key);
      if (json != null) {
        tasks.add(Task.fromJson(jsonDecode(json)));
      }
    }
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  // Note Methods
  Future<void> saveNote(Note note) async {
    await _noteBox.put(note.id, jsonEncode(note.toJson()));
  }

  Future<void> deleteNote(String id) async {
    await _noteBox.delete(id);
  }

  Future<Note?> getNote(String id) async {
    final json = _noteBox.get(id);
    if (json == null) return null;
    return Note.fromJson(jsonDecode(json));
  }

  Future<List<Note>> getAllNotes() async {
    final notes = <Note>[];
    for (var key in _noteBox.keys) {
      final json = _noteBox.get(key);
      if (json != null) {
        notes.add(Note.fromJson(jsonDecode(json)));
      }
    }
    // Sort pinned notes first, then by updated date
    notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return notes;
  }

  // Organization Methods
  Future<void> saveOrganization(Organization org) async {
    await _orgBox.put(org.id, jsonEncode(org.toJson()));
  }

  Future<void> deleteOrganization(String id) async {
    await _orgBox.delete(id);
  }

  Future<Organization?> getOrganization(String id) async {
    final json = _orgBox.get(id);
    if (json == null) return null;
    return Organization.fromJson(jsonDecode(json));
  }

  Future<List<Organization>> getAllOrganizations() async {
    final orgs = <Organization>[];
    for (var key in _orgBox.keys) {
      final json = _orgBox.get(key);
      if (json != null) {
        orgs.add(Organization.fromJson(jsonDecode(json)));
      }
    }
    orgs.sort((a, b) => a.name.compareTo(b.name));
    return orgs;
  }

  // Settings Methods
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  // Export all data for backup
  Future<Map<String, dynamic>> exportAllData() async {
    return {
      'expenses': _expenseBox.toMap(),
      'budgets': _budgetBox.toMap(),
      'tasks': _taskBox.toMap(),
      'notes': _noteBox.toMap(),
      'organizations': _orgBox.toMap(),
      'settings': _settingsBox.toMap(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  // Import data from backup
  Future<void> importData(Map<String, dynamic> data) async {
    if (data['expenses'] != null) {
      await _expenseBox.clear();
      await _expenseBox.putAll(Map<String, dynamic>.from(data['expenses']));
    }
    if (data['budgets'] != null) {
      await _budgetBox.clear();
      await _budgetBox.putAll(Map<String, dynamic>.from(data['budgets']));
    }
    if (data['tasks'] != null) {
      await _taskBox.clear();
      await _taskBox.putAll(Map<String, dynamic>.from(data['tasks']));
    }
    if (data['notes'] != null) {
      await _noteBox.clear();
      await _noteBox.putAll(Map<String, dynamic>.from(data['notes']));
    }
    if (data['organizations'] != null) {
      await _orgBox.clear();
      await _orgBox.putAll(Map<String, dynamic>.from(data['organizations']));
    }
    if (data['settings'] != null) {
      await _settingsBox.clear();
      await _settingsBox.putAll(Map<String, dynamic>.from(data['settings']));
    }
  }

  // Settings Methods
  Future<double> getAccountBalance() async {
    return (_settingsBox.get('accountBalance') as double?) ?? 0.0;
  }

  Future<void> setAccountBalance(double balance) async {
    await _settingsBox.put('accountBalance', balance);
  }

  Future<void> addToAccountBalance(double amount) async {
    final currentBalance = await getAccountBalance();
    await setAccountBalance(currentBalance + amount);
  }

  Future<void> deductFromAccountBalance(double amount) async {
    final currentBalance = await getAccountBalance();
    await setAccountBalance(currentBalance - amount);
  }

  Future<String?> getThemeMode() async {
    return _settingsBox.get('themeMode') as String?;
  }

  Future<void> setThemeMode(String mode) async {
    await _settingsBox.put('themeMode', mode);
  }

  // App Settings Methods
  Future<Settings> getSettings() async {
    final data = _settingsBox.get('appSettings');
    if (data != null) {
      return Settings(
        dailyReminderEnabled: data['dailyReminderEnabled'] as bool? ?? false,
        reminderHour: data['reminderHour'] as int? ?? 20,
        reminderMinute: data['reminderMinute'] as int? ?? 0,
      );
    }
    return Settings();
  }

  Future<void> saveSettings(Settings settings) async {
    await _settingsBox.put('appSettings', {
      'dailyReminderEnabled': settings.dailyReminderEnabled,
      'reminderHour': settings.reminderHour,
      'reminderMinute': settings.reminderMinute,
    });
  }

  Future<List<String>> getCustomCategories() async {
    final categoriesJson = _settingsBox.get('customCategories');
    if (categoriesJson == null) return [];
    return List<String>.from(jsonDecode(categoriesJson));
  }

  Future<void> addCustomCategory(String category) async {
    final categories = await getCustomCategories();
    if (!categories.contains(category)) {
      categories.add(category);
      await _settingsBox.put('customCategories', jsonEncode(categories));
    }
  }

  Future<void> removeCustomCategory(String category) async {
    final categories = await getCustomCategories();
    categories.remove(category);
    await _settingsBox.put('customCategories', jsonEncode(categories));
  }

  // Notification Methods
  Future<void> saveNotification(AppNotification notification) async {
    await _notificationBox.put(
      notification.id,
      jsonEncode(notification.toJson()),
    );
  }

  Future<List<AppNotification>> getAllNotifications() async {
    final notifications = <AppNotification>[];
    for (var key in _notificationBox.keys) {
      final json = _notificationBox.get(key);
      if (json != null) {
        notifications.add(AppNotification.fromJson(jsonDecode(json)));
      }
    }
    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return notifications;
  }

  Future<void> markNotificationAsRead(String id) async {
    final json = _notificationBox.get(id);
    if (json != null) {
      final notification = AppNotification.fromJson(jsonDecode(json));
      final updated = notification.copyWith(isRead: true);
      await _notificationBox.put(id, jsonEncode(updated.toJson()));
    }
  }

  Future<void> deleteNotification(String id) async {
    await _notificationBox.delete(id);
  }

  Future<int> getUnreadNotificationCount() async {
    final notifications = await getAllNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  // Account Methods
  Future<void> saveAccount(Account account) async {
    await _accountBox.put(account.id, jsonEncode(account.toJson()));
  }

  Future<void> deleteAccount(String id) async {
    await _accountBox.delete(id);
  }

  Future<Account?> getAccount(String id) async {
    final json = _accountBox.get(id);
    if (json == null) return null;
    return Account.fromJson(jsonDecode(json));
  }

  Future<List<Account>> getAllAccounts() async {
    final accounts = <Account>[];
    for (var key in _accountBox.keys) {
      final json = _accountBox.get(key);
      if (json != null) {
        accounts.add(Account.fromJson(jsonDecode(json)));
      }
    }
    accounts.sort((a, b) {
      // Main account always first
      if (a.type == AccountType.main) return -1;
      if (b.type == AccountType.main) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return accounts;
  }

  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    final account = await getAccount(accountId);
    if (account != null) {
      final updated = account.copyWith(
        balance: newBalance,
        updatedAt: DateTime.now(),
      );
      await saveAccount(updated);
    }
  }

  // Account Transaction Methods
  Future<void> saveAccountTransaction(AccountTransaction transaction) async {
    await _accountTransactionBox.put(
      transaction.id,
      jsonEncode(transaction.toJson()),
    );
  }

  Future<List<AccountTransaction>> getAllAccountTransactions() async {
    final transactions = <AccountTransaction>[];
    for (var key in _accountTransactionBox.keys) {
      final json = _accountTransactionBox.get(key);
      if (json != null) {
        transactions.add(AccountTransaction.fromJson(jsonDecode(json)));
      }
    }
    transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return transactions;
  }

  Future<List<AccountTransaction>> getAccountTransactions(
    String accountId,
  ) async {
    final allTransactions = await getAllAccountTransactions();
    return allTransactions
        .where(
          (t) => t.fromAccountId == accountId || t.toAccountId == accountId,
        )
        .toList();
  }

  Future<void> transferBetweenAccounts(
    String fromAccountId,
    String toAccountId,
    double amount,
    String note,
  ) async {
    final fromAccount = await getAccount(fromAccountId);
    final toAccount = await getAccount(toAccountId);

    if (fromAccount == null || toAccount == null) {
      throw Exception('Account not found');
    }

    if (fromAccount.balance < amount) {
      throw Exception('Insufficient balance');
    }

    // Update balances
    await updateAccountBalance(fromAccountId, fromAccount.balance - amount);
    await updateAccountBalance(toAccountId, toAccount.balance + amount);

    // Record transaction
    final transaction = AccountTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: amount,
      note: note,
      timestamp: DateTime.now(),
    );
    await saveAccountTransaction(transaction);
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _expenseBox.clear();
    await _budgetBox.clear();
    await _taskBox.clear();
    await _noteBox.clear();
    await _orgBox.clear();
  }
}
