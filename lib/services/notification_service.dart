import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Africa/Blantyre')); // Malawi timezone

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        // Request permissions for Android 13+
        await _requestPermissions();

        // Create notification channels for Android
        await _createNotificationChannels();

        _initialized = true;
        print('NotificationService: Initialized successfully');
      } else {
        print('NotificationService: Initialization returned false or null');
      }
    } catch (e) {
      print('NotificationService: Error during initialization: $e');
      // Don't throw, just log the error to prevent app crash
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      // Main notification channel
      const mainChannel = AndroidNotificationChannel(
        'expense_tracker_channel',
        'Expense Tracker',
        description: 'Notifications for expense tracking and reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      // Daily reminders channel
      const dailyChannel = AndroidNotificationChannel(
        'expense_tracker_daily_channel',
        'Daily Reminders',
        description: 'Daily expense tracking reminders',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );

      // Weekly reminders channel
      const weeklyChannel = AndroidNotificationChannel(
        'expense_tracker_weekly_channel',
        'Weekly Reminders',
        description: 'Weekly expense tracking reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidPlugin.createNotificationChannel(mainChannel);
      await androidPlugin.createNotificationChannel(dailyChannel);
      await androidPlugin.createNotificationChannel(weeklyChannel);

      print('NotificationService: Notification channels created');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        // Request notification permission
        final notificationPermission = await androidPlugin
            .requestNotificationsPermission();
        print(
          'NotificationService: Notification permission granted: $notificationPermission',
        );

        // Request exact alarm permission for Android 12+
        final canScheduleExactAlarms = await androidPlugin
            .canScheduleExactNotifications();

        print(
          'NotificationService: Can schedule exact alarms: $canScheduleExactAlarms',
        );

        if (canScheduleExactAlarms == false) {
          // Request exact alarm permission
          final exactAlarmPermission = await androidPlugin
              .requestExactAlarmsPermission();
          print(
            'NotificationService: Exact alarm permission granted: $exactAlarmPermission',
          );
        }
      }

      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosPlugin != null) {
        final permissions = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('NotificationService: iOS permissions granted: $permissions');
      }
    } catch (e) {
      print('NotificationService: Error requesting permissions: $e');
      // Don't throw, just log the error
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can be used to navigate to specific screens
  }

  // Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationType? type,
  }) async {
    try {
      if (!_initialized) {
        print('NotificationService: Not initialized, attempting to initialize');
        await initialize();
      }

      const androidDetails = AndroidNotificationDetails(
        'expense_tracker_channel',
        'Expense Tracker',
        channelDescription: 'Notifications for expense tracking and reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details, payload: payload);
      print('NotificationService: Notification shown - ID: $id, Title: $title');
    } catch (e) {
      print('NotificationService: Error showing notification: $e');
    }
  }

  // Schedule notification for specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      if (!_initialized) {
        print('NotificationService: Not initialized, attempting to initialize');
        await initialize();
      }

      const androidDetails = AndroidNotificationDetails(
        'expense_tracker_channel',
        'Expense Tracker',
        channelDescription: 'Notifications for expense tracking and reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      print(
        'NotificationService: Notification scheduled - ID: $id, Time: $scheduledTime',
      );
    } catch (e) {
      print('NotificationService: Error scheduling notification: $e');
    }
  }

  // Schedule daily notification
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required Time time,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'expense_tracker_daily_channel',
      'Daily Reminders',
      channelDescription: 'Daily expense tracking reminders',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      enableLights: true,
      channelShowBadge: true,
      visibility: NotificationVisibility.public,
      ticker: 'Expense Reminder',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(time),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  // Schedule weekly notification
  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek, // 1 = Monday, 7 = Sunday
    required Time time,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'expense_tracker_weekly_channel',
      'Weekly Reminders',
      channelDescription: 'Weekly expense tracking reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfWeekday(dayOfWeek, time),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Helper methods
  tz.TZDateTime _nextInstanceOfTime(Time time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      time.second,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int dayOfWeek, Time time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      time.second,
    );

    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  // Financial alert notifications
  Future<void> showBudgetAlert({
    required String category,
    required double spent,
    required double limit,
  }) async {
    final percentage = (spent / limit * 100).toStringAsFixed(0);
    await showNotification(
      id: category.hashCode,
      title: '⚠️ Budget Alert',
      body: 'You\'ve spent $percentage% of your $category budget',
      type: NotificationType.budgetOverspent,
    );
  }

  Future<void> showLowBalanceAlert({
    required double balance,
    required double threshold,
  }) async {
    await showNotification(
      id: 1001,
      title: '💰 Low Balance Alert',
      body:
          'Your account balance is MK${balance.abs().toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
      type: NotificationType.lowBalance,
    );
  }

  Future<void> showNegativeBalanceAlert({required double balance}) async {
    await showNotification(
      id: 1002,
      title: '🚨 Negative Balance',
      body:
          'Your account balance is negative: MK-${balance.abs().toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
      type: NotificationType.accountNegative,
    );
  }

  // Task reminder notifications
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required DateTime dueDate,
  }) async {
    // Schedule 1 day before
    final reminderTime = dueDate.subtract(const Duration(days: 1));
    if (reminderTime.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: taskId.hashCode,
        title: '📋 Task Reminder',
        body: 'Task "$taskTitle" is due tomorrow',
        scheduledTime: reminderTime,
        payload: 'task:$taskId',
      );
    }

    // Schedule on due date
    if (dueDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: taskId.hashCode + 1,
        title: '📋 Task Due Today',
        body: 'Task "$taskTitle" is due today',
        scheduledTime: dueDate,
        payload: 'task:$taskId',
      );
    }
  }

  // Daily expense summary
  Future<void> scheduleDailyExpenseSummary() async {
    await scheduleDailyNotification(
      id: 2000,
      title: '📊 Daily Expense Summary',
      body: 'Check your daily spending',
      time: const Time(20, 0, 0), // 8 PM
      payload: 'summary:daily',
    );
  }

  // Daily expense reminder
  Future<void> scheduleDailyExpenseReminder({
    required int hour,
    required int minute,
  }) async {
    await scheduleDailyNotification(
      id: 3000,
      title: '💰 Expense Reminder',
      body: 'Don\'t forget to record your expenses today!',
      time: Time(hour, minute),
      payload: 'reminder:daily_expense',
    );
  }

  // Cancel daily expense reminder
  Future<void> cancelDailyExpenseReminder() async {
    await cancelNotification(3000);
  }

  // Check if can schedule exact alarms (for Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final canSchedule = await androidPlugin.canScheduleExactNotifications();
      return canSchedule ?? false;
    }

    return true; // For iOS or if check fails
  }

  // Request exact alarm permission
  Future<bool> requestExactAlarmPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final result = await androidPlugin.requestExactAlarmsPermission();
      return result ?? false;
    }

    return true; // For iOS
  }

  // Weekly expense summary
  Future<void> scheduleWeeklyExpenseSummary() async {
    await scheduleWeeklyNotification(
      id: 2001,
      title: '📊 Weekly Expense Summary',
      body: 'Review your weekly spending',
      dayOfWeek: DateTime.sunday,
      time: const Time(19, 0, 0), // 7 PM on Sunday
      payload: 'summary:weekly',
    );
  }
}

// Define a simple Time class for scheduling (hour, minute, second)
class Time {
  final int hour;
  final int minute;
  final int second;
  const Time(this.hour, this.minute, [this.second = 0]);
}
