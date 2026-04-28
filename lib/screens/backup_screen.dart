import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../services/backup_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  bool _isLoading = false;
  DateTime? _lastBackupDate;

  @override
  void initState() {
    super.initState();
    _loadLastBackupDate();
  }

  Future<void> _loadLastBackupDate() async {
    try {
      final date = await _backupService.getLastBackupDate();
      if (mounted) {
        setState(() {
          _lastBackupDate = date;
        });
      }
    } catch (e) {
      // Silently fail on load - will show error on backup attempt
    }
  }

  Future<void> _performBackup() async {
    setState(() => _isLoading = true);

    try {
      final provider = context.read<AppProvider>();

      // Prepare data for backup
      final backupData = {
        'expenses': provider.expenses.map((e) => e.toJson()).toList(),
        'budgets': provider.budgets.map((b) => b.toJson()).toList(),
        'tasks': provider.tasks.map((t) => t.toJson()).toList(),
        'notes': provider.notes.map((n) => n.toJson()).toList(),
        'organizations': provider.organizations.map((o) => o.toJson()).toList(),
        'accounts': provider.accounts.map((a) => a.toJson()).toList(),
        'customCategories': provider.customCategories,
        'accountBalance': provider.accountBalance,
      };

      await _backupService.backupData(backupData);
      await _loadLastBackupDate();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup completed successfully'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup failed: $e'),
              backgroundColor: const Color(0xFFF44336),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _performRestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'This will replace all your current data with the backup. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final backupData = await _backupService.restoreData();

      if (backupData == null) {
        throw Exception('No backup found');
      }

      // Restore data through provider
      if (!mounted) return;
      final provider = context.read<AppProvider>();
      await provider.restoreFromBackup(backupData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restore completed successfully'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: const Color(0xFFF44336),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: const Text(
          'Are you sure you want to delete your backup from the cloud? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _backupService.deleteBackup();
      await _loadLastBackupDate();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: const Color(0xFFF44336),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard()
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.2),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildBackupStatusCard()
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.2),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildActionButtons()
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.2),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text('Cloud Backup', style: AppTheme.heading3),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Your data is securely stored in Firebase Cloud. You can backup and restore your expenses, budgets, tasks, notes, and organizations anytime.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Backup Status', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacingL),
            _buildStatusRow(
              Icons.cloud_done,
              'Cloud Storage',
              _backupService.isSignedIn ? 'Connected' : 'Not Connected',
              _backupService.isSignedIn
                  ? const Color(0xFF4CAF50)
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildStatusRow(
              Icons.access_time,
              'Last Backup',
              _lastBackupDate != null
                  ? AppConstants.formatDateTime(_lastBackupDate!)
                  : 'Never',
              Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: _performBackup,
          icon: const Icon(Icons.cloud_upload),
          label: const Text('Backup Now'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        OutlinedButton.icon(
          onPressed: _performRestore,
          icon: const Icon(Icons.cloud_download),
          label: const Text('Restore from Backup'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
          ),
        ),
        if (_lastBackupDate != null) ...[
          const SizedBox(height: AppTheme.spacingM),
          OutlinedButton.icon(
            onPressed: _deleteBackup,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Backup'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF44336),
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSetupStep(String number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
