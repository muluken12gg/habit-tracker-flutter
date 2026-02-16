import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main(){
  runApp(MyApp());
}

class MyApp extends StatelessWidget{

  @override
  Widget build(BuildContext context){

  return MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Habit Traaaaaaacker',
    home: HabitListPage(),
  );
  }
}

class HabitListPage extends StatelessWidget{
  final List<String> habits = [
    "reading",
    "pushup",
    "meditation",
    "morning routine"
  ];

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('Habit Tracker'),
      ),
      body: ListView.builder(
        itemCount: habits.length,
        itemBuilder: (context, index){
          return ListTile(
            title: Text(habits[index]),
            trailing: Icon(Icons.arrow_forward_ios_sharp),
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                    HabitDetailPage(habitName: habits[index]),
                ),
              );
            }
          );
        }
      )
    );
  }
}

class HabitDetailPage extends StatefulWidget{
  final String habitName;

  HabitDetailPage({required this.habitName});

  @override
  _HabitDetailPageState createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends State<HabitDetailPage>{
  
    int selectedDay = DateTime.now().day;

    Map<int, int>dailyValues = {};
    TextEditingController controller = TextEditingController();

    @override
    void initState(){
      super.initState();
      loadData();
    }

    Future<void> loadData() async{
      final prefs = await SharedPreferences.getInstance();
      String? data = prefs.getString(widget.habitName);

      if (data != null){
        Map<String, dynamic> decoded = jsonDecode(data);
        setState(() {
          dailyValues = decoded.map(
            (key, value) => MapEntry(int.parse(key), value),
          );
        });
      }
    }

    Future<void> saveData() async{
      final prefs = await SharedPreferences.getInstance();
      String encoded = jsonEncode(dailyValues);
      await prefs.setString(widget.habitName, encoded);
    }

    @override
    Widget build(BuildContext context){
      final int daysInMonth = DateTime(
        DateTime.now().year,
        DateTime.now().month + 1,
        0,
      ).day;

      final DateTime firstDayOfMonth =
        DateTime(DateTime.now().year, DateTime.now().month, 1);
      int startWeekday = firstDayOfMonth.weekday - 1;

      final DateTime now = DateTime.now();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habitName)
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text (
              "${DateTime.now().year} - ${DateTime.now().month}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontWeight: FontWeight.w600
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
              ),
            SizedBox(height: 12),
            Expanded(
              child: GridView.builder(

                itemCount: daysInMonth + startWeekday,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),

                itemBuilder: (context, index){
                  if (index < startWeekday){
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(11),
                      ),
                    );
                  }
                  int day = index - startWeekday + 1;
                  int? value = dailyValues[day];
                  bool isSelected = day == selectedDay;

                  bool isToday =
                    day == now.day &&
                    now.month == DateTime.now().month &&
                    now.year == DateTime.now().year;

                  return GestureDetector(
                    onTap: (){
                      setState((){
                        selectedDay = day;
                      });
                    },
                    
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                          ? Colors.black
                          : isToday
                            ? Colors.grey.shade300
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: !isSelected && isToday
                          ? Border.all(color: Colors.black, width: 1)
                          : null
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (value != null) 
                            Text(
                              value.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white70 : Colors.black54,
                              )
                            ),
                        ]
                      ),
                    ),
                  );
                }
              ),
            ),
            SizedBox(height: 12),

            Text(
              "Day $selectedDay",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
            ),

            SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Enter value",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12)
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    int? value = int.tryParse(controller.text);
                    if (value != null){
                      setState(() {
                        dailyValues[selectedDay] = value;
                      });
                      await saveData();
                      controller.clear();
                    }
                  },
                  child: Text("Save"),
                )
              ],
            )
          ]
        ),
      ),
    );
  }
}