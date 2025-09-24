import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final List<Map<String, dynamic>> features = [
    {'title': 'User List', 'icon': Icons.people, 'color': Colors.deepPurple, 'route': '/user_list'},
    {'title': 'Disaster Alerts', 'icon': Icons.warning, 'color': Colors.red, 'route': '/alerts'},
    {'title': 'Basic Needs', 'icon': Icons.fastfood, 'color': Colors.orange, 'route': '/needs'},
    {'title': 'Safety status', 'icon': Icons.shield, 'color': Colors.teal, 'route': '/safety'},
    {'title': 'Volunteers', 'icon': Icons.people_alt, 'color': Colors.indigo, 'route': '/volunteers'},
    {'title': 'Emergency Contacts', 'icon': Icons.phone, 'color': Colors.blue, 'route': '/contacts'},
    {'title': 'First Aid Tips', 'icon': Icons.healing, 'color': Colors.green, 'route': '/first_aid'},
  ];

   HomePage({Key? key}) : super(key: key); // ✅ Flutter 3+ uses Key? key

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Emergency App"),
        backgroundColor: Colors.red,
        centerTitle: true,
        elevation: 4,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: features.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Welcome Header
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "👋 Welcome!",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  "Access services and stay safe.",
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 20),
              ],
            );
          }

          final item = features[index - 1];
          return FeatureCard(
            title: item['title'],
            icon: item['icon'],
            color: item['color'],
            onTap: () => Navigator.pushNamed(context, item['route']),
          );
        },
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const FeatureCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key); // ✅ Updated to use Key? key for safety

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          splashColor: color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  radius: 26,
                  child: Icon(icon, size: 28, color: color),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
