import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_provider.dart';
import '../models/expense.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/expense_form_dialog.dart';
import 'expense_detail_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update AppBar based on tab
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _tabController.index == 2
          ? AppBar(
              title: const Text('Company Expenses'),
              actions: [
                Consumer<AppProvider>(
                  builder: (context, provider, child) {
                    final companyExpenses = provider.getExpensesByType(
                      ExpenseType.companyRefund,
                    );
                    if (companyExpenses.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => _shareAllCompanyExpenses(context),
                      tooltip: 'Share all company expenses',
                    );
                  },
                ),
              ],
            )
          : null,
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
              tabs: [
                Tab(
                  icon: Icon(Icons.list_alt, size: 20),
                  text: 'All',
                  height: 48,
                ),
                Tab(
                  icon: Icon(Icons.person, size: 20),
                  text: 'Personal',
                  height: 48,
                ),
                Tab(
                  icon: Icon(Icons.business, size: 20),
                  text: 'Company',
                  height: 48,
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, provider, child) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExpenseList(
                      provider.expenses.where((e) => !e.isRefunded).toList(),
                    ),
                    _buildExpenseList(
                      provider.getExpensesByType(ExpenseType.personal),
                    ),
                    _buildExpenseList(
                      provider.getExpensesByType(ExpenseType.companyRefund),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context),
        child: const Icon(Icons.add),
      ).animate().scale(delay: 300.ms, duration: 300.ms),
    );
  }

  Widget _buildExpenseList(List<Expense> expenses) {
    final filteredExpenses = _selectedCategory == 'All'
        ? expenses
        : expenses.where((e) => e.category == _selectedCategory).toList();

    if (filteredExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppTheme.lightGray,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'No expenses yet',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.mediumGray),
            ),
            const SizedBox(height: AppTheme.spacingS),
            TextButton(
              onPressed: () => _showAddExpenseDialog(context),
              child: const Text('Add your first expense'),
            ),
          ],
        ),
      );
    }

    // Group expenses by date
    final groupedExpenses = <String, List<Expense>>{};
    for (var expense in filteredExpenses) {
      final dateKey = AppConstants.formatDate(expense.date);
      groupedExpenses.putIfAbsent(dateKey, () => []).add(expense);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: groupedExpenses.length,
      itemBuilder: (context, index) {
        final dateKey = groupedExpenses.keys.elementAt(index);
        final dayExpenses = groupedExpenses[dateKey]!;
        final dayTotal = dayExpenses.fold(0.0, (sum, e) => sum + e.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateKey,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    AppConstants.formatCurrency(dayTotal),
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ...dayExpenses.map(
              (expense) => _buildExpenseCard(context, expense),
            ),
            const SizedBox(height: AppTheme.spacingM),
          ],
        ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildExpenseCard(BuildContext context, Expense expense) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlack,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        child: const Icon(Icons.delete, color: AppTheme.white),
      ),
      confirmDismiss: (direction) async {
        // For personal expenses, ask if they want to credit account
        if (expense.type == ExpenseType.personal) {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Expense'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to delete this expense?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Amount: ${AppConstants.formatCurrency(expense.amount)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Do you want to credit this amount back to your account?',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                    context.read<AppProvider>().deleteExpense(
                      expense.id,
                      creditAccount: false,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense deleted without crediting account'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Delete Only'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                    context.read<AppProvider>().deleteExpense(
                      expense.id,
                      creditAccount: true,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense deleted and account credited'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Delete & Credit'),
                ),
              ],
            ),
          ).then((value) => false); // Return false to prevent auto-dismissal
        } else {
          // For company expenses, show simple confirmation
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Expense'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Are you sure you want to delete this expense?'),
                  const SizedBox(height: 8),
                  Text(
                    'Amount: ${AppConstants.formatCurrency(expense.amount)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!expense.isRefunded) ...[
                    const SizedBox(height: 8),
                    Text(
                      'This amount will be credited back to your account.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        }
      },
      onDismissed: (direction) async {
        // Capture provider and messenger before dismissal to avoid widget tree issues
        final provider = context.read<AppProvider>();
        final messenger = ScaffoldMessenger.of(context);

        await provider.deleteExpense(expense.id);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              expense.type == ExpenseType.companyRefund && !expense.isRefunded
                  ? 'Expense deleted and account credited'
                  : 'Expense deleted',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
        child: InkWell(
          onTap: () {
            // For company expenses, show detail view instead of edit dialog
            if (expense.type == ExpenseType.companyRefund) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ExpenseDetailScreen(expense: expense),
                ),
              );
            } else {
              _showEditExpenseDialog(context, expense);
            }
          },
          onLongPress: () => _showExpenseOptions(context, expense),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Icon(
                    _getCategoryIcon(expense.category),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Row(
                        children: [
                          Text(expense.category, style: AppTheme.bodySmall),
                          if (expense.organizationName != null) ...[
                            Text(' • ', style: AppTheme.bodySmall),
                            Text(
                              expense.organizationName!,
                              style: AppTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppConstants.formatCurrency(expense.amount),
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: expense.type == ExpenseType.personal
                                ? (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppTheme.darkGray
                                      : AppTheme.lightGray)
                                : AppTheme.secondaryBlack,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusS,
                            ),
                          ),
                          child: Text(
                            expense.type == ExpenseType.personal
                                ? 'Personal'
                                : 'Refund',
                            style: AppTheme.caption.copyWith(
                              color: expense.type == ExpenseType.personal
                                  ? (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppTheme.white
                                        : AppTheme.primaryBlack)
                                  : AppTheme.white,
                            ),
                          ),
                        ),
                        if (expense.isRefunded) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingS,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusS,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 10,
                                  color: AppTheme.white,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Refunded',
                                  style: AppTheme.caption.copyWith(
                                    color: AppTheme.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food & Dining':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Entertainment':
        return Icons.movie;
      case 'Bills & Utilities':
        return Icons.receipt;
      case 'Healthcare':
        return Icons.local_hospital;
      case 'Education':
        return Icons.school;
      case 'Travel':
        return Icons.flight;
      case 'Personal Care':
        return Icons.spa;
      case 'Groceries':
        return Icons.local_grocery_store;
      case 'Rent':
        return Icons.home;
      case 'Insurance':
        return Icons.security;
      case 'Gifts & Donations':
        return Icons.card_giftcard;
      default:
        return Icons.payments;
    }
  }

  void _showAddExpenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ExpenseFormDialog(),
    );
  }

  void _showEditExpenseDialog(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (context) => ExpenseFormDialog(expense: expense),
    );
  }

  void _showExpenseOptions(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _shareExpense(expense);
              },
            ),
            if (expense.type == ExpenseType.personal || !expense.isRefunded)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditExpenseDialog(context, expense);
                },
              ),
            if (expense.type == ExpenseType.companyRefund &&
                !expense.isRefunded)
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Mark as Refunded'),
                onTap: () {
                  Navigator.pop(context);
                  if (expense.organizationId != null) {
                    context.read<AppProvider>().markExpenseAsRefunded(
                      expense.id,
                      expense.organizationId!,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense marked as refunded'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _shareExpense(Expense expense) {
    final buffer = StringBuffer();
    buffer.writeln('EXPENSE');
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln();
    buffer.writeln('Title: ${expense.title}');
    buffer.writeln('Amount: ${AppConstants.formatCurrency(expense.amount)}');
    buffer.writeln('Category: ${expense.category}');
    buffer.writeln('Date: ${AppConstants.formatDate(expense.date)}');
    buffer.writeln(
      'Type: ${expense.type == ExpenseType.personal ? 'Personal' : 'Company Refund'}',
    );

    if (expense.organizationName != null) {
      buffer.writeln('Organization: ${expense.organizationName}');
    }

    if (expense.type == ExpenseType.companyRefund) {
      buffer.writeln(
        'Status: ${expense.isRefunded ? '✅ Refunded' : '⏳ Pending'}',
      );
    }

    if (expense.description != null && expense.description!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Description:');
      buffer.writeln(expense.description);
    }

    Share.share(buffer.toString(), subject: 'Expense: ${expense.title}');
  }

  void _shareAllCompanyExpenses(BuildContext context) {
    final provider = context.read<AppProvider>();
    final companyExpenses = provider.getExpensesByType(
      ExpenseType.companyRefund,
    );

    if (companyExpenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No company expenses to share'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final shareText = _generateCompanyExpensesShareText(companyExpenses);
    Share.share(shareText, subject: 'Company Expenses Summary');
  }

  String _generateCompanyExpensesShareText(List<Expense> expenses) {
    final buffer = StringBuffer();
    buffer.writeln('COMPANY EXPENSES SUMMARY');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();

    // Calculate totals
    final totalAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final pendingExpenses = expenses.where((e) => !e.isRefunded).toList();
    final refundedExpenses = expenses.where((e) => e.isRefunded).toList();
    final pendingAmount = pendingExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final refundedAmount = refundedExpenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );

    buffer.writeln('OVERVIEW');
    buffer.writeln('Total Expenses: ${expenses.length}');
    buffer.writeln('Total Amount: ${AppConstants.formatCurrency(totalAmount)}');
    buffer.writeln();
    buffer.writeln(
      '⏳ Pending: ${pendingExpenses.length} (${AppConstants.formatCurrency(pendingAmount)})',
    );
    buffer.writeln(
      '✅ Refunded: ${refundedExpenses.length} (${AppConstants.formatCurrency(refundedAmount)})',
    );
    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Group by organization
    final expensesByOrg = <String, List<Expense>>{};
    for (var expense in expenses) {
      final org = expense.organizationName ?? 'No Organization';
      expensesByOrg.putIfAbsent(org, () => []).add(expense);
    }

    // List expenses by organization
    for (var org in expensesByOrg.keys) {
      final orgExpenses = expensesByOrg[org]!;
      final orgTotal = orgExpenses.fold(0.0, (sum, e) => sum + e.amount);

      buffer.writeln();
      buffer.writeln(org);
      buffer.writeln('Total: ${AppConstants.formatCurrency(orgTotal)}');
      buffer.writeln();

      for (var expense in orgExpenses) {
        final status = expense.isRefunded ? '✅' : '⏳';
        buffer.writeln('  $status ${expense.title}');
        buffer.writeln('     ${AppConstants.formatCurrency(expense.amount)}');
        buffer.writeln(
          '     ${expense.category} • ${AppConstants.formatDate(expense.date)}',
        );
        if (expense.description != null && expense.description!.isNotEmpty) {
          buffer.writeln('     ${expense.description}');
        }
        buffer.writeln();
      }
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Generated on ${AppConstants.formatDate(DateTime.now())}');

    return buffer.toString();
  }
}
