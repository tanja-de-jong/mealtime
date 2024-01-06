import 'package:flutter/material.dart';
import 'package:mealtime/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceList extends StatefulWidget {
  const PresenceList({super.key});

  @override
  PresenceListState createState() => PresenceListState();
}

class PresenceListState extends State<PresenceList> {
  DateTime date = DateTime.now();
  final List<String> _presence = ['niemand', 'Mattanja', 'Tanja', 'allebei'];
  final Map<int, String> _selectedLunch = {};
  final Map<int, String> _selectedDinner = {};
  final List<String> weekdays = [
    'maandag',
    'dinsdag',
    'woensdag',
    'donderdag',
    'vrijdag',
    'zaterdag',
    'zondag'
  ];
  bool dataExists = false;

  String getWeekLabel() {
    DateTime now = DateTime.now();
    int week = weekOfYear(date);
    int year = date.year;
    return now.year == year ? 'Week $week' : 'Week $year-$week';
  }

  setDefaultPresence() {
    setState(() {
      for (var i = 1; i <= 7; i++) {
        _selectedLunch[i] = 'Tanja';
        _selectedDinner[i] = _presence.last;
      }
      // Set selected lunch to Mattanja on Tuesday and Friday and to 'beide' on Saturday and Sunday
      _selectedLunch[2] = 'Mattanja';
      _selectedLunch[5] = 'Mattanja';
      _selectedLunch[6] = 'allebei';
      _selectedLunch[7] = 'allebei';
    });
  }

  Future<void> getPresenceData() async {
    int week = weekOfYear(date);
    int year = date.year;
    DocumentSnapshot<Map<String, dynamic>> document = await FirebaseFirestore
        .instance
        .collection('weeks')
        .doc('$year-$week')
        .get();

    if (document.exists) {
      dataExists = true;
      Map<String, dynamic> presenceData =
          document.data() as Map<String, dynamic>;
      setState(() {
        for (int i = 1; i <= 7; i++) {
          String day = i.toString();
          if (presenceData.containsKey(day)) {
            if (presenceData[day]['lunch'] != null) {
              _selectedLunch[i] =
                  _presence[presenceData[day]['lunch']['presence']];
            }
            if (presenceData[day]['diner'] != null) {
              _selectedDinner[i] =
                  _presence[presenceData[day]['diner']['presence']];
            }
          }
        }
      });
    } else {
      dataExists = false;
      setDefaultPresence();
    }
  }

  Future<void> savePresenceData() async {
    int week = weekOfYear(date);
    int year = date.year;
    Map<String, Map<String, dynamic>> data = {};

    for (int i = 1; i <= 7; i++) {
      data[i.toString()] = {
        'lunch': {'presence': _presence.indexOf(_selectedLunch[i]!)},
        'diner': {'presence': _presence.indexOf(_selectedDinner[i]!)},
      };
    }

    await FirebaseFirestore.instance
        .collection('weeks')
        .doc('$year-$week')
        .set(data, SetOptions(merge: true));
  }

  @override
  void initState() {
    super.initState();
    setDefaultPresence();
    getPresenceData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aanwezigheid'),
        actions: <Widget>[
          ElevatedButton(
            onPressed: savePresenceData,
            child: const Text("Opslaan"),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (dataExists) return Colors.green;
                  return Colors.transparent; // Use the component's default.
                },
              ),
            ),
          ),
        ],
      ),
      body: Center(
          child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                setState(() {
                  date = date.subtract(const Duration(days: 7));
                });
                getPresenceData();
              },
              child: const Text('Vorige week'),
            ),
            const SizedBox(width: 20),
            Text(getWeekLabel()),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  date = date.add(const Duration(days: 7));
                });
                getPresenceData();
              },
              child: const Text('Volgende week'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
            child: ListView.builder(
          itemCount: 7,
          itemBuilder: (context, index) {
            int day = index + 1;
            String dayLabel = weekdays[index];
            return Card(
              child: ListTile(
                title: Text(dayLabel[0].toUpperCase() + dayLabel.substring(1)),
                subtitle: Column(
                  children: [
                    Row(children: [
                      const SizedBox(width: 100, child: Text('Lunch')),
                      const SizedBox(width: 10),
                      SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<String>(
                            value: _selectedLunch[day],
                            decoration: InputDecoration(
                              // Add Horizontal padding using menuItemStyleData.padding so it matches
                              // the menu padding when button's width is not specified.
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              // Add more decoration..
                            ),
                            items: _presence
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedLunch[day] = newValue!;
                              });
                            },
                          ))
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      const SizedBox(width: 100, child: Text('Diner')),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String>(
                          value: _selectedDinner[day],
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          items: _presence
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedDinner[day] = newValue!;
                            });
                          },
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            );
          },
        ))
      ])),
    );
  }
}
