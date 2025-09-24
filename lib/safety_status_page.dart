import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("✅ Status updated: $statusText"),
      backgroundColor: statusText == "I'm Safe" ? Colors.green : Colors.orange,
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

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("🗑️ Your status was deleted."),
      backgroundColor: Colors.grey,
    ));
  }

  void _redirectToVolunteers() {
    Navigator.pushNamed(context, '/volunteers');
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Safety Status"),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Are you safe?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _markStatus("I'm Safe"),
              icon: Icon(Icons.check_circle),
              label: Text("I'm Safe"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _markStatus("I'm Not Safe"),
              icon: Icon(Icons.warning_amber),
              label: Text("I'm Not Safe"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            if (_showHelpButton)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton.icon(
                  onPressed: _redirectToVolunteers,
                  icon: Icon(Icons.volunteer_activism),
                  label: Text("Find Nearby Volunteers"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ),
            if (_status != null) ...[
              SizedBox(height: 30),
              Text("Your current status: $_status",
                  style: TextStyle(fontSize: 16)),
              TextButton.icon(
                onPressed: _deleteStatus,
                icon: Icon(Icons.delete_forever, color: Colors.red),
                label: Text("Delete Status",
                    style: TextStyle(color: Colors.red)),
              ),
            ],
            SizedBox(height: 30),
            Divider(),
            Text("🔍 Community Safety Updates",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('safety_status')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Center(child: Text("No safety updates yet."));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final name = data['username'];
                      final place = data['place'];
                      final statusText = data['status'];

                      return ListTile(
                        leading: Icon(
                          statusText == "I'm Safe"
                              ? Icons.check_circle
                              : Icons.warning,
                          color:
                              statusText == "I'm Safe" ? Colors.green : Colors.orange,
                        ),
                        title: Text("$name from $place"),
                        subtitle: Text("Status: $statusText"),
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
