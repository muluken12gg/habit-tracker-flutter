import "package:flutter/material.dart";
import 'package:habit_tracker/services/habit_service.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/pages/calendar_page.dart';

class Home extends StatefulWidget{
  
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final HabitService _habitService = HabitService();
  List<Habit> _habits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    try {
      final habits = await _habitService.getAllHabits();
      setState(() => _habits = habits);
    } catch (e) {
      print('Error loading habits: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addHabit(String name) async {
    if (name.trim().isEmpty) return;
    try {
      final habit = await _habitService.addHabit(name.trim());
      setState(() {
        _habits.add(habit);
      });
    } catch (e) {
      print('Error adding habit: $e');
    }
  }

  Future<void> _deleteHabit(int id) async {
    try {
      await _habitService.deleteHabit(id);
      setState(() {
        _habits.removeWhere((habit) => habit.id == id);
      });
    } catch (e) {
      print('Error deleting habit: $e');
    }
  }

  Future<void> _editHabitName(int id, String newName) async {
    if (newName.trim().isEmpty) return;
    try {
      // Delete old habit and create new one with same ID but new name
      await _habitService.deleteHabit(id);
      final updatedHabit = await _habitService.addHabit(newName.trim());
      // Replace in list
      final index = _habits.indexWhere((h) => h.id == id);
      if (index != -1) {
        setState(() {
          _habits[index] = updatedHabit;
        });
      }
    } catch (e) {
      print('Error editing habit: $e');
    }
  }

  void _showAddHabitDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Habit'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter habit name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _addHabit(controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditHabitDialog(Habit habit) {
    final controller = TextEditingController(text: habit.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Habit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new habit name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _editHabitName(habit.id, controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Habit habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.name}"? This will also delete all progress data for this habit.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteHabit(habit.id);
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text("Habit Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddHabitDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
              ? const Center(
                  child: Text(
                    'No habits yet. Tap + to add your first habit!',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _habits.length,
                  itemBuilder: (context, index) {
                    final habit = _habits[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          habit.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showEditHabitDialog(habit);
                                break;
                              case 'delete':
                                _showDeleteConfirmation(habit);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit Name'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CalendarPage(habit: habit),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}