import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> showDueNotification(
    String customerName,
    double dueAmount,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'due_channel',
          'Due Notifications',
          channelDescription:
              'Notifications for customers with pending dues over 7 days',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Overdue Payment',
      '$customerName has ₹${dueAmount.toStringAsFixed(2)} due for more than 7 days!',
      platformDetails,
    );
  }
}
