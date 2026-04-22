import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'translations.dart';

class VolunteerDetailsPage extends StatefulWidget {
  const VolunteerDetailsPage({super.key});

  @override
  State<VolunteerDetailsPage> createState() => _VolunteerDetailsPageState();
}

class _VolunteerDetailsPageState extends State<VolunteerDetailsPage> {
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final otpController = TextEditingController();

  String selectedSkill = 'General';
  bool willHelp = false;

  final List<String> skills = ['Medical', 'Rescue', 'Logistics', 'General'];

  bool isSubmitting = false;
  bool otpSent = false;

  ConfirmationResult? confirmationResult;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ================= SEND OTP =================
  Future<void> _sendOTP() async {
    String phone = phoneController.text.trim();

    if (phone.isEmpty || phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid 10-digit mobile number")),
      );
      return;
    }

    try {
      confirmationResult =
          await FirebaseAuth.instance.signInWithPhoneNumber("+91$phone");

      setState(() {
        otpSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP Sent Successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP Error: $e")),
      );
    }
  }

  // ================= VERIFY OTP =================
  Future<bool> _verifyOTP() async {
    try {
      await confirmationResult!.confirm(otpController.text.trim());
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP")),
      );
      return false;
    }
  }

  // ================= SUBMIT =================
  Future<void> _submitDetails() async {
    String lang = Localizations.localeOf(context).languageCode;

    final user = _auth.currentUser;
    if (user == null) return;

    if (!otpSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please verify phone number first")),
      );
      return;
    }

    bool verified = await _verifyOTP();
    if (!verified) return;

    final docRef = _firestore.collection('volunteers').doc(user.uid);

    setState(() => isSubmitting = true);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppTranslations.getText('already_submitted', lang)),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      await docRef.set({
        'uid': user.uid,
        'email': user.email,
        'username': usernameController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'skill': selectedSkill,
        'willing': willHelp,
        'verified': true, // ✅ IMPORTANT SECURITY
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppTranslations.getText('volunteer_submitted', lang)),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacementNamed(context, '/home');
    }

    setState(() => isSubmitting = false);
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
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText:
                    AppTranslations.getText('username', lang),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText:
                    AppTranslations.getText('mobile_number', lang),
              ),
            ),

            const SizedBox(height: 10),

            // 🔴 SEND OTP
            ElevatedButton(
              onPressed: _sendOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text("Send OTP"),
            ),

            if (otpSent) ...[
              const SizedBox(height: 10),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Enter OTP"),
              ),
            ],

            const SizedBox(height: 10),

            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText:
                    AppTranslations.getText('address', lang),
              ),
            ),

            const SizedBox(height: 10),

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

            SwitchListTile(
              title: Text(
                AppTranslations.getText('willing_help', lang),
              ),
              value: willHelp,
              activeColor: Colors.red,
              onChanged: (val) => setState(() => willHelp = val),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: isSubmitting ? null : _submitDetails,
              icon: const Icon(Icons.check),
              label: Text(
                  AppTranslations.getText('submit', lang)),
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