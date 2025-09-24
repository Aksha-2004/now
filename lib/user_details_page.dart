import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final phone = phoneController.text.trim();
    final place = placeController.text.trim();
    final address = addressController.text.trim();
    final age = ageController.text.trim();

    if (place.isEmpty || address.isEmpty || phone.isEmpty || age.isEmpty) {
      _showDialog("Please fill all fields.");
      return;
    }

    if (!phone.startsWith("+91") || phone.length != 13) {
      _showDialog("Phone number must start with +91 and be 13 digits in total (e.g., +919876543210).");
      return;
    }

    final user = auth.currentUser;
    if (user == null) {
      _showDialog("User not logged in.");
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
      _showDialog("Error saving user data.");
    }
  }

  void _showDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Details"),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text("Complete Your Profile",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                TextField(
                  controller: placeController,
                  decoration: InputDecoration(labelText: "Place"),
                ),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(labelText: "Address"),
                ),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone Number (Format: +91XXXXXXXXXX)",
                  ),
                ),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "Age"),
                ),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: InputDecoration(labelText: "Gender"),
                  items: ['Male', 'Female', 'Other']
                      .map((gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => selectedGender = val!),
                ),
                SizedBox(height: 12),
                SwitchListTile(
                  title: Text("Willing to help as a volunteer?"),
                  value: isVolunteer,
                  activeColor: Colors.red,
                  onChanged: (val) => setState(() => isVolunteer = val),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: Icon(Icons.arrow_forward),
                  label: Text("Continue"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    minimumSize: Size(double.infinity, 48),
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


