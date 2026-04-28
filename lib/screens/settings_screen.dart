import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final settings = provider.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader('Notifications'),
          FutureBuilder<bool>(
            future: NotificationService().canScheduleExactAlarms(),
            builder: (context, snapshot) {
              if (snapshot.hasData && !snapshot.data!) {
                return ListTile(
                  leading: const Icon(
                    Icons.warning_outlined,
                    color: Colors.orange,
                  ),
                  title: const Text('Exact Alarm Permission Required'),
                  subtitle: const Text(
                    'Tap to grant permission for scheduled reminders',
                  ),
                  onTap: () async {
                    final granted = await NotificationService()
                        .requestExactAlarmPermission();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            granted
                                ? 'Permission granted!'
                                : 'Please enable exact alarms in system settings',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          SwitchListTile(
            title: const Text('Daily Expense Reminder'),
            subtitle: Text(
              settings.dailyReminderEnabled
                  ? 'Reminds you to record expenses at ${_formatTime(settings.reminderHour, settings.reminderMinute)}'
                  : 'Get daily reminders to track your expenses',
            ),
            secondary: const Icon(Icons.notifications_active_outlined),
            value: settings.dailyReminderEnabled,
            onChanged: (value) {
              provider.toggleDailyReminder(value);
            },
          ),
          if (settings.dailyReminderEnabled)
            ListTile(
              leading: const Icon(Icons.access_time_outlined),
              title: const Text('Reminder Time'),
              subtitle: Text(
                _formatTime(settings.reminderHour, settings.reminderMinute),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: settings.reminderHour,
                    minute: settings.reminderMinute,
                  ),
                );
                if (time != null) {
                  provider.setReminderTime(time.hour, time.minute);
                }
              },
            ),
          const Divider(),
          _buildSectionHeader('Background Notifications'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Notifications when app is closed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Scheduled reminders work even when the app is closed. '
                    'However, some devices may block background notifications due to battery optimization.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'If reminders don\'t appear when app is closed:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _buildTipItem('1. Disable battery optimization for this app'),
                  _buildTipItem(
                    '2. Allow background activity in system settings',
                  ),
                  _buildTipItem(
                    '3. Ensure "Do Not Disturb" allows notifications',
                  ),
                  _buildTipItem(
                    '4. Check that notifications are enabled for this app',
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          _buildSectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outlined),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('Description'),
            subtitle: Text(
              'Track your expenses, manage budgets, and stay on top of your finances',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 13)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
