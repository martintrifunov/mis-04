import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class Exam {
  String? name;
  DateTime? date;
  TimeOfDay? time;

  Exam({this.name, this.date, this.time});

  factory Exam.fromJson(Map<String, dynamic> jsonData) {
    return Exam(name: jsonData['name'], date: jsonData['date'] == null ? null : DateTime.parse(jsonData['date']), time: jsonData['time'] == null ? null : TimeOfDay(hour: int.parse(jsonData['time'].split(":")[0]), minute: int.parse(jsonData['time'].split(":")[1].split(" ")[0])));
  }

  static Map<String, dynamic> toMap(Exam exam) => {
    'name': exam.name,
    'date': exam.date == null ? null : exam.date?.toIso8601String(),
    'time': exam.time == null ? null : formatTimeOfDay(exam.time!)
  };

  static String encode(List<Exam> exams) => json.encode(
    exams.map<Map<String, dynamic>>((exam) => Exam.toMap(exam)).toList(),
  );

  static List<Exam> decode(String exams) => (json.decode(exams) as List<dynamic>).map<Exam>((item) => Exam.fromJson(item)).toList();

  static String formatTimeOfDay(TimeOfDay tod) {
    final now = new DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final format = DateFormat.jm();
    return format.format(dt);
  }
}
