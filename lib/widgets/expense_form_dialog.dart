import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/expense.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'add_category_dialog.dart';

class ExpenseFormDialog extends StatefulWidget {
  final Expense? expense;

  const ExpenseFormDialog({super.key, this.expense});

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late ExpenseType _selectedType;
  String? _selectedOrgId;
  String? _receiptPath;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense?.title ?? '');
    _amountController = TextEditingController(
      text: widget.expense?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.expense?.description ?? '',
    );
    _selectedDate = widget.expense?.date ?? DateTime.now();
    _selectedCategory =
        widget.expense?.category ?? AppConstants.expenseCategories[0];
    _selectedType = widget.expense?.type ?? ExpenseType.personal;
    _selectedOrgId = widget.expense?.organizationId;
    _receiptPath = widget.expense?.receiptUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.expense == null ? 'Add Expense' : 'Edit Expense',
                        style: AppTheme.heading2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingL),

                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Lunch at restaurant',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Amount Field
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText: '0.00',
                    prefixText: AppConstants.currencySymbol,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Category Dropdown with Add Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Consumer<AppProvider>(
                        builder: (context, provider, child) {
                          final allCategories = [
                            ...AppConstants.expenseCategories,
                            ...provider.customCategories,
                          ];
                          return DropdownButtonFormField<String>(
                            value: allCategories.contains(_selectedCategory)
                                ? _selectedCategory
                                : allCategories.first,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                            ),
                            items: allCategories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedCategory = value!);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF00BCD4),
                        ),
                        tooltip: 'Add Custom Category',
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            builder: (context) => const AddCategoryDialog(),
                          );
                          setState(() {}); // Refresh to show new category
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Type Selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type', style: AppTheme.bodyMedium),
                    const SizedBox(height: AppTheme.spacingS),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeButton(
                            'Personal',
                            ExpenseType.personal,
                            Icons.person,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: _buildTypeButton(
                            'Company Refund',
                            ExpenseType.companyRefund,
                            Icons.business,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Organization Selector (if company refund)
                if (_selectedType == ExpenseType.companyRefund)
                  Consumer<AppProvider>(
                    builder: (context, provider, child) {
                      return DropdownButtonFormField<String>(
                        value: _selectedOrgId,
                        decoration: const InputDecoration(
                          labelText: 'Organization',
                        ),
                        hint: const Text('Select organization'),
                        items: provider.organizations.map((org) {
                          return DropdownMenuItem(
                            value: org.id,
                            child: Text(org.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedOrgId = value);
                        },
                        validator: (value) {
                          if (_selectedType == ExpenseType.companyRefund &&
                              (value == null || value.isEmpty)) {
                            return 'Please select an organization';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                if (_selectedType == ExpenseType.companyRefund)
                  const SizedBox(height: AppTheme.spacingM),

                // Date Selector
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Date', style: AppTheme.bodyMedium),
                  subtitle: Text(AppConstants.formatDate(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Add notes about this expense',
                  ),
                  maxLines: 3,
                ),

                // Receipt Upload (only for company refunds)
                if (_selectedType == ExpenseType.companyRefund) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receipt/Evidence (Optional)',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      if (_receiptPath != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusS,
                                  ),
                                  image: DecorationImage(
                                    image: FileImage(File(_receiptPath!)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Receipt attached',
                                      style: AppTheme.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap to view or change',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.mediumGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _receiptPath = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImageFromCamera,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImageFromGallery,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppTheme.spacingL),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    ElevatedButton(
                      onPressed: _saveExpense,
                      child: Text(widget.expense == null ? 'Add' : 'Save'),
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

  Widget _buildTypeButton(String label, ExpenseType type, IconData icon) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlack : AppTheme.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlack : AppTheme.lightGray,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.white : AppTheme.primaryBlack,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: isSelected ? AppTheme.white : AppTheme.primaryBlack,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (image != null) {
        await _saveReceiptLocally(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to capture image: $e')));
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        await _saveReceiptLocally(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _saveReceiptLocally(XFile image) async {
    try {
      // Get the app's local directory (not backed up)
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String receiptsDir = '${appDir.path}/receipts';

      // Create receipts directory if it doesn't exist
      await Directory(receiptsDir).create(recursive: true);

      // Generate unique filename
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final String filePath = '$receiptsDir/$fileName';

      // Copy file to local storage
      await File(image.path).copy(filePath);

      setState(() {
        _receiptPath = filePath;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save receipt: $e')));
      }
    }
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<AppProvider>();

      String? orgName;
      if (_selectedType == ExpenseType.companyRefund &&
          _selectedOrgId != null) {
        orgName = provider.organizations
            .firstWhere((org) => org.id == _selectedOrgId)
            .name;
      }

      final expense = Expense(
        id: widget.expense?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        category: _selectedCategory,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        type: _selectedType,
        organizationId: _selectedType == ExpenseType.companyRefund
            ? _selectedOrgId
            : null,
        organizationName: orgName,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        receiptUrl: _receiptPath,
        isRefunded: widget.expense?.isRefunded ?? false,
      );

      if (widget.expense == null) {
        provider.addExpense(expense);
      } else {
        provider.updateExpense(expense);
      }

      Navigator.pop(context);

      // Show warning if overspending after adding personal expense
      if (_selectedType == ExpenseType.personal && mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (provider.isOverspending() && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  provider.getOverspendingMessage() ?? 'You\'re overspending!',
                ),
                backgroundColor: const Color(0xFFFF5722),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () {
                    // Already on dashboard, user can see the banner
                  },
                ),
              ),
            );
          }
        });
      }
    }
  }
}
