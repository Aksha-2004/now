import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserListPage extends StatelessWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All Registered Users"),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("❌ Error loading users"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No users found."));
          }

          // Remove duplicates
          final seenUids = <String>{};
          final uniqueUsers = snapshot.data!.docs.where((doc) {
            final uid = doc.id;
            if (seenUids.contains(uid)) {
              return false;
            } else {
              seenUids.add(uid);
              return true;
            }
          }).toList();

          // Sort manually by timestamp (safely)
          uniqueUsers.sort((a, b) {
            final aTime = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final bTime = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bTime.compareTo(aTime); // descending
          });

          return ListView.builder(
            itemCount: uniqueUsers.length,
            itemBuilder: (context, index) {
              final data = uniqueUsers[index].data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 3,
                child: ListTile(
                  leading: Icon(Icons.person, color: Colors.red),
                  title: Text(data['username'] ?? 'Unknown'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['email'] != null) Text("📧 ${data['email']}"),
                      if (data['place'] != null) Text("📍 Place: ${data['place']}"),
                      if (data['phone'] != null) Text("📞 Phone: ${data['phone']}"),
                      if (data['address'] != null) Text("🏠 Address: ${data['address']}"),
                      if (data['gender'] != null) Text("👤 Gender: ${data['gender']}"),
                      if (data['age'] != null) Text("🎂 Age: ${data['age']}"),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
