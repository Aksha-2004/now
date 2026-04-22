import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'offline_alerts_page.dart';
import 'translations.dart'; // ✅ ADD THIS

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

  void _sendAlert(String lang) async {
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
      SnackBar(
        content: Text(AppTranslations.getText('alert_sent', lang)),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteAlert(String alertId, String lang) async {
    try {
      await FirebaseFirestore.instance.collection('alerts').doc(alertId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.getText('alert_deleted', lang)),
          backgroundColor: Colors.grey,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.getText('delete_failed', lang)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final now = DateTime.now();

    // 🌐 GET LANGUAGE
    String lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.getText('alerts', lang)),
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
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: Text(AppTranslations.getText('offline', lang)),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: !_isOfflineMode
            ? Column(
                children: [
                  // 🔴 ALERT FORM
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          TextField(
                            controller: _alertController,
                            decoration: InputDecoration(
                              labelText: AppTranslations.getText('alert_msg', lang),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),

                          DropdownButtonFormField<String>(
                            value: _selectedLevel,
                            decoration: InputDecoration(
                              labelText: AppTranslations.getText('alert_level', lang),
                              border: const OutlineInputBorder(),
                            ),
                            items: _disasterLevels.map((level) {
                              return DropdownMenuItem(
                                value: level,
                                child: Text(level),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedLevel = val!),
                          ),

                          const SizedBox(height: 10),

                          TextField(
                            controller: _safePlaceController,
                            decoration: InputDecoration(
                              labelText:
                                  AppTranslations.getText('safe_places', lang),
                              border: const OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 10),

                          ElevatedButton.icon(
                            onPressed: () => _sendAlert(lang),
                            icon: const Icon(Icons.send),
                            label: Text(
                                AppTranslations.getText('send_alert', lang)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 📢 ALERT LIST
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('alerts')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final alerts = snapshot.data!.docs.where((doc) {
                          final ts =
                              (doc['timestamp'] as Timestamp?)?.toDate();
                          return ts != null &&
                              now.difference(ts).inHours < 24;
                        }).toList();

                        if (alerts.isEmpty) {
                          return Center(
                            child: Text(AppTranslations.getText(
                                'no_alerts', lang)),
                          );
                        }

                        return ListView.builder(
                          itemCount: alerts.length,
                          itemBuilder: (context, index) {
                            final doc = alerts[index];
                            final data =
                                doc.data() as Map<String, dynamic>;

                            final ts =
                                (data['timestamp'] as Timestamp?)?.toDate();

                            final formattedTime = ts != null
                                ? DateFormat('dd MMM, hh:mm a').format(ts)
                                : AppTranslations.getText(
                                    'time_unknown', lang);

                            final isMine =
                                currentUser?.uid == data['uid'];

                            return Card(
                              margin:
                                  const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: const Icon(Icons.warning,
                                    color: Colors.red),
                                title: Text(
                                    data['message'] ??
                                        AppTranslations.getText(
                                            'no_message', lang)),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "${AppTranslations.getText('level', lang)}: ${data['level']}"),
                                    if ((data['safe_places'] ?? '')
                                        .isNotEmpty)
                                      Text(
                                          "${AppTranslations.getText('safe_places', lang)}: ${data['safe_places']}"),
                                    Text(
                                        "${AppTranslations.getText('sent_at', lang)}: $formattedTime"),
                                  ],
                                ),
                                trailing: isMine
                                    ? IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _deleteAlert(doc.id, lang),
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