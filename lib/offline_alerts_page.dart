import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'translations.dart';

class OfflineAlertPage extends StatefulWidget {
  const OfflineAlertPage({super.key});

  @override
  State<OfflineAlertPage> createState() => _OfflineAlertPageState();
}

class _OfflineAlertPageState extends State<OfflineAlertPage> {
  final TextEditingController _messageController = TextEditingController();

  List<String> phoneNumbers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhoneNumbers(); // ✅ NO context usage here
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ✅ Load phone numbers safely
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

      // ✅ context used safely AFTER build
      String lang = Localizations.localeOf(context).languageCode;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${AppTranslations.getText('load_error', lang)}: $e",
          ),
        ),
      );
    }
  }

  // ✅ Open SMS App
  Future<void> _openSMSApp() async {
    String lang = Localizations.localeOf(context).languageCode;

    final message = _messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppTranslations.getText('msg_empty', lang)),
        ),
      );
      return;
    }

    if (phoneNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppTranslations.getText('no_numbers', lang)),
        ),
      );
      return;
    }

    final String recipients = phoneNumbers.join(';');

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: recipients,
      queryParameters: {
        'body': message,
      },
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(
          smsUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception("Cannot launch SMS");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppTranslations.getText('open_sms_fail', lang)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(AppTranslations.getText('offline_title', lang)),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🔹 Message Input
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText:
                          AppTranslations.getText('alert_message', lang),
                      hintText:
                          AppTranslations.getText('type_alert', lang),
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 🔹 Send Button
                  ElevatedButton.icon(
                    onPressed: _openSMSApp,
                    icon: const Icon(Icons.sms),
                    label: Text(
                        AppTranslations.getText('send_sms', lang)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔹 Count
                  Text(
                    "${AppTranslations.getText('total_numbers', lang)}: ${phoneNumbers.length}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  // 🔹 List of Numbers
                  Expanded(
                    child: phoneNumbers.isEmpty
                        ? Center(
                            child: Text(
                              AppTranslations.getText('no_numbers', lang),
                            ),
                          )
                        : ListView.builder(
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