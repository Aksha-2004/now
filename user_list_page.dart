import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'translations.dart';

class UserListPage extends StatelessWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        String role = data['role'] ?? 'user';

        // ❌ NOT ADMIN
        if (role != 'admin') {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Access Denied"),
              backgroundColor: Colors.red,
            ),
            body: const Center(
              child: Text(
                "🚫 You are not allowed to see this page",
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
        }

        // ✅ ADMIN VIEW (FULL DETAILS)
        return Scaffold(
          appBar: AppBar(
            title: Text(AppTranslations.getText('all_users', lang)),
            backgroundColor: Colors.red,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs;

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final data =
                      users[index].data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // 👤 Username
                          Text(
                            "👤 ${data['username'] ?? 'No name'}",
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 6),

                          // 📧 Email
                          if (data['email'] != null)
                            Text("📧 ${data['email']}"),

                          // 📍 Place
                          if (data['place'] != null)
                            Text(
                              "📍 ${AppTranslations.getText('place', lang)}: ${data['place']}",
                            ),

                          // 📞 Phone
                          if (data['phone'] != null)
                            Text(
                              "📞 ${AppTranslations.getText('phone', lang)}: ${data['phone']}",
                            ),

                          // 🏠 Address
                          if (data['address'] != null)
                            Text(
                              "🏠 ${AppTranslations.getText('address', lang)}: ${data['address']}",
                            ),

                          // 👤 Gender
                          if (data['gender'] != null)
                            Text(
                              "👤 ${AppTranslations.getText('gender', lang)}: ${data['gender']}",
                            ),

                          // 🎂 Age
                          if (data['age'] != null)
                            Text(
                              "🎂 ${AppTranslations.getText('age', lang)}: ${data['age']}",
                            ),

                          // 🆔 Role
                          if (data['role'] != null)
                            Text("🔐 Role: ${data['role']}"),

                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}