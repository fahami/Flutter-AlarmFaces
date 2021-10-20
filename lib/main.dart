import 'dart:math' as math;

import 'package:alarmfaces/helpers/db_helper.dart';
import 'package:alarmfaces/history.dart';
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'helpers/notification_helper.dart';
import 'models/alarm.dart';
import 'utils/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  final dir = await path_provider.getApplicationDocumentsDirectory();

  Hive
    ..init(dir.path)
    ..registerAdapter(AlarmAdapter())
    ..openBox<Alarm>('alarm');
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey(debugLabel: "Main Navigator");
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    NotificationHelper.init();
    listenNotifications();
  }

  void listenNotifications() =>
      NotificationHelper.onNotifications.stream.listen(onClickedNotification);

  void onClickedNotification(String? payload) {
    print(payload);
    final DateTime dateTimeAlarm =
        DateFormat('yyyy-MM-dd hh:mm:ss').parse(payload!);
    final DateTime dateTimeOpen = DateTime.now();
    final int differenceDate = dateTimeOpen.difference(dateTimeAlarm).inSeconds;
    print(dateTimeAlarm);
    print(dateTimeOpen);
    print(differenceDate);
    Boxes.getAlarm().add(Alarm(dateTimeAlarm, differenceDate));
    this.navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => HistoryAlarm(
              history: Alarm(dateTimeAlarm, differenceDate),
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
      navigatorKey: navigatorKey,
    );
  }
}

class ClockPainter extends CustomPainter {
  final DateTime _dateTime;

  ClockPainter(this._dateTime);
  @override
  void paint(Canvas canvas, Size size) {
    double centerX = size.width / 2;
    double centerY = size.width / 2;
    Offset center = Offset(centerX, centerY);

    // hour dial
    var hourX = centerX +
        size.width * 0.25 * math.cos(_dateTime.hour * 30 * math.pi / 180);
    var hourY = centerX +
        size.width * 0.25 * math.sin(_dateTime.hour * 30 * math.pi / 180);
    canvas.drawLine(
        center,
        Offset(hourX, hourY),
        Paint()
          ..color = Colors.grey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10);
    // minutes dial
    var minX = centerX +
        size.width * 0.35 * math.cos(_dateTime.minute * 6 * math.pi / 180);
    var minY = centerX +
        size.width * 0.35 * math.sin(_dateTime.minute * 6 * math.pi / 180);
    canvas.drawLine(
        center,
        Offset(minX, minY),
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10);
    // center
    canvas.drawCircle(center, 10, Paint()..color = Colors.amber);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Home extends StatefulWidget {
  Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Color colorDial = Colors.amber;

  final ValueNotifier<DateTime> _dateTime = ValueNotifier(DateTime.now());

  String alarmText(DateTime date) {
    return DateFormat.jm().format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Text(
              'Alarm',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            ValueListenableBuilder<DateTime>(
              valueListenable: _dateTime,
              builder: (context, value, child) => Text(
                alarmText(value),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await AndroidAlarmManager.oneShotAt(
                      _dateTime.value,
                      1,
                      BackgroundService.callback,
                      wakeup: true,
                      rescheduleOnReboot: true,
                      exact: true,
                      alarmClock: true,
                    );
                  },
                  child: Text('SET ALARM'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await AndroidAlarmManager.cancel(1);
                  },
                  child: Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HistoryAlarm(),
                        ));
                  },
                  child: Text('History'),
                )
              ],
            ),
            Expanded(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        margin: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 64,
                              color: Colors.grey.withOpacity(0.5),
                              offset: const Offset(0, 0),
                            )
                          ],
                        ),
                        child: ValueListenableBuilder<DateTime>(
                          valueListenable: _dateTime,
                          builder: (context, _date, child) => Transform.rotate(
                            angle: -math.pi / 2,
                            child: CustomPaint(
                              painter: ClockPainter(_date),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        _dateTime.value = _dateTime.value
                            .add(Duration(hours: details.delta.dy.round()));
                      },
                      onHorizontalDragUpdate: (details) {
                        _dateTime.value = _dateTime.value
                            .add(Duration(minutes: details.delta.dx.round()));
                      },
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              height: 20,
                              width: 30,
                              color: Colors.brown[800],
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              height: 25,
                              width: 10,
                              color: Colors.brown,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    Hive.close();
  }
}
