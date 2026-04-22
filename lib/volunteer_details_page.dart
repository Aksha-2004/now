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
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final otpController = TextEditingController();

  String selectedSkill = 'General';
  bool willHelp = false;

  final List<String> skills = ['Medical', 'Rescue', 'Logistics', 'General'];

  bool isSubmitting = false;
  bool otpSent = false;
  bool isLoadingOtp = false;

  String verificationId = "";

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ================= SEND OTP =================
  Future<void> _sendOTP() async {
    String phone = phoneController.text.trim();

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid 10-digit number")),
      );
      return;
    }

    setState(() {
      isLoadingOtp = true;
      otpSent = true; // ✅ SHOW OTP FIELD IMMEDIATELY
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: "+91$phone",

      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Auto Verified")),
        );
      },

      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          isLoadingOtp = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP Failed: ${e.message}")),
        );
      },

      codeSent: (String verId, int? resendToken) {
        setState(() {
          verificationId = verId;
          isLoadingOtp = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP Sent")),
        );
      },

      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },
    );
  }

  // ================= VERIFY OTP =================
  Future<bool> _verifyOTP() async {
    if (otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter OTP")),
      );
      return false;
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
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

    bool verified = await _verifyOTP();
    if (!verified) return;

    final docRef = _firestore.collection('volunteers').doc(user.uid);

    setState(() => isSubmitting = true);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppTranslations.getText('already_submitted', lang)),
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
        'verified': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppTranslations.getText('volunteer_submitted', lang)),
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

            ElevatedButton(
              onPressed: isLoadingOtp ? null : _sendOTP,
              child: isLoadingOtp
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Send OTP"),
            ),

            const SizedBox(height: 10),

            // ✅ ALWAYS SHOW OTP FIELD AFTER CLICK
            if (otpSent)
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Enter OTP"),
              ),

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
              onChanged: (val) => setState(() => willHelp = val),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isSubmitting ? null : _submitDetails,
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}