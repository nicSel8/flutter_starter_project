import 'dart:convert';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_starter_project/core/core.dart';
import 'package:flutter_starter_project/utils/alert/snackbar_controller.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationController.handleRemoteNotification(
    message: message,
    background: true,
  );
}

class NotificationController {
  static Future<void> init() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: const Color(0xFF6EC818),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        ),
        NotificationChannel(
          channelKey: 'badge_channel',
          channelName: 'Badge indicator notifications',
          channelDescription:
              'Notification channel to activate badge indicator',
          channelShowBadge: true,
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.green,
          importance: NotificationImportance.High,
        ),
      ],
    );
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> isNotificationAllowed() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      RouteApp.routemaster.push('/notificationpermission');
    } else {
      listen();
    }
  }

  static void listen() {
    FirebaseMessaging.instance.getToken().then(
      (token) {
        debugPrint('FCMTOKEN: $token');
      },
    );

    AwesomeNotifications().actionStream.listen(
      (receivedNotification) {
        if (Platform.isIOS) {
          AwesomeNotifications().getGlobalBadgeCounter().then(
                (value) =>
                    AwesomeNotifications().setGlobalBadgeCounter(value - 1),
              );
        }

        if (receivedNotification.payload?['redirect'] != null) {
          RouteApp.routemaster.push(
            '${receivedNotification.payload?['redirect']}',
          );
          return;
        }

        RouteApp.routemaster.push(
          '/notification?title=${receivedNotification.title}&subtitle=${receivedNotification.id}&description=${receivedNotification.payload}',
        );
      },
    );

    AwesomeNotifications().createdStream.listen(
      (notification) {
        SnackBarController.showSnackbar(
          'Notification Created on ${notification.channelKey}',
        );
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      /* print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}'); */
      await handleRemoteNotification(message: message);
    });
  }

  static Future<void> handleRemoteNotification({
    required RemoteMessage message,
    bool background = false,
  }) async {
    if (message.notification != null) {
      return;
    } else {
      //await AwesomeNotifications().createNotificationFromJsonData(message.data);
      final content = jsonDecode(message.data['content']);
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: content['id'],
          channelKey: content['channelKey'],
          title: content['title'],
          body: content['body'],
          payload: message.data.map(
            (key, value) => MapEntry(
              key,
              content['payload'].toString(),
            ),
          ),
        ),
      );
    }
  }

  static Future<void> createBasicNotification() async {
    /* final interval = NotificationInterval(
      interval: 5,
    ); */
    /* final calendar = NotificationCalendar(
       weekday: notificationSchedule.dayOfTheWeek,
      hour: notificationSchedule.timeOfDay.hour,
      minute: notificationSchedule.timeOfDay.minute,
      second: 0,
      millisecond: 0,
    );*/
    await AwesomeNotifications().createNotification(
      //schedule: calendar,
      content: NotificationContent(
        id: 1,
        channelKey: 'basic_channel',
        title: 'Simple Notification',
        body: 'Simple body',
        payload: {'a': 'b'},
      ),
    );
  }

  static Future<void> createBadgeNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: 'badge_channel',
        title: 'Badge test notification',
        body: 'This notification does activate badge indicator',
      ),
    );
  }

  static Future<void> createRedirectNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'basic_channel',
        title: 'Redirect Notification',
        body: 'Redirect body',
        payload: {'redirect': '/settings'},
      ),
    );
  }

  static void dispose() {
    AwesomeNotifications().actionSink.close();
    AwesomeNotifications().createdSink.close();
  }
}
