import 'package:flutter/material.dart';

class FirstAidPage extends StatelessWidget {
  final List<Map<String, String>> tips = [
    {
      'title': 'Bleeding',
      'description': 'Apply pressure with a clean cloth. Seek medical help if bleeding continues.'
    },
    {
      'title': 'Burns',
      'description': 'Cool the burn under running water. Do not apply ice. Cover loosely with a sterile cloth.'
    },
    {
      'title': 'Fractures',
      'description': 'Immobilize the area. Do not try to straighten the bone. Get medical help immediately.'
    },
    {
      'title': 'CPR',
      'description': 'Check responsiveness. Call for help. Begin chest compressions until help arrives.'
    },
    {
      'title': 'Choking',
      'description': 'Perform the Heimlich maneuver if person is choking and unable to breathe or speak.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("First Aid Tips"), backgroundColor: Colors.green),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: tips.length,
        itemBuilder: (context, index) {
          final tip = tips[index];
          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.healing, color: Colors.green),
              title: Text(tip['title']!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(tip['description']!, style: TextStyle(fontSize: 15)),
              ),
            ),
          );
        },
      ),
    );
  }
}
