import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMsg("Location services are disabled.", Colors.orange);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showMsg("Location permission permanently denied.", Colors.red);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      final place = placemarks.first;
      _locationController.text = "${place.name}, ${place.locality}, ${place.administrativeArea}";
    } catch (e) {
      _showMsg("❌ Failed to get location", Colors.red);
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  void _showMsg(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _submitAvailableNeed() async {
    final location = _locationController.text.trim();
    final provider = _providerController.text.trim();
    final uid = _auth.currentUser?.uid;

    if (location.isEmpty || provider.isEmpty || uid == null) {
      _showMsg("⚠ Location, provider and user required.", Colors.orange);
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

      _showMsg("✅ Submitted successfully!", Colors.green);
    } catch (e) {
      _showMsg("❌ Failed to submit", Colors.red);
    }
  }

  Future<void> _submitRequestedNeed() async {
    final request = _extraNeedRequestController.text.trim();

    if (request.isEmpty) {
      _showMsg("Please specify your need.", Colors.orange);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('requested_needs').add({
        'need': request,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _extraNeedRequestController.clear();
      _showMsg("📢 Request shared with providers.", Colors.green);
    } catch (e) {
      _showMsg("❌ Failed to submit request", Colors.red);
    }
  }

  Future<void> _deleteNeed(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('basic_needs').doc(docId).delete();
      _showMsg("🗑️ Entry deleted", Colors.grey);
    } catch (e) {
      _showMsg("❌ Delete failed", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Basic Needs"),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Section 1: Share Need
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("🟢 Available Basic Needs", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(labelText: "Location"),
                    ),
                    SizedBox(height: 6),
                    ElevatedButton.icon(
                      onPressed: _loadingLocation ? null : _getCurrentLocation,
                      icon: Icon(Icons.my_location),
                      label: Text(_loadingLocation ? "Getting..." : "Use My Current Location"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _providerController,
                      decoration: InputDecoration(labelText: "Provided by"),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _submitAvailableNeed,
                      icon: Icon(Icons.check),
                      label: Text("Submit Location"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Section 2: Request Additional Needs
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("🆘 Request Additional Needs", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    TextField(
                      controller: _extraNeedRequestController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "What do you need? (e.g. Milk, medicine)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _submitRequestedNeed,
                      icon: Icon(Icons.send),
                      label: Text("Request Need"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Shared Locations List with delete button
            Text("📍 Shared Locations", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('basic_needs')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isUser = currentUid == data['uid'];

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      color: Colors.lightBlue[50],
                      child: ListTile(
                        leading: Icon(Icons.location_on, color: Colors.red),
                        title: Text(data['location'] ?? ''),
                        subtitle: Text("Provided by: ${data['provider'] ?? ''}"),
                        trailing: isUser
                            ? IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteNeed(doc.id),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),

            SizedBox(height: 20),

            // Requested Needs
            Text("📢 Requested Needs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requested_needs')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      color: Colors.orange[50],
                      child: ListTile(
                        leading: Icon(Icons.warning, color: Colors.orange),
                        title: Text(data['need'] ?? 'No need specified'),
                      ),
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
