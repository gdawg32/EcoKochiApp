import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart';

const String baseUrl = "https://ecokochi.pythonanywhere.com/api/"; // Global variable for base URL

class ResidentDashboardPage extends StatelessWidget {
  final String token;
  final Map<String, dynamic> residentDetails;

  // Constructor that takes the token and resident details
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
              // Handle logout functionality
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
              // Welcome Section
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

              // Quick Actions Section
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
                physics: const NeverScrollableScrollPhysics(), // Disable GridView scrolling
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildActionButton(
                    icon: Icons.calendar_today,
                    label: 'Schedule',
                    onPressed: () {
                      // Navigate to garbage collection schedule
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.qr_code,
                    label: 'QR Code',
                    onPressed: () {
                      // Navigate to QR code page
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.report,
                    label: 'Report Issue',
                    onPressed: () {
                      // Navigate to report issue page
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.eco,
                    label: 'Eco Tips',
                    onPressed: () {
                      // Navigate to eco tips page
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add functionality for quick action
        },
        backgroundColor: Colors.green[800],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Custom Action Button Widget
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

  // Custom Activity Tile Widget
  Widget _buildActivityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green[900],
          ),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }

  // Logout function that sends the POST request and navigates back to the login screen
  Future<void> _logout(BuildContext context) async {
    const String logoutUrl = "${baseUrl}garbage-collector/logout/";

    try {
      final response = await http.post(
        Uri.parse(logoutUrl),
        headers: {
          "Authorization": "Token $token", // Using the passed token for authentication
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