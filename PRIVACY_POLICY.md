# Privacy Policy

**Last updated:** May 01, 2026

**My Expenses** ("the App") is a free, open-source personal finance management application. This privacy policy explains how the App handles your information.

## Developer

This App is developed and maintained as an open-source project and is provided free of charge with no monetization.

## Data Collection and Storage

### Data You Provide

The App allows you to create and manage the following types of data:

- Expenses (title, amount, category, date, descriptions)
- Budgets (category, amount, date ranges)
- Tasks (title, description, priority, due dates)
- Notes (title, content)
- Organizations (name, description, contact email, phone)
- Accounts and transactions (account names, balances, transfers)
- App settings and preferences

### Local Storage

**All data is stored locally on your device** using Hive, an offline-first local database. The App functions entirely offline and does not require an internet connection for its core features. No data leaves your device unless you explicitly use the optional cloud backup feature.

### Optional Cloud Backup (Google Sign-In & Firebase)

If you choose to use the cloud backup feature, the following applies:

- **Authentication:** You sign in with your Google account. The App receives your Google email address and a unique user ID through Firebase Authentication.
- **Data backup:** Your app data (expenses, budgets, tasks, notes, organizations, and settings) is uploaded to Google Firebase Firestore, associated with your user ID.
- **Access control:** Only you can access your backed-up data. Firestore security rules ensure that each user can only read and write their own data.
- **This feature is entirely optional.** The App works fully without signing in or backing up.

## Permissions

The App requests the following device permissions:

- **Notifications** (`POST_NOTIFICATIONS`): To send local reminders for expense tracking, task due dates, and budget alerts.
- **Boot Completed** (`RECEIVE_BOOT_COMPLETED`): To reschedule local notifications after the device restarts.
- **Vibrate** (`VIBRATE`): To vibrate when a notification is displayed.
- **Wake Lock** (`WAKE_LOCK`): To ensure scheduled notifications are delivered reliably.
- **Exact Alarm** (`SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`): To schedule notifications at precise times (daily/weekly reminders).
- **File Access** (via file picker): To import/export local backup files in JSON format. File access is only used when you explicitly initiate an import or export action.

All notifications are **local only** — the App does not use push notifications or communicate with any server for notification purposes.

## Data Sharing

- **We do not sell, trade, or share your personal data with any third parties.**
- **No advertising:** The App contains no ads and no advertising SDKs.
- **No analytics:** The App does not include any third-party analytics, tracking, or telemetry services.
- **No data collection by the developer:** The developer does not collect, access, or process any of your data.

The only external service used is **Google Firebase** (Authentication and Firestore), and only when you opt in to the cloud backup feature. Firebase is governed by [Google's Privacy Policy](https://policies.google.com/privacy).

## Data Security

- Local data is stored in the app's private storage directory on your device, accessible only to the App.
- Cloud backup data in Firebase Firestore is protected by security rules that restrict access to authenticated users viewing only their own data.
- Google Sign-In authentication is handled securely through Google's OAuth 2.0 flow.

## Data Retention and Deletion

- **Local data:** You can delete any individual record (expense, task, note, etc.) within the App at any time. Uninstalling the App removes all local data from your device.
- **Cloud backup data:** You can delete your cloud backup from within the App. You can also request full deletion of your data by contacting the developer.
- **Account deletion:** Signing out of Google removes the App's access to your Google account. You can revoke the App's access at any time via your [Google Account permissions](https://myaccount.google.com/permissions).

## Children's Privacy

The App is not directed at children under the age of 13. We do not knowingly collect personal information from children. If you believe a child has provided personal data through the App, please contact the developer so that the data can be removed.

## Changes to This Privacy Policy

This privacy policy may be updated from time to time. Any changes will be reflected in this document with an updated "Last updated" date. Continued use of the App after changes constitutes acceptance of the updated policy.

## Open Source

This App is open source. You can review the complete source code to verify the privacy practices described in this policy.

## Contact

If you have any questions or concerns about this privacy policy, please open an issue on the project's GitHub repository or contact the developer directly.

---

*This App is provided "as is" without warranty of any kind. The developer is not responsible for any data loss resulting from device failure, app uninstallation, or any other cause.*
