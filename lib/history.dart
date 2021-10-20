import 'dart:developer';

import 'package:alarmfaces/helpers/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/alarm.dart';

class HistoryAlarm extends StatelessWidget {
  final Alarm? history;
  HistoryAlarm({Key? key, this.history}) : super(key: key);
  final parseDate = DateFormat('yyyy-MM-dd');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Riwayat Alarm',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Container(
            child: ValueListenableBuilder<Box<Alarm>>(
              valueListenable: Boxes.getAlarm().listenable(),
              builder: (context, box, child) {
                final alarmDb = box.values.toList().cast<Alarm>();
                return SfCartesianChart(
                  isTransposed: true,
                  enableAxisAnimation: true,
                  primaryXAxis: DateTimeCategoryAxis(
                    title: AxisTitle(text: 'Tanggal Waktu Alarm dibuat'),
                    dateFormat: DateFormat('yyyy-MM-dd HH:mm:ss'),
                    opposedPosition: true,
                  ),
                  primaryYAxis: NumericAxis(
                      opposedPosition: true,
                      title: AxisTitle(text: 'Durasi Alarm dibuka (detik)')),
                  zoomPanBehavior: ZoomPanBehavior(
                    enablePanning: true,
                    enablePinching: true,
                    enableDoubleTapZooming: true,
                  ),
                  series: [
                    BarSeries<Alarm, DateTime>(
                      dataSource: alarmDb,
                      xValueMapper: (Alarm alarm, _) => alarm.date,
                      yValueMapper: (Alarm alarm, _) => alarm.duration,
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
