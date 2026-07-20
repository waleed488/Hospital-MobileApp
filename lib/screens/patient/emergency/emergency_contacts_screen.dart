import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String customEmergencyContact = "Not Configured";

  @override
  void initState() {
    super.initState();
    _loadCustomEmergencyContact();
  }

  Future<void> _loadCustomEmergencyContact() async {
    if (uid.isNotEmpty) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          customEmergencyContact = doc.data()?['emergencyContact'] ?? "Not Configured";
        });
      }
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanedNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $cleanedNumber';
      }
    } catch (e) {
      // Fallback: Copy to clipboard and show SnackBar
      await Clipboard.setData(ClipboardData(text: phoneNumber));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Copied $phoneNumber to clipboard"),
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.redAccent, Colors.red],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.white, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Emergency Assistance",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Tap on any card to place an emergency call immediately.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Direct Dial Hotlines",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            _emergencyCard(
              title: "Hospital ER Department",
              number: "+1 (800) 555-0199",
              subtitle: "24/7 emergency response and guidance",
              icon: Icons.local_hospital,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            _emergencyCard(
              title: "Ambulance Hotline",
              number: "911",
              subtitle: "Immediate dispatch ambulance services",
              icon: Icons.airport_shuttle,
              color: Colors.amber.shade800,
            ),
            const SizedBox(height: 25),
            const Text(
              "Personal Emergency Contact",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            _emergencyCard(
              title: "Family / Friend Contact",
              number: customEmergencyContact,
              subtitle: "Configured in your Medical Profile",
              icon: Icons.family_restroom,
              color: Colors.teal,
              isCustom: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emergencyCard({
    required String title,
    required String number,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isCustom = false,
  }) {
    final bool canDial = number != "Not Configured" && number.isNotEmpty;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.04),
      child: InkWell(
        onTap: canDial ? () => _makeCall(number) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      number,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: canDial ? color : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (canDial)
                Icon(
                  Icons.phone_in_talk,
                  color: color,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
