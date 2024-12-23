import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:test2/function/ddubuck/ddubuck_1/ddubuck.dart';
import 'calendar_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RecordPage extends StatefulWidget {
  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<ExerciseRecord>> _groupedRecords = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExerciseRecords();
  }

  Future<void> _loadExerciseRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? recordsAsJson = prefs.getStringList('exercise_records');

    if (recordsAsJson != null) {
      List<ExerciseRecord> records = recordsAsJson.map((recordJson) {
        Map<String, dynamic> recordMap = jsonDecode(recordJson);
        return ExerciseRecord(
          route: (recordMap['route'] as List).map((point) {
            return LatLng(point['lat'], point['lng']);
          }).toList(),
          time: Duration(seconds: recordMap['time']),
          distance: recordMap['distance'],
          date: DateTime.parse(recordMap['date']),
        );
      }).toList();

      setState(() {
        _groupExerciseRecordsByDate(records);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _groupExerciseRecordsByDate(List<ExerciseRecord> records) {
    _groupedRecords.clear();
    for (var record in records) {
      DateTime date = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      if (_groupedRecords[date] == null) {
        _groupedRecords[date] = [];
      }
      _groupedRecords[date]?.add(record);
    }
  }

  List<ExerciseRecord> _getRecordsForDay(DateTime day) {
    return _groupedRecords[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('뚜벅기록'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [

          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) {
              return _getRecordsForDay(day);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              markersAlignment: Alignment.bottomCenter,
              markerSizeScale: 0.3,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekendStyle: TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 10),

          if (_selectedDay != null)
            Expanded(
              child: ListView.builder(
                itemCount: _getRecordsForDay(_selectedDay!).length,
                itemBuilder: (context, index) {
                  final record = _getRecordsForDay(_selectedDay!)[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CalendarPage(
                            walkedRoute: record.route,
                            time: record.time,
                            distance: record.distance,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.directions_walk, size: 40, color: Colors.blue),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Text(
                                  '거리: ${record.distance.toStringAsFixed(2)} km',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),


                                Row(
                                  children: [
                                    Icon(Icons.timer, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${record.time.inMinutes}:${(record.time.inSeconds % 60).toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                Text(
                                  '날짜: ${DateFormat('yyyy-MM-dd').format(record.date)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}