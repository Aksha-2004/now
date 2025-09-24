import 'package:flutter/material.dart';

class EmergencyContactsPage extends StatelessWidget {
  final List<Map<String, String>> contacts = [
    {'title': 'Police', 'number': '100'},
    {'title': 'Ambulance', 'number': '108'},
    {'title': 'Fire Station', 'number': '101'},
    {'title': 'Disaster Helpline', 'number': '1078'},
    {'title': 'Child Helpline', 'number': '1098'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Emergency Contacts"), backgroundColor: Colors.red),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.phone, color: Colors.red),
              title: Text(contact['title']!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              trailing: Text(contact['number']!, style: TextStyle(fontSize: 16)),
            ),
          );
        },
      ),
    );
  }
}
