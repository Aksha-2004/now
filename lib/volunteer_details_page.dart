import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VolunteerDetailsPage extends StatefulWidget {
  const VolunteerDetailsPage({super.key});

  @override
  State<VolunteerDetailsPage> createState() => _VolunteerDetailsPageState();
}

class _VolunteerDetailsPageState extends State<VolunteerDetailsPage> {
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  String selectedSkill = 'General';
  bool willHelp = false;

  final List<String> skills = ['Medical', 'Rescue', 'Logistics', 'General'];
  bool isSubmitting = false;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _submitDetails() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('volunteers').doc(user.uid);

    setState(() => isSubmitting = true);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("You have already submitted your volunteer details."),
        backgroundColor: Colors.orange,
      ));
    } else {
      await docRef.set({
        'uid': user.uid,
        'email': user.email,
        'username': usernameController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'skill': selectedSkill,
        'willing': willHelp,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Volunteer details submitted."),
        backgroundColor: Colors.green,
      ));

      Navigator.pushReplacementNamed(context, '/home');
    }

    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Volunteer Details"), backgroundColor: Colors.red),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: "Username"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: "Mobile Number"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: addressController,
              decoration: InputDecoration(labelText: "Address"),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField(
              value: selectedSkill,
              decoration: InputDecoration(labelText: "Skill Type"),
              items: skills.map((skill) => DropdownMenuItem(
                value: skill,
                child: Text(skill),
              )).toList(),
              onChanged: (val) => setState(() => selectedSkill = val.toString()),
            ),
            SizedBox(height: 10),
            SwitchListTile(
              title: Text("Willing to help during disasters?"),
              value: willHelp,
              activeColor: Colors.red,
              onChanged: (val) => setState(() => willHelp = val),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isSubmitting ? null : _submitDetails,
              icon: Icon(Icons.check),
              label: Text("Submit"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

