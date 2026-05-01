# My Expenses — Personal Finance Manager

A clean, minimal expense tracking, budget planning, and task management app built with Flutter. Designed for personal use with offline-first local storage and optional cloud backup.

**Free & Open Source** · **No Ads** · **No Tracking** · **No Data Collection**

## About

My Expenses helps you take control of your personal finances without compromising your privacy. All your data stays on your device — no accounts required, no data sent anywhere. If you want, you can optionally back up to the cloud using your Google account.

The app is built with a minimal black and white design, focused on simplicity and ease of use. It runs entirely offline and is lightweight on storage and battery.

## Features

### Expense Tracking
- Track personal expenses and company refunds separately
- 14+ predefined categories with support for custom categories
- Add descriptions, dates, and organize by category or type
- Swipe-to-delete with undo

### Analytics Dashboard
- Pie chart for expense distribution
- Line chart for monthly spending trends
- Top spending categories with progress bars
- Personal vs company refund breakdown
- Quick summary cards

### Budget Planner
- Set budgets per category with custom date ranges
- Track spending against budget limits
- Visual progress indicators and over-budget warnings

### Organization Management
- Create and manage companies/organizations
- Track refunds owed per organization
- Store contact info and view all related expenses

### Account Management
- Main account with balance tracking
- Multiple accounts with transfer support
- Transaction history

### Tasks & Notes
- Tasks with priorities (Low / Medium / High / Urgent) and due dates
- Notes with pinning and rich text support
- Overdue task alerts

### Notifications
- Daily and weekly expense reminders
- Budget alerts when approaching or exceeding limits
- Task due date reminders
- Low balance and negative balance warnings
- All notifications are local — no server communication

### Backup & Restore
- **Local backup:** Export/import your data as JSON files
- **Cloud backup (optional):** Sign in with Google to back up to Firebase Firestore
- Restore data on a new device by signing in with the same Google account

## Tech Stack

- **Flutter** — Cross-platform UI framework
- **Provider** — State management
- **Hive** — Local NoSQL database (offline-first)
- **Firebase Auth + Firestore** — Optional cloud backup
- **Google Sign-In** — Authentication for cloud backup
- **fl_chart** — Charts and graphs
- **flutter_local_notifications** — Scheduled local notifications
- **flutter_animate** — Animations
- **flutter_quill** — Rich text editor for notes

## Getting Started

### Prerequisites

- Flutter SDK 3.9.2+
- Android Studio or VS Code
- An Android device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd expense_tracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Setup (Optional)

Cloud backup requires a Firebase project. See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for a step-by-step guide.

Google Sign-In setup is documented in [GOOGLE_SIGNIN_SETUP.md](GOOGLE_SIGNIN_SETUP.md).

The app works fully without Firebase — all core features run offline.

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart        # Firebase configuration
├── models/                      # Data models (expense, budget, task, note, etc.)
├── providers/                   # State management (AppProvider, ThemeProvider)
├── screens/                     # UI screens
├── widgets/                     # Reusable UI components
├── services/                    # Storage, backup, notifications
│   ├── storage_service.dart     # Hive local database
│   ├── backup_service.dart      # Firebase cloud backup
│   ├── local_backup_service.dart # JSON file import/export
│   └── notification_service.dart # Local notifications
├── analytics/                   # Analytics dashboard
├── budget/                      # Budget planner
├── expenses/                    # Expense management
├── notes_tasks/                 # Tasks and notes
├── organizations/               # Organization management
├── firebase/                    # Firebase integration
└── utils/                       # Theme, constants, utilities
```

## Permissions

The app requests only the permissions it needs:

- **Notifications** — Local reminders and alerts
- **Exact Alarms** — Precise scheduling for daily/weekly reminders
- **Boot Completed** — Reschedule notifications after device restart
- **Vibrate / Wake Lock** — Notification delivery

No internet permission is required for core functionality. Internet is only used if you opt in to cloud backup.

## Privacy

- All data stored locally on your device
- No ads, no analytics, no tracking
- No data shared with third parties
- Optional cloud backup is secured per-user via Firebase
- Full details in [PRIVACY_POLICY.md](PRIVACY_POLICY.md)

## Contributing

Contributions are welcome. Feel free to open issues or submit pull requests.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

**Made with Flutter**
