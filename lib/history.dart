import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HistoryAlarm extends StatefulWidget {
  const HistoryAlarm({Key? key}) : super(key: key);

  @override
  State<HistoryAlarm> createState() => _HistoryAlarmState();
}

class _HistoryAlarmState extends State<HistoryAlarm> {
  List<AlarmOpened> dataSource = [
    AlarmOpened(DateTime.now(), 200),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final alarmData = Hive.box('alarm');
          alarmData.add(AlarmOpened(DateTime.now(), 100));
          print(alarmData.values);
        },
        child: Text('Add'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                  visibleMaximum: DateTime.now(),
                  visibleMinimum:
                      DateTime.now().subtract(const Duration(days: 50))),
              zoomPanBehavior: ZoomPanBehavior(
                enablePanning: true,
                enablePinching: true,
              ),
              series: [
                ColumnSeries<AlarmOpened, DateTime>(
                  dataSource: dataSource,
                  xValueMapper: (AlarmOpened alarm, _) => alarm.date,
                  yValueMapper: (AlarmOpened alarm, _) => alarm.duration,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    Hive.close();
  }
}

class AlarmOpened {
  final DateTime date;
  final int duration;

  AlarmOpened(this.date, this.duration);
}
