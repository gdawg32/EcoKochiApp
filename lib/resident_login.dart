import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'resident_dashboard.dart';

const String baseUrl = "https://ecokochi.pythonanywhere.com/api/";

class ResidentLoginSignupPage extends StatelessWidget {
  const ResidentLoginSignupPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Color(0xFFDCEDC8)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 40),
              ModernButton(
                text: 'Resident Login',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ResidentLoginPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              ModernButton(
                text: 'Resident Signup',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ResidentSignupPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResidentLoginPage extends StatefulWidget {
  const ResidentLoginPage({Key? key}) : super(key: key);

  @override
  _ResidentLoginPageState createState() => _ResidentLoginPageState();
}

class _ResidentLoginPageState extends State<ResidentLoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> loginResident() async {
    final String apiUrl = "${baseUrl}resident/login/";

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": usernameController.text,
          "password": passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];
        final residentDetails = responseData['resident'];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResidentDashboardPage(
              token: token,
              residentDetails: residentDetails,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = jsonDecode(response.body)['error'] ??
              'Failed to login. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[600],
        title: const Text('Resident Login',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Color(0xFFDCEDC8)],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[800]),
                ),
              ),
            ModernTextField(
              controller: usernameController,
              labelText: 'Username',
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 20),
            ModernTextField(
              controller: passwordController,
              labelText: 'Password',
              obscureText: true,
              prefixIcon: Icons.lock,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ModernButton(
                    text: 'Login',
                    onPressed: loginResident,
                  ),
          ],
        ),
      ),
    );
  }
}

class ResidentSignupPage extends StatefulWidget {
  const ResidentSignupPage({Key? key}) : super(key: key);

  @override
  _ResidentSignupPageState createState() => _ResidentSignupPageState();
}

class _ResidentSignupPageState extends State<ResidentSignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController houseNumberController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  String? selectedWard;
  List<Map<String, dynamic>> wards = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchWards();
  }

  Future<void> fetchWards() async {
    const String apiUrl = "${baseUrl}wards/";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> wardList = jsonDecode(response.body);
        setState(() {
          wards = wardList
              .map((ward) => {
                    "ward_no": ward['ward_no'],
                    "name": ward['name'],
                  })
              .toList();
      });
    } else {
      setState(() {
        _errorMessage = "Failed to fetch wards: ${response.body}";
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = "An error occurred: $e";
    });
  }
}

  Future<void> submitApplication() async {
    const String apiUrl = "${baseUrl}resident/apply/";

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": nameController.text,
          "ward_no": selectedWard,
          "house_number": houseNumberController.text,
          "phone_number": phoneNumberController.text,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Application submitted successfully!")),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _errorMessage = "Failed to submit application: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[600],
        title: const Text('Resident Signup',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Color(0xFFDCEDC8)],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[800]),
                ),
              ),
            ModernTextField(
              controller: nameController,
              labelText: 'Name',
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Ward',
                prefixIcon: const Icon(Icons.location_city,
                    color: Colors.green), // Ward icon
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 12.0),
              ),
              value: selectedWard,
              items: wards
                  .map((ward) => DropdownMenuItem(
                        value: ward['ward_no'].toString(),
                        child: Text("${ward['ward_no']} - ${ward['name']}"),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedWard = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ModernTextField(
              controller: houseNumberController,
              labelText: 'House Number',
              prefixIcon: Icons.home,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ModernTextField(
              controller: phoneNumberController,
              labelText: 'Phone Number',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ModernButton(
                    text: 'Submit Application',
                    onPressed: selectedWard == null ? null : submitApplication,
                  ),
          ],
        ),
      ),
    );
  }
}

class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const ModernButton({Key? key, required this.text, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        textStyle: const TextStyle(fontSize: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Text(text),
    );
  }
}

class ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;

  const ModernTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.prefixIcon,
    this.keyboardType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon:
            Icon(prefixIcon, color: Colors.green), // Custom prefix icon color
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      ),
    );
  }
}