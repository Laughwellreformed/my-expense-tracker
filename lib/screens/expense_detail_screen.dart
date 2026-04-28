import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/expense.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/expense_form_dialog.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareExpense(context),
          ),
          if (expense.type == ExpenseType.companyRefund && !expense.isRefunded)
            PopupMenuButton<String>(
              onSelected: (value) {
                final provider = context.read<AppProvider>();
                if (value == 'mark_refunded') {
                  if (expense.organizationId != null) {
                    provider.markExpenseAsRefunded(
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
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_refunded',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 20),
                      SizedBox(width: 8),
                      Text('Mark as Refunded'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with amount
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          const Color.fromARGB(255, 0, 0, 0),
                          const Color.fromARGB(255, 7, 14, 22),
                        ]
                      : [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.8),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    AppConstants.formatCurrency(expense.amount),
                    style: AppTheme.heading1.copyWith(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                      vertical: AppTheme.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    ),
                    child: Text(
                      expense.category,
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details section
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem(
                    context,
                    icon: Icons.title,
                    label: 'Title',
                    value: expense.title,
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildDetailItem(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: AppConstants.formatDate(expense.date),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildDetailItem(
                    context,
                    icon: Icons.label,
                    label: 'Type',
                    value: expense.type == ExpenseType.personal
                        ? 'Personal'
                        : 'Company Refund',
                  ),
                  if (expense.organizationName != null) ...[
                    const SizedBox(height: AppTheme.spacingL),
                    _buildDetailItem(
                      context,
                      icon: Icons.business,
                      label: 'Organization',
                      value: expense.organizationName!,
                    ),
                  ],
                  if (expense.type == ExpenseType.companyRefund) ...[
                    const SizedBox(height: AppTheme.spacingL),
                    _buildDetailItem(
                      context,
                      icon: Icons.info,
                      label: 'Refund Status',
                      value: expense.isRefunded ? 'Refunded' : 'Pending',
                      valueColor: expense.isRefunded
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF9800),
                    ),
                  ],
                  if (expense.description != null &&
                      expense.description!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingL),
                    _buildDetailItem(
                      context,
                      icon: Icons.description,
                      label: 'Description',
                      value: expense.description!,
                    ),
                  ],

                  // Receipt/Evidence section
                  if (expense.receiptUrl != null &&
                      expense.receiptUrl!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingXl),
                    const Divider(),
                    const SizedBox(height: AppTheme.spacingL),
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Text('Evidence / Receipt', style: AppTheme.heading3),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    GestureDetector(
                      onTap: () => _showFullImage(context, expense.receiptUrl!),
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          child: Image.file(
                            File(expense.receiptUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 48,
                                      color: AppTheme.mediumGray,
                                    ),
                                    const SizedBox(height: AppTheme.spacingS),
                                    Text(
                                      'Receipt not found',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.mediumGray,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      'Tap to view full size',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          (expense.type == ExpenseType.companyRefund && expense.isRefunded)
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showEditDialog(context),
              label: const Icon(Icons.edit),
            ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingS),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.mediumGray),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFullImage(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Receipt', style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(
                File(imagePath),
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Receipt not found',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _shareExpense(BuildContext context) {
    final shareText = _generateShareText();
    Share.share(shareText, subject: 'Expense: ${expense.title}');
  }

  String _generateShareText() {
    final buffer = StringBuffer();
    buffer.writeln('EXPENSE DETAILS');
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
        'Refund Status: ${expense.isRefunded ? '✅ Refunded' : '⏳ Pending'}',
      );
    }

    if (expense.description != null && expense.description!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Description:');
      buffer.writeln(expense.description);
    }

    return buffer.toString();
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ExpenseFormDialog(expense: expense),
    ).then((value) {
      // Refresh the screen after editing
      if (value == true) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
    });
  }
}
