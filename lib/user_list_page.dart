import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'translations.dart'; // ✅ Import translations

class UserListPage extends StatelessWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.getText('all_users', lang)),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                AppTranslations.getText('error_users', lang),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                AppTranslations.getText('no_users', lang),
              ),
            );
          }

          // ✅ Remove duplicates
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

          // ✅ Sort by timestamp
          uniqueUsers.sort((a, b) {
            final aTime =
                (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final bTime =
                (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            itemCount: uniqueUsers.length,
            itemBuilder: (context, index) {
              final data =
                  uniqueUsers[index].data() as Map<String, dynamic>;

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 3,
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.red),
                  title: Text(data['username'] ?? 'Unknown'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['email'] != null)
                        Text("📧 ${data['email']}"),

                      if (data['place'] != null)
                        Text(
                          "📍 ${AppTranslations.getText('place', lang)}: ${data['place']}",
                        ),

                      if (data['phone'] != null)
                        Text(
                          "📞 ${AppTranslations.getText('phone', lang)}: ${data['phone']}",
                        ),

                      if (data['address'] != null)
                        Text(
                          "🏠 ${AppTranslations.getText('address', lang)}: ${data['address']}",
                        ),

                      if (data['gender'] != null)
                        Text(
                          "👤 ${AppTranslations.getText('gender', lang)}: ${data['gender']}",
                        ),

                      if (data['age'] != null)
                        Text(
                          "🎂 ${AppTranslations.getText('age', lang)}: ${data['age']}",
                        ),
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