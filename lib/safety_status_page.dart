import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'translations.dart';

class SafetyStatusPage extends StatefulWidget {
  const SafetyStatusPage({super.key});

  @override
  State<SafetyStatusPage> createState() => _SafetyStatusPageState();
}

class _SafetyStatusPageState extends State<SafetyStatusPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _status;
  bool _showHelpButton = false;
  String? _docId;

  void _markStatus(String statusText) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final username = userDoc['username'];
    final place = userDoc['place'];

    final existing = await _firestore
        .collection('safety_status')
        .where('uid', isEqualTo: user.uid)
        .get();

    if (existing.docs.isNotEmpty) {
      _docId = existing.docs.first.id;
      await _firestore.collection('safety_status').doc(_docId).update({
        'status': statusText,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      final doc = await _firestore.collection('safety_status').add({
        'uid': user.uid,
        'username': username,
        'place': place,
        'status': statusText,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _docId = doc.id;
    }

    setState(() {
      _status = statusText;
      _showHelpButton = statusText == "I'm Not Safe";
    });

    String lang = Localizations.localeOf(context).languageCode;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        "${AppTranslations.getText('status_updated', lang)}: $statusText",
      ),
      backgroundColor:
          statusText == "I'm Safe" ? Colors.green : Colors.orange,
    ));
  }

  void _deleteStatus() async {
    if (_docId == null) return;
    await _firestore.collection('safety_status').doc(_docId).delete();

    setState(() {
      _status = null;
      _showHelpButton = false;
      _docId = null;
    });

    String lang = Localizations.localeOf(context).languageCode;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppTranslations.getText('status_deleted', lang)),
      backgroundColor: Colors.grey,
    ));
  }

  void _redirectToVolunteers() {
    Navigator.pushNamed(context, '/volunteers');
  }

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.getText('safety_title', lang)),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              AppTranslations.getText('are_you_safe', lang),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () => _markStatus("I'm Safe"),
              icon: const Icon(Icons.check_circle),
              label: Text(AppTranslations.getText('im_safe', lang)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () => _markStatus("I'm Not Safe"),
              icon: const Icon(Icons.warning_amber),
              label: Text(AppTranslations.getText('im_not_safe', lang)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            if (_showHelpButton)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton.icon(
                  onPressed: _redirectToVolunteers,
                  icon: const Icon(Icons.volunteer_activism),
                  label: Text(
                      AppTranslations.getText('find_volunteers', lang)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),

            if (_status != null) ...[
              const SizedBox(height: 30),
              Text(
                "${AppTranslations.getText('your_status', lang)}: $_status",
                style: const TextStyle(fontSize: 16),
              ),
              TextButton.icon(
                onPressed: _deleteStatus,
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: Text(
                  AppTranslations.getText('delete_status', lang),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],

            const SizedBox(height: 30),
            const Divider(),

            Text(
              "🔍 ${AppTranslations.getText('community_updates', lang)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('safety_status')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        AppTranslations.getText('no_updates', lang),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data =
                          docs[index].data() as Map<String, dynamic>;

                      final name = data['username'];
                      final place = data['place'];
                      final statusText = data['status'];

                      return ListTile(
                        leading: Icon(
                          statusText == "I'm Safe"
                              ? Icons.check_circle
                              : Icons.warning,
                          color: statusText == "I'm Safe"
                              ? Colors.green
                              : Colors.orange,
                        ),
                        title: Text(
                            "$name ${AppTranslations.getText('from', lang)} $place"),
                        subtitle: Text(
                          "${AppTranslations.getText('status_label', lang)}: $statusText",
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
