import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'translations.dart';   // ✅ ADD
import 'main.dart';           // ✅ ADD

class SignUpPage extends StatefulWidget {
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  void _signup() async {
    String lang = Localizations.localeOf(context).languageCode;

    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showDialog(AppTranslations.getText('fill_fields', lang));
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user!.updateDisplayName(username);

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'username': username,
        'email': email,
        'profile_complete': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacementNamed(context, '/user_details', arguments: {
        'uid': userCredential.user!.uid,
        'username': username,
        'email': email,
      });
    } catch (e) {
      _showDialog(
          "${AppTranslations.getText('signup_failed', lang)} ${e.toString().split('] ').last}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showDialog(String message) {
    String lang = Localizations.localeOf(context).languageCode;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.getText('ok', lang)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // ✅ LANGUAGE SWITCH
      appBar: AppBar(
        backgroundColor: Colors.red,
        actions: [
          TextButton(
            onPressed: () {
              EmergencyContactApp.setLocale(context, const Locale('en'));
            },
            child: const Text("EN", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              EmergencyContactApp.setLocale(context, const Locale('ta'));
            },
            child: const Text("TA", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),

      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(24),
            elevation: 10,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.person_add_alt,
                      size: 60, color: Colors.red),
                  const SizedBox(height: 10),

                  // ✅ TITLE
                  Text(
                    AppTranslations.getText('signup_title', lang),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  // USERNAME
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText:
                          AppTranslations.getText('username', lang),
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // EMAIL
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText:
                          AppTranslations.getText('email', lang),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 12),

                  // PASSWORD
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText:
                          AppTranslations.getText('password', lang),
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isLoading ? null : _signup,
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : Text(
                            AppTranslations.getText('signup', lang)),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/'),
                    child: Text(AppTranslations.getText(
                        'already_account', lang)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}