import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'translations.dart';   // ✅ ADD
import 'main.dart';           // ✅ ADD

class VolunteersPage extends StatefulWidget {
  const VolunteersPage({super.key});

  @override
  State<VolunteersPage> createState() => _VolunteersPageState();
}

class _VolunteersPageState extends State<VolunteersPage> {
  String searchText = '';

  @override
  Widget build(BuildContext context) {

    String lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.getText('volunteers', lang)),
        backgroundColor: Colors.red,

        // 🌐 Language Switch
        actions: [
          TextButton(
            onPressed: () {
              EmergencyContactApp.setLocale(context, const Locale('en'));
            },
            child: const Text("EN", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              EmergencyContactApp.setLocale(context, const Locale('ta'));
            },
            child: const Text("TA", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),

      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: AppTranslations.getText('search_hint', lang),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('volunteers')
                  .orderBy('timestamp', descending: true)
                  .snapshots(includeMetadataChanges: true),
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(AppTranslations.getText('error_loading', lang)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(AppTranslations.getText('no_volunteers', lang)),
                  );
                }

                final docs = snapshot.data!.docs;

                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['username']?.toLowerCase() ?? '';
                  final address = data['address']?.toLowerCase() ?? '';
                  return name.contains(searchText) || address.contains(searchText);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(AppTranslations.getText('no_match', lang)),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 3,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.redAccent,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(data['username'] ?? 'No Name'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📞 ${data['phone'] ?? 'N/A'}"),
                            Text("📍 ${data['address'] ?? 'Unknown'}"),
                            Text("🛠️ ${AppTranslations.getText('skill', lang)}: ${data['skill'] ?? 'Not specified'}"),
                            Text("🤝 ${AppTranslations.getText('willing', lang)}: ${data['willing'] == true ? AppTranslations.getText('yes', lang) : AppTranslations.getText('no', lang)}"),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}