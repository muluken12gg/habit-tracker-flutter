import "package:flutter/material.dart";
import 'package:table_calendar/table_calendar.dart';
import 'package:habit_tracker/services/habit_service.dart';
import 'package:habit_tracker/models/habit.dart';

class CalendarPage extends StatefulWidget {
  final Habit habit;

  const CalendarPage({super.key, required this.habit});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final HabitService _habitService = HabitService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, int> _progressData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    try {
      final progress = await _habitService.getProgressForHabit(
        widget.habit.id,
        _focusedDay,
      );
      setState(() => _progressData = progress);
    } catch (e) {
      debugPrint('Error loading progress: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateEntry(DateTime date, int value) async {
    try {
      final entries = await _habitService.getEntriesForHabit(widget.habit.id, date);
      if (entries.isNotEmpty) {
        await _habitService.updateEntry(entries.first.id, value);
      } else {
        await _habitService.addEntry(widget.habit.id, value, date);
      }
      await _loadProgress();
    } catch (e) {
      debugPrint('Error updating entry: $e');
    }
  }

  void _showEntryDialog(DateTime date) {
    // Only allow editing today's date
    final today = DateTime.now();
    final isToday = date.year == today.year &&
                   date.month == today.month &&
                   date.day == today.day;

    if (!isToday) {
      // Show read-only dialog for past/future dates
      final value = _progressData[DateTime(date.year, date.month, date.day)] ?? 0;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Progress for ${date.day}/${date.month}/${date.year}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Value: $value/10'),
              const SizedBox(height: 16),
              Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[300],
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value / 10.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: value > 0 ? Colors.green.shade400 : Colors.transparent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You can only edit today\'s progress',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Allow editing today's date
    final currentValue = _progressData[DateTime(date.year, date.month, date.day)] ?? 0;
    final controller = TextEditingController(text: currentValue.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Progress for Today'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Enter value (0-10)'),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Rate your progress from 0 to 10',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text) ?? 0;
              if (value >= 0 && value <= 10) {
                _updateEntry(date, value);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(widget.habit.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress summary
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Today\'s Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[300],
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: (_progressData[DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)] ?? 0) / 10.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.green.shade400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${_progressData[DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)] ?? 0}/10',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Calendar
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
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
                        _showEntryDialog(selectedDay);
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                        _loadProgress();
                      },
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Colors.blue.shade300,
                          shape: BoxShape.circle,
                        ),
                        weekendTextStyle: const TextStyle(color: Colors.red),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final date = DateTime(day.year, day.month, day.day);
                          final value = _progressData[date] ?? 0;

                          Color? backgroundColor;
                          if (value > 0) {
                            final intensity = value / 10.0;
                            backgroundColor = Color.lerp(
                              Colors.white,
                              Colors.green.shade400,
                              intensity,
                            );
                          }

                          return Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSameDay(date, DateTime.now())
                                    ? Colors.amber
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: value > 5 ? Colors.white : Colors.black,
                                  fontWeight: isSameDay(date, DateTime.now())
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Legend
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Tap today to update progress • View past days to see history',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}