import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kabumflutterhelloworld/notification/locator.dart';

import 'navigationService.dart';

class PayloadArguments {
  final String name;
  final String code;

  PayloadArguments(this.name, this.code);
}

class LocalNotification {
  final _notifications = FlutterLocalNotificationsPlugin();

  LocalNotification() {
    _setupNotification();
  }

  void _setupNotification() {
    final settingsAndroid = AndroidInitializationSettings('ic_notification');
    final settingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: (id, title, body, payload) =>
            _onSelectNotification(payload));
    final initializationSettingsMacOS = MacOSInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false);

    _notifications.initialize(
        InitializationSettings(
            android: settingsAndroid,
            iOS: settingsIOS,
            macOS: initializationSettingsMacOS),
        onSelectNotification: _onSelectNotification);
  }

  Future _onSelectNotification(String payload) async {
    print(payload);
    List<String> args = payload.split("¨");
    // Handled in generateRoute method
    return locator<NavigationService>().navigateTo("AppProductDetail", arguments: PayloadArguments(args.first, args.last));
  }

  Future<NotificationAppLaunchDetails> launchDetails() {
    return _notifications.getNotificationAppLaunchDetails();
  }

  NotificationDetails _defaultNotification(String title, String body) {
    final bigTextStyleInformation = BigTextStyleInformation(body
        ,
        htmlFormatBigText: true,
        contentTitle: '<b>$title</b>',
        htmlFormatContentTitle: true,
        summaryText: '<i>atualização de produto</i>',
        htmlFormatSummaryText: true);
    final androidChannelSpecifics = AndroidNotificationDetails(
      '1',
      'all',
      'send message to all members',
      icon: 'ic_notification',
      largeIcon: DrawableResourceAndroidBitmap('ic_notification'),
      color: const Color.fromARGB(255, 255, 0, 0),
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
      styleInformation: bigTextStyleInformation
    );
    final iOSChannelSpecifics = IOSNotificationDetails();
    final mac = MacOSNotificationDetails();
    return NotificationDetails(android: androidChannelSpecifics, iOS: iOSChannelSpecifics, macOS: mac);
  }

  Future _showNotification({
    @required String title,
    @required String body,
    @required NotificationDetails type,
    int id = 0,
    String payload
  }) =>
      _notifications.show(id, title, body, type, payload: payload);

  Future showNotification({
    @required String title,
    @required String body,
    int id = 0,
    String payload = ""
  }) =>
      _showNotification(title: title, body: body, id: id, type: _defaultNotification(title, body), payload: payload);
}
