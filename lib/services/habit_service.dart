import 'package:hive/hive.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/habit_entry.dart';

class HabitService {
  static const String _habitsBox = 'habits';
  static const String _entriesBox = 'entries';

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HabitAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(HabitEntryAdapter());
    await Hive.openBox<Habit>(_habitsBox);
    await Hive.openBox<HabitEntry>(_entriesBox);
  }

  Box<Habit> get _habits => Hive.box<Habit>(_habitsBox);
  Box<HabitEntry> get _entries => Hive.box<HabitEntry>(_entriesBox);

  Future<List<Habit>> getAllHabits() async {
    return _habits.values.toList();
  }

  Future<Habit> addHabit(String name) async {
    final habits = _habits.values.toList();
    final newId = habits.isEmpty ? 1 : habits.map((h) => h.id).reduce((a, b) => a > b ? a : b) + 1;
    final habit = Habit(id: newId, name: name);
    await _habits.put(habit.id, habit);
    return habit;
  }

  Future<void> deleteHabit(int id) async {
    await _habits.delete(id);
    final entries = _entries.values.where((e) => e.habitId == id).toList();
    for (final entry in entries) {
      await _entries.delete(entry.id);
    }
  }

  Future<List<HabitEntry>> getEntriesForHabit(int habitId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _entries.values.where((e) =>
      e.habitId == habitId &&
      !e.date.isBefore(startOfDay) &&
      e.date.isBefore(endOfDay)
    ).toList();
  }

  Future<void> addEntry(int habitId, int value, DateTime date) async {
    final entries = _entries.values.toList();
    final newId = entries.isEmpty ? 1 : entries.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    final entry = HabitEntry(id: newId, habitId: habitId, value: value, date: date);
    await _entries.put(entry.id, entry);
  }

  Future<void> updateEntry(int entryId, int value) async {
    final entry = _entries.get(entryId);
    if (entry != null) {
      entry.value = value;
      await _entries.put(entryId, entry);
    }
  }

  Future<void> deleteEntry(int entryId) async {
    await _entries.delete(entryId);
  }

  Future<Map<DateTime, int>> getProgressForHabit(int habitId, DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);

    final progress = <DateTime, int>{};
    for (final entry in _entries.values) {
      if (entry.habitId == habitId &&
          !entry.date.isBefore(startOfMonth) &&
          entry.date.isBefore(endOfMonth)) {
        final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
        progress[date] = entry.value;
      }
    }
    return progress;
  }
}
