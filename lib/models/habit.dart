import 'package:hive/hive.dart';

class Habit {
  int id;
  String name;

  Habit({required this.id, required this.name});
}

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    return Habit(
      id: reader.readInt(),
      name: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.name);
  }
}
