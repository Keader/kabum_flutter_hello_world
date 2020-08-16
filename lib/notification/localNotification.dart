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

    _notifications.initialize(
        InitializationSettings(settingsAndroid, settingsIOS),
        onSelectNotification: _onSelectNotification);
  }

  Future _onSelectNotification(String payload) async {
    print(payload);
    List<String> args = payload.split("\$");
    // Handled in generateRoute method
    return locator<NavigationService>().navigateTo("AppProductDetail", arguments: PayloadArguments(args.first, args.last));
  }

  NotificationDetails get _defaultNotification {
    final androidChannelSpecifics = AndroidNotificationDetails(
      '1',
      'all',
      'send message to all members',
      importance: Importance.Max,
      priority: Priority.High,
      ongoing: false,
      autoCancel: true,
    );
    final iOSChannelSpecifics = IOSNotificationDetails();
    return NotificationDetails(androidChannelSpecifics, iOSChannelSpecifics);
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
      _showNotification(title: title, body: body, id: id, type: _defaultNotification, payload: payload);
}

// example: Provider.of<LocalNotification>(context, listen: false).showNotification(title: "Titulo", body: "Corpo");
