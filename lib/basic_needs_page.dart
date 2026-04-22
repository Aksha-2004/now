import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'translations.dart';
import 'main.dart';

class BasicNeedsPage extends StatefulWidget {
  const BasicNeedsPage({super.key});

  @override
  State<BasicNeedsPage> createState() => _BasicNeedsPageState();
}

class _BasicNeedsPageState extends State<BasicNeedsPage> {
  final _locationController = TextEditingController();
  final _providerController = TextEditingController();
  final _extraNeedRequestController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  bool _loadingLocation = false;

  void _showMsg(String key, Color color, String lang) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppTranslations.getText(key, lang)),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _getCurrentLocation(String lang) async {
    setState(() => _loadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMsg('location_disabled', Colors.orange, lang);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showMsg('permission_denied', Colors.red, lang);
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      final place = placemarks.first;
      _locationController.text =
          "${place.name}, ${place.locality}, ${place.administrativeArea}";
    } catch (e) {
      _showMsg('location_fail', Colors.red, lang);
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  Future<void> _submitAvailableNeed(String lang) async {
    final location = _locationController.text.trim();
    final provider = _providerController.text.trim();
    final uid = _auth.currentUser?.uid;

    if (location.isEmpty || provider.isEmpty || uid == null) {
      _showMsg('fill_required', Colors.orange, lang);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('basic_needs').add({
        'location': location,
        'provider': provider,
        'uid': uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _locationController.clear();
      _providerController.clear();

      _showMsg('submit_success', Colors.green, lang);
    } catch (e) {
      _showMsg('submit_fail', Colors.red, lang);
    }
  }

  Future<void> _submitRequestedNeed(String lang) async {
    final request = _extraNeedRequestController.text.trim();

    if (request.isEmpty) {
      _showMsg('need_required', Colors.orange, lang);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('requested_needs').add({
        'need': request,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _extraNeedRequestController.clear();
      _showMsg('request_shared', Colors.green, lang);
    } catch (e) {
      _showMsg('request_fail', Colors.red, lang);
    }
  }

  Future<void> _deleteNeed(String docId, String lang) async {
    try {
      await FirebaseFirestore.instance
          .collection('basic_needs')
          .doc(docId)
          .delete();
      _showMsg('deleted', Colors.grey, lang);
    } catch (e) {
      _showMsg('delete_fail', Colors.red, lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    String lang = Localizations.localeOf(context).languageCode;
    final currentUid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.getText('needs', lang)),
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // 🔹 Available Needs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppTranslations.getText('available_needs', lang)),
                    const SizedBox(height: 10),

                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: AppTranslations.getText('location', lang),
                      ),
                    ),

                    ElevatedButton.icon(
                      onPressed: _loadingLocation
                          ? null
                          : () => _getCurrentLocation(lang),
                      icon: const Icon(Icons.my_location),
                      label: Text(
                        _loadingLocation
                            ? AppTranslations.getText('getting', lang)
                            : AppTranslations.getText('use_location', lang),
                      ),
                    ),

                    TextField(
                      controller: _providerController,
                      decoration: InputDecoration(
                        labelText: AppTranslations.getText('provider', lang),
                      ),
                    ),

                    ElevatedButton(
                      onPressed: () => _submitAvailableNeed(lang),
                      child: Text(AppTranslations.getText('submit', lang)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Request Needs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(AppTranslations.getText('request_needs', lang)),
                    TextField(
                      controller: _extraNeedRequestController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText:
                            AppTranslations.getText('what_need', lang),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _submitRequestedNeed(lang),
                      child: Text(AppTranslations.getText('request', lang)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Shared Locations
            Text(AppTranslations.getText('shared_locations', lang)),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('basic_needs')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isUser = currentUid == data['uid'];

                    return ListTile(
                      title: Text(data['location'] ?? ''),
                      subtitle: Text(
                          "${AppTranslations.getText('provider', lang)}: ${data['provider']}"),
                      trailing: isUser
                          ? IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteNeed(doc.id, lang),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}