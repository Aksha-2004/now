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

  // 🔹 Load phone numbers
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
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  // 🔔 Alarm + Open SMS
  Future<void> _openSMSApp() async {
    final message = _messageController.text.trim();

    if (message.isEmpty || phoneNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Message or numbers missing")),
      );
      return;
    }

    // 🔔 Play alarm
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(
      AssetSource('sounds/emergency_alarm.mp3'),
      volume: 1.0,
    );

    // ⏳ Let sound play shortly
    await Future.delayed(const Duration(milliseconds: 500));

    // 📩 Create proper SMS URI
    final String numbers = phoneNumbers.join(',');
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: numbers,
      queryParameters: {'body': message},
    );

    // 🔇 Stop sound
    await _audioPlayer.stop();

    // 📱 Open native SMS app
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Cannot open SMS app")),
      );
    }
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
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _openSMSApp,
                    icon: const Icon(Icons.sms),
                    label: const Text("Send SMS to All"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "📋 Total Recipients: ${phoneNumbers.length}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
    );
  }
}
