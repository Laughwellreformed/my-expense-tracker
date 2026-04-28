import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../models/expense.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = '30'; // Days

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Time Period',
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7', child: Text('Last 7 Days')),
              const PopupMenuItem(value: '30', child: Text('Last 30 Days')),
              const PopupMenuItem(value: '90', child: Text('Last 3 Months')),
              const PopupMenuItem(value: '365', child: Text('Last Year')),
            ],
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final reports = _generateReports(provider);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Financial Health Score
                  _buildHealthScore(reports)
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: AppTheme.spacingL),

                  // Quick Stats
                  _buildQuickStats(reports)
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: AppTheme.spacingL),

                  // Spending Insights
                  _buildSpendingInsights(reports)
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: AppTheme.spacingL),

                  // Budget Performance
                  _buildBudgetPerformance(reports)
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: AppTheme.spacingL),

                  // Category Analysis
                  _buildCategoryAnalysis(reports)
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: AppTheme.spacingL),

                  // Recommendations
                  _buildRecommendations(reports)
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: AppTheme.spacingL),

                  // Trends
                  _buildTrends(reports)
                      .animate(delay: 600.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  FinancialReports _generateReports(AppProvider provider) {
    final now = DateTime.now();
    final daysBack = int.parse(_selectedPeriod);
    final startDate = now.subtract(Duration(days: daysBack));

    final expenses = provider.getExpensesByDateRange(startDate, now);
    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final personalSpent = expenses
        .where((e) => e.type == ExpenseType.personal)
        .fold(0.0, (sum, e) => sum + e.amount);
    final companyPending = expenses
        .where((e) => e.type == ExpenseType.companyRefund && !e.isRefunded)
        .fold(0.0, (sum, e) => sum + e.amount);

    // Calculate daily average
    final dailyAverage = totalSpent / daysBack;

    // Category breakdown
    final categorySpending = <String, double>{};
    for (var expense in expenses) {
      categorySpending[expense.category] =
          (categorySpending[expense.category] ?? 0) + expense.amount;
    }

    // Budget adherence
    final budgets = provider.getActiveBudgets();
    var budgetScore = 100.0;
    var budgetsOverspent = 0;

    for (var budget in budgets) {
      final spent = provider.getSpentOnBudget(budget);
      if (spent > budget.amount) {
        budgetsOverspent++;
        budgetScore -= 20;
      } else if (spent > budget.amount * 0.9) {
        budgetScore -= 10;
      }
    }
    budgetScore = budgetScore.clamp(0, 100);

    // Financial health score
    var healthScore = 100.0;

    // Deduct for negative balance
    if (provider.accountBalance < 0) {
      healthScore -= 30;
    } else if (provider.accountBalance < dailyAverage * 7) {
      healthScore -= 15;
    }

    // Deduct for budget overspending
    healthScore -= (budgetsOverspent * 10);

    // Deduct for high spending rate
    final monthlyProjection = dailyAverage * 30;
    if (monthlyProjection > provider.accountBalance * 0.8) {
      healthScore -= 20;
    }

    healthScore = healthScore.clamp(0, 100);

    return FinancialReports(
      totalSpent: totalSpent,
      personalSpent: personalSpent,
      companyPending: companyPending,
      dailyAverage: dailyAverage,
      categorySpending: categorySpending,
      budgetScore: budgetScore,
      healthScore: healthScore,
      budgetsOverspent: budgetsOverspent,
      expenseCount: expenses.length,
      largestExpense: expenses.isEmpty
          ? 0
          : expenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b),
      accountBalance: provider.accountBalance,
      daysAnalyzed: daysBack,
    );
  }

  Widget _buildHealthScore(FinancialReports reports) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final score = reports.healthScore;

    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;

    if (score >= 80) {
      scoreColor = const Color(0xFF4CAF50);
      scoreLabel = 'Excellent';
      scoreIcon = Icons.sentiment_very_satisfied;
    } else if (score >= 60) {
      scoreColor = const Color(0xFF8BC34A);
      scoreLabel = 'Good';
      scoreIcon = Icons.sentiment_satisfied;
    } else if (score >= 40) {
      scoreColor = const Color(0xFFFFC107);
      scoreLabel = 'Fair';
      scoreIcon = Icons.sentiment_neutral;
    } else {
      scoreColor = const Color(0xFFFF5722);
      scoreLabel = 'Poor';
      scoreIcon = Icons.sentiment_dissatisfied;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withOpacity(0.8), scoreColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(scoreIcon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Health Score',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          score.toStringAsFixed(0),
                          style: AppTheme.heading1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 48,
                          ),
                        ),
                        Text(
                          ' / 100',
                          style: AppTheme.bodyLarge.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              scoreLabel,
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(FinancialReports reports) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: AppTheme.heading2),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Spent',
                value: AppConstants.formatCurrency(reports.totalSpent),
                icon: Icons.trending_up,
                color: const Color(0xFFFF5722),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: _StatCard(
                title: 'Daily Average',
                value: AppConstants.formatCurrency(reports.dailyAverage),
                icon: Icons.calendar_today,
                color: const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Transactions',
                value: reports.expenseCount.toString(),
                icon: Icons.receipt_long,
                color: const Color(0xFF9C27B0),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: _StatCard(
                title: 'Largest',
                value: AppConstants.formatCurrencyCompact(
                  reports.largestExpense,
                ),
                icon: Icons.arrow_upward,
                color: const Color(0xFFFFC107),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpendingInsights(FinancialReports reports) {
    final monthlyProjection = reports.dailyAverage * 30;
    final weeklyProjection = reports.dailyAverage * 7;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('Spending Insights', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInsightRow(
            'Weekly Projection',
            AppConstants.formatCurrency(weeklyProjection),
            weeklyProjection > reports.accountBalance * 0.2
                ? Icons.warning
                : Icons.check_circle,
            weeklyProjection > reports.accountBalance * 0.2
                ? const Color(0xFFFFC107)
                : const Color(0xFF4CAF50),
          ),
          const Divider(height: 24),
          _buildInsightRow(
            'Monthly Projection',
            AppConstants.formatCurrency(monthlyProjection),
            monthlyProjection > reports.accountBalance * 0.8
                ? Icons.error
                : Icons.check_circle,
            monthlyProjection > reports.accountBalance * 0.8
                ? const Color(0xFFFF5722)
                : const Color(0xFF4CAF50),
          ),
          const Divider(height: 24),
          _buildInsightRow(
            'Current Balance',
            AppConstants.formatCurrency(reports.accountBalance),
            reports.accountBalance < reports.dailyAverage * 7
                ? Icons.trending_down
                : Icons.trending_up,
            reports.accountBalance < reports.dailyAverage * 7
                ? const Color(0xFFFF5722)
                : const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(label, style: AppTheme.bodyMedium),
          ],
        ),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetPerformance(FinancialReports reports) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('Budget Performance', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Score', style: AppTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      '${reports.budgetScore.toStringAsFixed(0)}/100',
                      style: AppTheme.heading2.copyWith(
                        color: reports.budgetScore >= 70
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFFC107),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Overspent Budgets', style: AppTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      reports.budgetsOverspent.toString(),
                      style: AppTheme.heading2.copyWith(
                        color: reports.budgetsOverspent > 0
                            ? const Color(0xFFFF5722)
                            : const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (reports.budgetsOverspent > 0) ...[
            const SizedBox(height: AppTheme.spacingM),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF5722).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Color(0xFFFF5722),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have ${reports.budgetsOverspent} budget(s) that exceeded their limit',
                      style: AppTheme.bodySmall.copyWith(
                        color: const Color(0xFFFF5722),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryAnalysis(FinancialReports reports) {
    final sortedCategories = reports.categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('Top Spending Categories', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          if (sortedCategories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Text(
                  'No expenses in this period',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.mediumGray,
                  ),
                ),
              ),
            )
          else
            ...sortedCategories.take(5).map((entry) {
              final percentage = (entry.value / reports.totalSpent * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: AppTheme.bodyMedium),
                        Text(
                          AppConstants.formatCurrency(entry.value),
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 8,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecommendations(FinancialReports reports) {
    final recommendations = <Recommendation>[];

    // Check account balance
    if (reports.accountBalance < reports.dailyAverage * 7) {
      recommendations.add(
        Recommendation(
          icon: Icons.warning,
          title: 'Low Account Balance',
          description:
              'Your balance can only cover ${(reports.accountBalance / reports.dailyAverage).toStringAsFixed(0)} days of spending. Consider reducing expenses.',
          priority: 'high',
        ),
      );
    }

    // Check spending rate
    final monthlyProjection = reports.dailyAverage * 30;
    if (monthlyProjection > reports.accountBalance * 0.8) {
      recommendations.add(
        Recommendation(
          icon: Icons.speed,
          title: 'High Spending Rate',
          description:
              'At your current rate, you\'ll spend ${((monthlyProjection / reports.accountBalance) * 100).toStringAsFixed(0)}% of your balance monthly. Consider slowing down.',
          priority: 'high',
        ),
      );
    }

    // Check budget overspending
    if (reports.budgetsOverspent > 0) {
      recommendations.add(
        Recommendation(
          icon: Icons.trending_up,
          title: 'Budget Exceeded',
          description:
              '${reports.budgetsOverspent} budget(s) exceeded. Review and adjust your spending in these categories.',
          priority: 'medium',
        ),
      );
    }

    // Check top spending category
    if (reports.categorySpending.isNotEmpty) {
      final topCategory = reports.categorySpending.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      final percentage = (topCategory.value / reports.totalSpent * 100);

      if (percentage > 40) {
        recommendations.add(
          Recommendation(
            icon: Icons.pie_chart,
            title: 'High Category Concentration',
            description:
                '${percentage.toStringAsFixed(0)}% of spending is in ${topCategory.key}. Consider diversifying or reducing this category.',
            priority: 'low',
          ),
        );
      }
    }

    // Positive recommendations
    if (reports.healthScore >= 80) {
      recommendations.add(
        Recommendation(
          icon: Icons.check_circle,
          title: 'Great Job!',
          description:
              'You\'re managing your finances well. Keep up the good work!',
          priority: 'positive',
        ),
      );
    }

    if (reports.accountBalance > reports.dailyAverage * 30) {
      recommendations.add(
        Recommendation(
          icon: Icons.savings,
          title: 'Consider Saving',
          description:
              'You have a healthy balance. Consider moving excess funds to savings or investments.',
          priority: 'positive',
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('Recommendations', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          if (recommendations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Text(
                  'No recommendations at this time',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.mediumGray,
                  ),
                ),
              ),
            )
          else
            ...recommendations.map((rec) {
              Color color;
              switch (rec.priority) {
                case 'high':
                  color = const Color(0xFFFF5722);
                  break;
                case 'medium':
                  color = const Color(0xFFFFC107);
                  break;
                case 'positive':
                  color = const Color(0xFF4CAF50);
                  break;
                default:
                  color = const Color(0xFF2196F3);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(rec.icon, color: color, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec.title,
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(rec.description, style: AppTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildTrends(FinancialReports reports) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('Key Metrics', style: AppTheme.heading3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildTrendRow(
            'Analysis Period',
            '${reports.daysAnalyzed} days',
            Icons.calendar_month,
          ),
          const Divider(height: 24),
          _buildTrendRow(
            'Personal Expenses',
            AppConstants.formatCurrency(reports.personalSpent),
            Icons.person,
          ),
          const Divider(height: 24),
          _buildTrendRow(
            'Pending Refunds',
            AppConstants.formatCurrency(reports.companyPending),
            Icons.pending_actions,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: AppTheme.bodyMedium),
          ],
        ),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Icon(icon, color: color, size: 24)],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class FinancialReports {
  final double totalSpent;
  final double personalSpent;
  final double companyPending;
  final double dailyAverage;
  final Map<String, double> categorySpending;
  final double budgetScore;
  final double healthScore;
  final int budgetsOverspent;
  final int expenseCount;
  final double largestExpense;
  final double accountBalance;
  final int daysAnalyzed;

  FinancialReports({
    required this.totalSpent,
    required this.personalSpent,
    required this.companyPending,
    required this.dailyAverage,
    required this.categorySpending,
    required this.budgetScore,
    required this.healthScore,
    required this.budgetsOverspent,
    required this.expenseCount,
    required this.largestExpense,
    required this.accountBalance,
    required this.daysAnalyzed,
  });
}

class Recommendation {
  final IconData icon;
  final String title;
  final String description;
  final String priority;

  Recommendation({
    required this.icon,
    required this.title,
    required this.description,
    required this.priority,
  });
}
