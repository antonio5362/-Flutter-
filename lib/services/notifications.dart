import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
 
class Notifications {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
 
  static const _dailyDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminder',
      'Напоминания о занятиях',
      channelDescription: 'Ежедневное напоминание позаниматься',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );
 
  static const _timerDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'timer_done',
      'Таймер фокуса',
      channelDescription: 'Сообщение об окончании таймера',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );
 
  static Future<void> init() async {
    try {
      const android = AndroidInitializationSettings('ic_notification');
      await _plugin.initialize(const InitializationSettings(android: android));
      _ready = true;
    } catch (e) {
      debugPrint('Уведомления не запустились: $e');
    }
  }
 
  static Future<bool> requestPermission() async {
    try {
      final impl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await impl?.requestNotificationsPermission();
      return granted ?? false;
    } catch (e) {
      debugPrint('Разрешение на уведомления: $e');
      return false;
    }
  }
 
  static tz.TZDateTime _utc(DateTime local) {
    final u = local.toUtc();
    return tz.TZDateTime.utc(u.year, u.month, u.day, u.hour, u.minute, u.second);
  }
 
  /// Ежедневное напоминание. Если сегодня уже занимались — первое придёт завтра.
  static Future<void> scheduleDaily(int minutes, {bool skipToday = false}) async {
    if (!_ready) return;
    try {
      final now = DateTime.now();
      var t = DateTime(now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
      if (skipToday || !t.isAfter(now)) {
        t = DateTime(now.year, now.month, now.day + 1, minutes ~/ 60, minutes % 60);
      }
      await _plugin.zonedSchedule(
        1,
        'Пора заниматься 📚',
        'Зайди хотя бы на 5 минут — сохрани серию дней 🔥',
        _utc(t),
        _dailyDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Не удалось запланировать напоминание: $e');
    }
  }
 
  static Future<void> cancelDaily() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(1);
    } catch (_) {}
  }
 
  static Future<void> scheduleTimerEnd(DateTime when, String text) async {
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        2,
        'Таймер фокуса',
        text,
        _utc(when),
        _timerDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Не удалось запланировать таймер: $e');
    }
  }
 
  static Future<void> cancelTimerEnd() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(2);
    } catch (_) {}
  }
}
