class Settings {
  final bool dailyReminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  Settings({
    this.dailyReminderEnabled = false,
    this.reminderHour = 20, // Default 8 PM
    this.reminderMinute = 0,
  });

  Settings copyWith({
    bool? dailyReminderEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return Settings(
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }
}
