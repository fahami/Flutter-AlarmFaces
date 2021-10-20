import 'dart:isolate';

import 'dart:ui';

import 'package:alarmfaces/helpers/notification_helper.dart';
import 'package:intl/intl.dart';

final ReceivePort port = ReceivePort();

class BackgroundService {
  static BackgroundService? _service;
  static String _isolateName = 'isolate';
  static SendPort? _uiSendPort;

  BackgroundService._createObject();
  factory BackgroundService() {
    return _service ?? BackgroundService._createObject();
  }
  void initializeService() {
    IsolateNameServer.registerPortWithName(port.sendPort, _isolateName);
  }

  static Future<void> callback() async {
    print('Alarm fired!');
    final NotificationHelper _notificationHelper = NotificationHelper();
    await _notificationHelper.showNotification(
        title: 'Alarm berakhir!',
        body:
            'Alarm anda telah bunyi di ${DateFormat.Hms().format(DateTime.now())}',
        payload: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()));

    _uiSendPort ??= IsolateNameServer.lookupPortByName(_isolateName);
    _uiSendPort?.send(null);
  }
}
