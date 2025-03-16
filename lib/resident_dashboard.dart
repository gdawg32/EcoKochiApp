import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'main.dart';
import 'resident_schedule_page.dart';

const String baseUrl = "https://ecokochi.pythonanywhere.com/api/";

class ResidentDashboardPage extends StatelessWidget {
  final String token;
  final Map<String, dynamic> residentDetails;

  ResidentDashboardPage({
    required this.token,
    required this.residentDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EcoKochi Resident Dashboard',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[800],
        elevation: 10,
        shadowColor: Colors.green[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () {
              _logout(context);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[50]!,
              Colors.green[100]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${residentDetails['name']}! 🌱',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 22, 82, 26),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Ward: ${residentDetails['ward']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green[800],
                        ),
                      ),
                      Text(
                        'House Number: ${residentDetails['house_number']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 17, 68, 21),
                ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildActionButton(
                  icon: Icons.calendar_today,
                  label: 'Schedule',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResidentSchedulePage(token: token),
                      ),
                    );
                  },
                ),
                  _buildActionButton(
                    icon: Icons.qr_code,
                    label: 'QR Code',
                    onPressed: () {
                      _fetchQRCode(context);
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.report,
                    label: 'Report Issue',
                    onPressed: () {},
                  ),
                  _buildActionButton(
                    icon: Icons.eco,
                    label: 'Eco Tips',
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.green[800],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.green[800]),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchQRCode(BuildContext context) async {
    const String qrCodeUrl = "${baseUrl}resident/qr-code/";

    try {
      final response = await http.get(
        Uri.parse(qrCodeUrl),
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String qrCodeString = responseData['qr_code_string'];

        // Show the QR code in a dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Resident QR Code"),
              content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                QrImageView(  // Change QrImage to QrImageView
                  data: qrCodeString,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
                const SizedBox(height: 10),
                SelectableText(
                  qrCodeString,
                  style: TextStyle(fontSize: 16, color: Colors.green[800]),
                ),
              ],
            ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch QR Code: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    const String logoutUrl = "${baseUrl}garbage-collector/logout/";

    try {
      final response = await http.post(
        Uri.parse(logoutUrl),
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WelcomeScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Logged out successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logout failed: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred while logging out: $e")),
      );
    }
  }
}