import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:animate_do/animate_do.dart';
import '../services/supabase_service.dart';
import '../models/task.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Task> _tasks = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    final tasks = await _supabaseService.getTasks(
        _supabaseService.supabase.auth.currentUser!.id);
    final events = <DateTime, List<Task>>{};
    for (var task in tasks) {
      final date = task.assignedAt;
      final day = DateTime(date.year, date.month, date.day);
      if (events[day] == null) {
        events[day] = [];
      }
      events[day]!.add(task);
    }
    setState(() {
      _tasks = tasks;
      _events = events;
    });
  }

  List<Task> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Calendar'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          FadeInDown(
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: _getEventsForDay,
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FadeInUp(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: _getEventsForDay(_selectedDay!).map((task) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: ListTile(
                      title: Text(task.title),
                      subtitle: Text(task.description),
                      trailing: task.status == 'completed'
                          ? const Chip(
                        label: Text('Completed'),
                        backgroundColor: Colors.green,
                      )
                          : const Chip(
                        label: Text('Pending'),
                        backgroundColor: Colors.red,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}