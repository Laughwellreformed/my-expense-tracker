import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../models/budget.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/budget_form_dialog.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  icon: Icon(Icons.play_circle, size: 20),
                  text: 'Active',
                  height: 48,
                ),
                Tab(
                  icon: Icon(Icons.folder, size: 20),
                  text: 'All Budgets',
                  height: 48,
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, provider, child) {
                if (provider.budgets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: AppTheme.lightGray,
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        Text(
                          'No budgets yet',
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        TextButton(
                          onPressed: () => _showAddBudgetDialog(context),
                          child: const Text('Create your first budget'),
                        ),
                      ],
                    ),
                  );
                }

                final activeBudgets = provider.getActiveBudgets();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Active Budgets Tab
                    _buildBudgetList(context, provider, activeBudgets, true),
                    // All Budgets Tab
                    _buildBudgetList(
                      context,
                      provider,
                      provider.budgets,
                      false,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetDialog(context),
        child: const Icon(Icons.add),
      ).animate().scale(delay: 300.ms, duration: 300.ms),
    );
  }

  Widget _buildBudgetList(
    BuildContext context,
    AppProvider provider,
    List<Budget> budgets,
    bool isActiveTab,
  ) {
    if (budgets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Text(
            isActiveTab ? 'No active budgets' : 'No budgets',
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.mediumGray),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card (only show in Active tab)
          if (isActiveTab)
            _buildSummaryCard(
              provider,
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
          if (isActiveTab) const SizedBox(height: AppTheme.spacingL),

          // Budget Cards
          ...budgets.map((budget) => _buildBudgetCard(context, budget, true)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AppProvider provider) {
    final totalBudget = provider.totalBudgetAmount;
    final totalSpent = provider.totalBudgetSpent;
    final remaining = totalBudget - totalSpent;
    final percentageUsed = totalBudget > 0
        ? (totalSpent / totalBudget) * 100
        : 0;
    final isOverBudget = totalSpent > totalBudget;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget Overview', style: AppTheme.heading3),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Total Budget', totalBudget),
              _buildSummaryItem('Spent', totalSpent),
              _buildSummaryItem(
                'Remaining',
                remaining,
                isNegative: isOverBudget,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            child: LinearProgressIndicator(
              value: (percentageUsed / 100).clamp(0.0, 1.0),
              backgroundColor: AppTheme.lightGray,
              color: percentageUsed > 100
                  ? const Color(0xFFF44336)
                  : percentageUsed > 80
                  ? const Color(0xFFFF9800)
                  : percentageUsed > 60
                  ? const Color(0xFFFFC107)
                  : const Color(0xFF4CAF50),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentageUsed.toStringAsFixed(1)}% used',
                style: AppTheme.bodySmall,
              ),
              if (isOverBudget)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF44336),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Text(
                    'Over Budget',
                    style: AppTheme.caption.copyWith(color: AppTheme.white),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double amount, {
    bool isNegative = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          AppConstants.formatCurrencyCompact(amount),
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isNegative ? const Color(0xFFF44336) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    Budget budget,
    bool showProgress,
  ) {
    return Dismissible(
      key: Key(budget.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingM),
        decoration: BoxDecoration(
          color: const Color(0xFFF44336),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        child: const Icon(Icons.delete, color: AppTheme.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Budget'),
              content: const Text(
                'Are you sure you want to delete this budget?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Color(0xFFF44336)),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        context.read<AppProvider>().deleteBudget(budget.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
        child: InkWell(
          onTap: () => _showEditBudgetDialog(context, budget),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budget.category,
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXs),
                          Text(
                            '${AppConstants.formatDate(budget.startDate)} - ${AppConstants.formatDate(budget.endDate)}',
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppConstants.formatCurrency(budget.remaining),
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: budget.isOverBudget
                                ? AppTheme.darkGray
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text('remaining', style: AppTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  child: LinearProgressIndicator(
                    value: (budget.percentageUsed / 100).clamp(0.0, 1.0),
                    backgroundColor: AppTheme.lightGray,
                    color: budget.percentageUsed > 100
                        ? const Color(0xFFF44336)
                        : budget.percentageUsed > 80
                        ? const Color(0xFFFF9800)
                        : budget.percentageUsed > 60
                        ? const Color(0xFFFFC107)
                        : const Color(0xFF4CAF50),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppConstants.formatCurrency(budget.spent)} of ${AppConstants.formatCurrency(budget.amount)}',
                      style: AppTheme.bodySmall,
                    ),
                    Text(
                      '${budget.percentageUsed.toStringAsFixed(1)}%',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (budget.isOverBudget)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacingS),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingS,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.darkGray,
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Text(
                        'Over Budget',
                        style: AppTheme.caption.copyWith(color: AppTheme.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0),
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BudgetFormDialog(),
    );
  }

  void _showEditBudgetDialog(BuildContext context, Budget budget) {
    showDialog(
      context: context,
      builder: (context) => BudgetFormDialog(budget: budget),
    );
  }
}
