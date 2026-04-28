import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/add_money_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overspending Warning Banner
                if (provider.isOverspending())
                  _buildOverspendingBanner(provider)
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: -0.2, end: 0),
                if (provider.isOverspending())
                  const SizedBox(height: AppTheme.spacingM),
                // Summary Cards
                _buildSummaryCards(
                  context,
                  provider,
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: AppTheme.spacingL),

                // Expense Distribution Chart
                _buildExpenseChart(provider)
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: AppTheme.spacingL),

                // Monthly Trend
                _buildMonthlyTrend(provider)
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: AppTheme.spacingL),

                // Category Breakdown
                _buildCategoryBreakdown(provider)
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: AppTheme.spacingL),

                // Quick Stats
                _buildQuickStats(provider)
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverspendingBanner(AppProvider provider) {
    final message = provider.getOverspendingMessage();
    if (message == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF5722).withAlpha(230),
            const Color(0xFFE64A19).withAlpha(230),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5722).withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Financial Alert',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Overview', style: AppTheme.heading2),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFF4CAF50)),
              tooltip: 'Add Money',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddMoneyDialog(),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        // Account Balance Card
        _AccountBalanceCard(balance: provider.accountBalance),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total Expenses',
                amount: provider.totalExpenses,
                icon: Icons.trending_down,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: _SummaryCard(
                title: 'Budget Left',
                amount: provider.totalBudgetAmount - provider.totalBudgetSpent,
                icon: Icons.account_balance_wallet,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Personal',
                amount: provider.totalPersonalExpenses,
                icon: Icons.person,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: _SummaryCard(
                title: 'To be Refunded',
                amount: provider.totalCompanyRefunds,
                icon: Icons.pending_actions,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Refunded',
                amount: provider.totalRefundedAmount,
                icon: Icons.check_circle,
                isPositive: true,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: _SummaryCard(
                title: 'Organizations',
                amount: provider.organizations.length.toDouble(),
                icon: Icons.business,
                isCount: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseChart(AppProvider provider) {
    final expensesByCategory = provider.getExpensesByCategory();

    if (expensesByCategory.isEmpty) {
      return _buildEmptyState('No expenses to display');
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.secondaryBlack : AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: isDark ? AppTheme.darkGray : AppTheme.lightGray,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Expense Distribution', style: AppTheme.heading3),
              const SizedBox(height: AppTheme.spacingL),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieChartSections(expensesByCategory),
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, double> data) {
    final total = data.values.fold(0.0, (sum, value) => sum + value);
    final entries = data.entries.toList();

    return List.generate(entries.length, (index) {
      final percentage = (entries[index].value / total) * 100;
      final color = Color(
        AppConstants.chartColors[index % AppConstants.chartColors.length],
      );

      return PieChartSectionData(
        color: color,
        value: entries[index].value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.white,
        ),
      );
    });
  }

  Widget _buildMonthlyTrend(AppProvider provider) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthExpenses = provider.getExpensesByDateRange(monthStart, now);

    // Group by day
    final dailyExpenses = <int, double>{};
    for (var expense in monthExpenses) {
      final day = expense.date.day;
      dailyExpenses[day] = (dailyExpenses[day] ?? 0) + expense.amount;
    }

    if (dailyExpenses.isEmpty) {
      return _buildEmptyState('No expenses this month');
    }

    // Calculate min and max for the chart
    final sortedDays = dailyExpenses.keys.toList()..sort();
    final minDay = sortedDays.first.toDouble();
    final maxDay = sortedDays.last.toDouble();
    final maxExpense = dailyExpenses.values.reduce((a, b) => a > b ? a : b);

    // Calculate appropriate intervals
    final dayRange = maxDay - minDay;
    final xInterval = dayRange > 10 ? (dayRange / 5).ceilToDouble() : 1.0;
    final yInterval = maxExpense > 0 ? (maxExpense / 4).ceilToDouble() : 1000.0;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.secondaryBlack : AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: isDark ? AppTheme.darkGray : AppTheme.lightGray,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly Trend', style: AppTheme.heading3),
              const SizedBox(height: AppTheme.spacingL),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: isDark
                              ? AppTheme.darkGray
                              : AppTheme.lightGray,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          interval: yInterval,
                          getTitlesWidget: (value, meta) {
                            if (value < 0) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                AppConstants.formatCurrencyCompact(value),
                                style: AppTheme.bodySmall.copyWith(
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: xInterval,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            // Only show labels for actual data points or nice intervals
                            final intValue = value.toInt();
                            if (intValue < 1 || intValue > 31) {
                              return const SizedBox.shrink();
                            }
                            // Show every nth day based on interval
                            if ((intValue - minDay.toInt()) %
                                        xInterval.toInt() !=
                                    0 &&
                                !dailyExpenses.containsKey(intValue)) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                intValue.toString(),
                                style: AppTheme.bodySmall.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: minDay - 1,
                    maxX: maxDay + 1,
                    minY: 0,
                    maxY: maxExpense * 1.2,
                    lineBarsData: [
                      LineChartBarData(
                        spots:
                            dailyExpenses.entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value))
                                .toList()
                              ..sort((a, b) => a.x.compareTo(b.x)),
                        isCurved: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00BCD4),
                            const Color(0xFF00BCD4),
                          ],
                        ),
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: const Color(0xFF00BCD4),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF00BCD4).withAlpha(51),
                              const Color(0xFF00BCD4).withAlpha(0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryBreakdown(AppProvider provider) {
    final expensesByCategory = provider.getExpensesByCategory();
    final sortedCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isEmpty) {
      return _buildEmptyState('No expenses to display');
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.secondaryBlack : AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: isDark ? AppTheme.darkGray : AppTheme.lightGray,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Top Categories', style: AppTheme.heading3),
              const SizedBox(height: AppTheme.spacingM),
              ...sortedCategories.take(5).map((entry) {
                final percentage = provider.totalExpenses > 0
                    ? (entry.value / provider.totalExpenses) * 100
                    : 0.0;
                final index = sortedCategories.indexOf(entry);
                final color = Color(
                  AppConstants.chartColors[index %
                      AppConstants.chartColors.length],
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                        child: LinearProgressIndicator(
                          value: (percentage / 100).clamp(0.0, 1.0),
                          backgroundColor: isDark
                              ? AppTheme.darkGray
                              : AppTheme.lightGray,
                          color: color,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(AppProvider provider) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.secondaryBlack : AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: isDark ? AppTheme.darkGray : AppTheme.lightGray,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quick Stats', style: AppTheme.heading3),
              const SizedBox(height: AppTheme.spacingM),
              _buildStatRow(
                'Total Budgets',
                provider.budgets.length.toString(),
              ),
              _buildStatRow(
                'Active Budgets',
                provider.getActiveBudgets().length.toString(),
              ),
              _buildStatRow(
                'Organizations',
                provider.organizations.length.toString(),
              ),
              _buildStatRow(
                'Pending Tasks',
                provider.pendingTasksCount.toString(),
              ),
              _buildStatRow(
                'Completed Tasks',
                provider.completedTasksCount.toString(),
              ),
              _buildStatRow('Total Notes', provider.notes.length.toString()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMedium),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.secondaryBlack : AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: isDark ? AppTheme.darkGray : AppTheme.lightGray,
            ),
          ),
          child: Center(
            child: Text(
              message,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGray),
            ),
          ),
        );
      },
    );
  }
}

class _AccountBalanceCard extends StatelessWidget {
  final double balance;

  const _AccountBalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withAlpha(77),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Balance',
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.white.withAlpha(230),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConstants.formatCurrency(balance),
                      style: AppTheme.heading1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final bool isPositive;
  final bool isCount;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    this.isPositive = false,
    this.isCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.secondaryBlack : AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: isDark ? AppTheme.darkGray : AppTheme.lightGray,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    icon,
                    size: 20,
                    color: isPositive
                        ? const Color(0xFF4CAF50)
                        : AppTheme.mediumGray,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                isCount
                    ? amount.toInt().toString()
                    : AppConstants.formatCurrencyCompact(amount),
                style: AppTheme.heading3.copyWith(
                  color: isPositive ? const Color(0xFF4CAF50) : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
