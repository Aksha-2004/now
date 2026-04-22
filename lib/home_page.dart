import 'package:flutter/material.dart';
import 'translations.dart';
import 'main.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final List<Map<String, dynamic>> features = [
    {'key': 'user_list', 'icon': Icons.people, 'color': Colors.deepPurple, 'route': '/user_list'},
    {'key': 'alerts', 'icon': Icons.warning, 'color': Colors.red, 'route': '/alerts'},
    {'key': 'needs', 'icon': Icons.fastfood, 'color': Colors.orange, 'route': '/needs'},
    {'key': 'safety', 'icon': Icons.shield, 'color': Colors.teal, 'route': '/safety'},
    {'key': 'volunteers', 'icon': Icons.people_alt, 'color': Colors.indigo, 'route': '/volunteers'},
    {'key': 'contacts', 'icon': Icons.phone, 'color': Colors.blue, 'route': '/contacts'},
    {'key': 'first_aid', 'icon': Icons.healing, 'color': Colors.green, 'route': '/first_aid'},
  ];

  @override
  Widget build(BuildContext context) {

    String lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.red,
        centerTitle: true,
        elevation: 4,

        // ✅ translated title
        title: Text(AppTranslations.getText('app_title', lang)),

        // ✅ FIXED HERE (IMPORTANT CHANGE)
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

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: features.length + 1,
        itemBuilder: (context, index) {

          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.getText('welcome', lang),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  AppTranslations.getText('subtitle', lang),
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 20),
              ],
            );
          }

          final item = features[index - 1];

          return FeatureCard(
            title: AppTranslations.getText(item['key'], lang),
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}