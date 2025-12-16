import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

class OfflineAlertPage extends StatefulWidget {
  const OfflineAlertPage({super.key});

  @override
  State<OfflineAlertPage> createState() => _OfflineAlertPageState();
}

class _OfflineAlertPageState extends State<OfflineAlertPage> {
  final TextEditingController _messageController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<String> phoneNumbers = [];
  bool isLoading = true;

  // 🔹 Load phone numbers from Firestore
  Future<void> _loadPhoneNumbers() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final seen = <String>{};
      final numbers = snapshot.docs
          .map((doc) => doc.data()['phone']?.toString().trim())
          .where((phone) =>
              phone != null && phone.isNotEmpty && seen.add(phone!))
          .cast<String>()
          .toList();

      setState(() {
        phoneNumbers = numbers;
        isLoading = false;
      });
    } catch (e) {
      isLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error loading numbers: $e")),
      );
    }
  }

  // 🔔 PLAY ALARM + OPEN SMS
  Future<void> _openSMSApp() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Message cannot be empty")),
      );
      return;
    }

    if (phoneNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ No phone numbers found")),
      );
      return;
    }

    // 🔔 Play looping emergency sound
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(
      AssetSource('sounds/emergency_alarm.mp3'),
      volume: 1.0,
    );

    // ⏳ Let alarm play for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    // 📩 Open SMS app with ALL numbers
    final numbers = phoneNumbers.join(',');
    final uri = Uri.parse(
      "sms:$numbers?body=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }

    // 🔇 Stop sound after redirect
    await _audioPlayer.stop();
  }

  @override
  void initState() {
    super.initState();
    _loadPhoneNumbers();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Offline Alert (SMS)"),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Alert Message",
                      border: OutlineInputBorder(),
                      hintText: "Type disaster alert here...",
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _openSMSApp,
                    icon: const Icon(Icons.sms),
                    label: const Text("Send SMS to All"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,e
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "📋 Total Recipients: ${phoneNumbers.lngth}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView.builder(
                      itemCount: phoneNumbers.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.phone),
                          title: Text(phoneNumbers[index]),
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

