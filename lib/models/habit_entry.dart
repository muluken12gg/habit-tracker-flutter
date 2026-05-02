import 'package:hive/hive.dart';

class HabitEntry {
  int id;
  int habitId;
  int value;
  DateTime date;

  HabitEntry({
    required this.id,
    required this.habitId,
    required this.value,
    required this.date,
  });
}

class HabitEntryAdapter extends TypeAdapter<HabitEntry> {
  @override
  final int typeId = 1;

  @override
  HabitEntry read(BinaryReader reader) {
    return HabitEntry(
      id: reader.readInt(),
      habitId: reader.readInt(),
      value: reader.readInt(),
      date: reader.read() as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HabitEntry obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.habitId);
    writer.writeInt(obj.value);
    writer.write(obj.date);
  }
}
