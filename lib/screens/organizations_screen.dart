import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../models/organization.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/organization_form_dialog.dart';

class OrganizationsScreen extends StatelessWidget {
  const OrganizationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.organizations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: AppTheme.lightGray,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'No organizations yet',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.mediumGray,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  TextButton(
                    onPressed: () => _showAddOrganizationDialog(context),
                    child: const Text('Add your first organization'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            itemCount: provider.organizations.length,
            itemBuilder: (context, index) {
              final org = provider.organizations[index];
              return _buildOrganizationCard(context, org, provider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrganizationDialog(context),
        child: const Icon(Icons.add),
      ).animate().scale(delay: 300.ms, duration: 300.ms),
    );
  }

  Widget _buildOrganizationCard(
    BuildContext context,
    Organization org,
    AppProvider provider,
  ) {
    final refundExpenses = provider.expenses
        .where((e) => e.organizationId == org.id)
        .toList();

    // Calculate pending amount (only non-refunded expenses)
    final pendingAmount = refundExpenses
        .where((e) => !e.isRefunded)
        .fold(0.0, (sum, e) => sum + e.amount);

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: InkWell(
        onTap: () => _showOrganizationDetails(context, org, refundExpenses),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      Icons.business,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          org.name,
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (org.description != null) ...[
                          const SizedBox(height: AppTheme.spacingXs),
                          Text(
                            org.description!,
                            style: AppTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditOrganizationDialog(context, org),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              const Divider(),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Due', style: AppTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text(
                          AppConstants.formatCurrency(pendingAmount),
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withAlpha(51),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: const Color(0xFF4CAF50),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Refunded',
                              style: AppTheme.bodySmall.copyWith(
                                color: const Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppConstants.formatCurrencyCompact(org.totalRefunded),
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: pendingAmount > 0
                          ? const Color(0xFFFF5722).withAlpha(26)
                          : const Color(0xFF9E9E9E).withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: pendingAmount > 0
                            ? const Color(0xFFFF5722).withAlpha(51)
                            : const Color(0xFF9E9E9E).withAlpha(51),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.pending_actions,
                              size: 14,
                              color: pendingAmount > 0
                                  ? const Color(0xFFFF5722)
                                  : const Color(0xFF9E9E9E),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pending',
                              style: AppTheme.bodySmall.copyWith(
                                color: pendingAmount > 0
                                    ? const Color(0xFFFF5722)
                                    : const Color(0xFF9E9E9E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppConstants.formatCurrencyCompact(pendingAmount),
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (org.contactEmail != null || org.contactPhone != null) ...[
                const SizedBox(height: AppTheme.spacingM),
                const Divider(),
                const SizedBox(height: AppTheme.spacingM),
                if (org.contactEmail != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.email,
                        size: 16,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(org.contactEmail!, style: AppTheme.bodySmall),
                    ],
                  ),
                if (org.contactPhone != null) ...[
                  const SizedBox(height: AppTheme.spacingXs),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 16,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(org.contactPhone!, style: AppTheme.bodySmall),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }

  void _showAddOrganizationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const OrganizationFormDialog(),
    );
  }

  void _showEditOrganizationDialog(BuildContext context, Organization org) {
    showDialog(
      context: context,
      builder: (context) => OrganizationFormDialog(organization: org),
    );
  }

  void _showOrganizationDetails(
    BuildContext context,
    Organization org,
    List expenses,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(org.name, style: AppTheme.heading2)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Refund Summary
                  Row(
                    children: [
                      Expanded(
                        child: _RefundSummaryItem(
                          label: 'Total Due',
                          amount: org.totalRefundsDue,
                          color: const Color(0xFFFFC107),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RefundSummaryItem(
                          label: 'Refunded',
                          amount: org.totalRefunded,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RefundSummaryItem(
                          label: 'Pending',
                          amount: org.totalPending,
                          color: const Color(0xFFFF5722),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Expenses List
            Expanded(
              child: expenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: AppTheme.lightGray,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No refund expenses yet',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        final isRefunded = org.refundedExpenseIds.contains(
                          expense.id,
                        );
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isRefunded
                                    ? const Color(0xFF4CAF50).withAlpha(26)
                                    : const Color(0xFFFFC107).withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isRefunded ? Icons.check_circle : Icons.pending,
                                color: isRefunded
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFFFC107),
                              ),
                            ),
                            title: Text(expense.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(AppConstants.formatDate(expense.date)),
                                if (isRefunded)
                                  Text(
                                    'Refunded',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: const Color(0xFF4CAF50),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: SizedBox(
                              width: 100,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppConstants.formatCurrency(expense.amount),
                                    style: AppTheme.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (!isRefunded)
                                    TextButton(
                                      onPressed: () async {
                                        await context
                                            .read<AppProvider>()
                                            .markExpenseAsRefunded(
                                              expense.id,
                                              org.id,
                                            );
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'Marked as refunded and amount credited',
                                              ),
                                              backgroundColor: const Color(
                                                0xFF4CAF50,
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 0,
                                        ),
                                        minimumSize: const Size(0, 28),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Mark Refunded',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    )
                                  else
                                    TextButton(
                                      onPressed: () async {
                                        await context
                                            .read<AppProvider>()
                                            .unmarkExpenseAsRefunded(
                                              expense.id,
                                              org.id,
                                            );
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'Unmarked as refunded and amount deducted',
                                              ),
                                              backgroundColor: const Color(
                                                0xFFFF5722,
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 0,
                                        ),
                                        minimumSize: const Size(0, 28),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Undo',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefundSummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _RefundSummaryItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.mediumGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppConstants.formatCurrencyCompact(amount),
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
