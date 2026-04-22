import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'translations.dart'; // ✅ IMPORTANT

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final placeController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final ageController = TextEditingController();

  String selectedGender = 'Male';
  bool isVolunteer = false;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  void _submit() async {
    String lang = Localizations.localeOf(context).languageCode;

    final phone = phoneController.text.trim();
    final place = placeController.text.trim();
    final address = addressController.text.trim();
    final age = ageController.text.trim();

    if (place.isEmpty || address.isEmpty || phone.isEmpty || age.isEmpty) {
      _showDialog(AppTranslations.getText('fill_fields', lang));
      return;
    }

    if (!phone.startsWith("+91") || phone.length != 13) {
      _showDialog(AppTranslations.getText('invalid_phone', lang));
      return;
    }

    final user = auth.currentUser;
    if (user == null) {
      _showDialog(AppTranslations.getText('user_not_logged', lang));
      return;
    }

    final userData = {
      'uid': user.uid,
      'username': user.displayName ?? '',
      'email': user.email ?? '',
      'place': place,
      'address': address,
      'phone': phone,
      'age': age,
      'gender': selectedGender,
      'isVolunteer': isVolunteer,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await firestore.collection('users').doc(user.uid).set(userData);

      if (isVolunteer) {
        Navigator.pushReplacementNamed(context, '/volunteer');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _showDialog(AppTranslations.getText('error_saving', lang));
    }
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
      appBar: AppBar(
        title: Text(AppTranslations.getText('user_details', lang)),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  AppTranslations.getText('complete_profile', lang),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // 🔹 Place
                TextField(
                  controller: placeController,
                  decoration: InputDecoration(
                    labelText: AppTranslations.getText('place', lang),
                  ),
                ),

                // 🔹 Address
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: AppTranslations.getText('address', lang),
                  ),
                ),

                // 🔹 Phone
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText:
                        AppTranslations.getText('phone_format', lang),
                  ),
                ),

                // 🔹 Age
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppTranslations.getText('age', lang),
                  ),
                ),

                // 🔹 Gender
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: InputDecoration(
                    labelText: AppTranslations.getText('gender', lang),
                  ),
                  items: ['Male', 'Female', 'Other']
                      .map((gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          ))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => selectedGender = val!),
                ),

                const SizedBox(height: 12),

                // 🔹 Volunteer Switch
                SwitchListTile(
                  title: Text(
                    AppTranslations.getText('volunteer_question', lang),
                  ),
                  value: isVolunteer,
                  activeColor: Colors.red,
                  onChanged: (val) => setState(() => isVolunteer = val),
                ),

                const SizedBox(height: 20),

                // 🔹 Button
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                      AppTranslations.getText('continue', lang)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}