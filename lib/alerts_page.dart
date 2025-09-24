import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'offline_alerts_page.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final TextEditingController _alertController = TextEditingController();
  final TextEditingController _safePlaceController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isOfflineMode = false;

  String _selectedLevel = 'Low';
  final List<String> _disasterLevels = ['Low', 'Medium', 'High'];

  void _sendAlert() async {
    final alert = _alertController.text.trim();
    final safePlaces = _safePlaceController.text.trim();
    final user = _auth.currentUser;

    if (alert.isEmpty || user == null) return;

    await FirebaseFirestore.instance.collection('alerts').add({
      'message': alert,
      'level': _selectedLevel,
      'safe_places': safePlaces,
      'uid': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _alertController.clear();
    _safePlaceController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Alert broadcasted to all users"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteAlert(String alertId) async {
    try {
      await FirebaseFirestore.instance.collection('alerts').doc(alertId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🗑️ Alert deleted"), backgroundColor: Colors.grey),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to delete alert"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Disaster Alerts"),
        backgroundColor: Colors.red,
        actions: [
          Switch(
            value: _isOfflineMode,
            onChanged: (val) {
              setState(() => _isOfflineMode = val);
              if (val) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OfflineAlertPage()),
                );
              }
            },
            activeColor: Colors.white,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Center(child: Text("Offline")),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: !_isOfflineMode
            ? Column(
                children: [
                  // Alert Form
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          TextField(
                            controller: _alertController,
                            decoration: const InputDecoration(
                              labelText: "Disaster Message",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _selectedLevel,
                            decoration: const InputDecoration(
                              labelText: "Disaster Level",
                              border: OutlineInputBorder(),
                            ),
                            items: _disasterLevels.map((level) {
                              return DropdownMenuItem(value: level, child: Text(level));
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedLevel = val!),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _safePlaceController,
                            decoration: const InputDecoration(
                              labelText: "Safe Places (optional)",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _sendAlert,
                            icon: const Icon(Icons.send),
                            label: const Text("Send Alert"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Live Alert List
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('alerts')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final alerts = snapshot.data!.docs.where((doc) {
                          final ts = (doc['timestamp'] as Timestamp?)?.toDate();
                          return ts != null && now.difference(ts).inHours < 24;
                        }).toList();

                        if (alerts.isEmpty) {
                          return const Center(child: Text("No alerts in the past 24 hours."));
                        }

                        return ListView.builder(
                          itemCount: alerts.length,
                          itemBuilder: (context, index) {
                            final doc = alerts[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final ts = (data['timestamp'] as Timestamp?)?.toDate();
                            final formattedTime = ts != null
                                ? DateFormat('dd MMM, hh:mm a').format(ts)
                                : "Time unknown";

                            final isMine = currentUser?.uid == data['uid'];

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: const Icon(Icons.warning, color: Colors.red),
                                title: Text(data['message'] ?? 'No message'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Level: ${data['level']}"),
                                    if ((data['safe_places'] ?? '').isNotEmpty)
                                      Text("Safe Places: ${data['safe_places']}"),
                                    Text("Sent at: $formattedTime"),
                                  ],
                                ),
                                trailing: isMine
                                    ? IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteAlert(doc.id),
                                      )
                                    : null,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              )
            : const SizedBox(),
      ),
    );
  }
}
