import 'package:flutter/material.dart';

enum ScheduleType { pending, tentative, final_, resolved, name }

class ScheduleEvent {
  final String name;
  final ScheduleType type;

  ScheduleEvent({required this.name, required this.type});

  Color get color {
    switch (type) {
      case ScheduleType.pending:
        return const Color(0xFF5B9BD5); // Blue
      case ScheduleType.tentative:
        return const Color(0xFFFFA500); // Orange
      case ScheduleType.final_:
        return const Color(0xFFE74C3C); // Red
      case ScheduleType.resolved:
        return const Color(0xFF27AE60); // Green
      case ScheduleType.name:
        return const Color(0xFF95A5A6); // Gray
    }
  }
}
