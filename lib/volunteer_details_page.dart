import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'translations.dart';

class VolunteerDetailsPage extends StatefulWidget {
  const VolunteerDetailsPage({super.key});

  @override
  State<VolunteerDetailsPage> createState() =>
      _VolunteerDetailsPageState();
}

class _VolunteerDetailsPageState extends State<VolunteerDetailsPage> {
  final usernameController = TextEditingController();
  final addressController = TextEditingController();

  String selectedSkill = 'General';
  bool willHelp = false;

  final List<String> skills = ['Medical', 'Rescue', 'Logistics', 'General'];

  bool isSubmitting = false;
  bool isSendingMail = false;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ================= SEND EMAIL VERIFICATION =================
  Future<void> _sendEmailVerification() async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMsg("User not logged in");
      return;
    }

    try {
      setState(() => isSendingMail = true);

      await user.sendEmailVerification();

      _showMsg("Verification email sent. Check your inbox.");

      setState(() => isSendingMail = false);
    } catch (e) {
      setState(() => isSendingMail = false);
      _showMsg("Error: $e");
    }
  }

  // ================= CHECK VERIFIED =================
  Future<bool> _checkEmailVerified() async {
    await _auth.currentUser!.reload();
    final user = _auth.currentUser;

    if (user!.emailVerified) {
      return true;
    } else {
      _showMsg("Please verify your email first");
      return false;
    }
  }

  // ================= SUBMIT =================
  Future<void> _submitDetails() async {
    String lang = Localizations.localeOf(context).languageCode;

    final user = _auth.currentUser;
    if (user == null) return;

    // 🔴 Check email verified
    bool verified = await _checkEmailVerified();
    if (!verified) return;

    final docRef = _firestore.collection('volunteers').doc(user.uid);

    setState(() => isSubmitting = true);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppTranslations.getText('already_submitted', lang)),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      await docRef.set({
        'uid': user.uid,
        'email': user.email,
        'username': usernameController.text.trim(),
        'address': addressController.text.trim(),
        'skill': selectedSkill,
        'willing': willHelp,
        'verified': true, // ✅ VERIFIED USER
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppTranslations.getText('volunteer_submitted', lang)),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacementNamed(context, '/home');
    }

    setState(() => isSubmitting = false);
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(AppTranslations.getText('volunteer_details', lang)),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Username
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText:
                    AppTranslations.getText('username', lang),
              ),
            ),

            const SizedBox(height: 10),

            // Email Display
            Text(
              "Email: ${_auth.currentUser?.email ?? ""}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            // 🔴 SEND VERIFICATION EMAIL
            ElevatedButton(
              onPressed: isSendingMail ? null : _sendEmailVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: isSendingMail
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Verify Email"),
            ),

            const SizedBox(height: 10),

            // Address
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText:
                    AppTranslations.getText('address', lang),
              ),
            ),

            const SizedBox(height: 10),

            // Skill
            DropdownButtonFormField(
              value: selectedSkill,
              decoration: InputDecoration(
                labelText:
                    AppTranslations.getText('skill_type', lang),
              ),
              items: skills.map((skill) {
                return DropdownMenuItem(
                  value: skill,
                  child: Text(skill),
                );
              }).toList(),
              onChanged: (val) =>
                  setState(() => selectedSkill = val.toString()),
            ),

            const SizedBox(height: 10),

            // Willing
            SwitchListTile(
              title: Text(
                AppTranslations.getText('willing_help', lang),
              ),
              value: willHelp,
              onChanged: (val) => setState(() => willHelp = val),
            ),

            const SizedBox(height: 20),

            // Submit
            ElevatedButton.icon(
              onPressed: isSubmitting ? null : _submitDetails,
              icon: const Icon(Icons.check),
              label: const Text("Submit"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}