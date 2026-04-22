import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'translations.dart';   // ✅ ADD
import 'main.dart';           // ✅ ADD

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  final _auth = FirebaseAuth.instance;
  final _functions = FirebaseFunctions.instance;

  void _login() async {
    String lang = Localizations.localeOf(context).languageCode;

    String email = emailController.text.trim();
    String password = passwordController.text;

    if (usernameController.text.isEmpty || email.isEmpty || password.isEmpty) {
      _showDialog(AppTranslations.getText('fill_fields', lang));
      return;
    }

    setState(() => isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _showDialog(AppTranslations.getText('invalid_login', lang));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _forgotPassword() async {
    String lang = Localizations.localeOf(context).languageCode;

    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showDialog(AppTranslations.getText('enter_email', lang));
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppTranslations.getText('reset_title', lang)),
        content: Text("${AppTranslations.getText('reset_msg', lang)} $email"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.getText('cancel', lang)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _auth.sendPasswordResetEmail(email: email);

                final sendCustomEmail =
                    _functions.httpsCallable('sendEmail');
                final sendCustomSMS =
                    _functions.httpsCallable('sendSMS');

                await sendCustomEmail.call({
                  'to': email,
                  'subject': 'Password Reset',
                  'message': 'Check your email to reset password'
                });

                await sendCustomSMS.call({
                  'to': '+91XXXXXXXXXX',
                  'message': 'Password reset requested. Check email.'
                });

                _showDialog("✅ ${AppTranslations.getText('reset_sent', lang)}");
              } catch (e) {
                _showDialog("❌ Error: $e");
              }
            },
            child: Text(AppTranslations.getText('send', lang)),
          )
        ],
      ),
    );
  }

  void _showDialog(String msg) {
    String lang = Localizations.localeOf(context).languageCode;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(msg),
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
      backgroundColor: Colors.grey[100],

      // ✅ LANGUAGE BUTTON
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
            elevation: 12,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 60, color: Colors.red),
                  const SizedBox(height: 10),

                  // ✅ TITLE
                  Text(
                    AppTranslations.getText('login_title', lang),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  // ✅ USERNAME
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText:
                          AppTranslations.getText('username', lang),
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ✅ EMAIL
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText:
                          AppTranslations.getText('email', lang),
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ✅ PASSWORD
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText:
                          AppTranslations.getText('password', lang),
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: Text(AppTranslations.getText(
                          'forgot_password', lang)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : Text(
                            AppTranslations.getText('login', lang)),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/signup'),
                    child: Text(AppTranslations.getText(
                        'new_user', lang)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}