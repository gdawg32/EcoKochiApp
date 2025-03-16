import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';


const String baseUrl = "https://ecokochi.pythonanywhere.com/api/";

class ResidentSchedulePage extends StatefulWidget {
  final String token;

  const ResidentSchedulePage({super.key, required this.token});

  @override
  _ResidentSchedulePageState createState() => _ResidentSchedulePageState();
}

class _ResidentSchedulePageState extends State<ResidentSchedulePage> {
  List<dynamic> _assignments = [];
  bool _isLoading = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchAssignments();
  }

  Future<void> fetchAssignments() async {
    final String apiUrl = "${baseUrl}resident/assignments/";

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Token ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _assignments = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load assignments. (${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Collection Schedule"),
        backgroundColor: Colors.green[800],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _assignments.isEmpty
                  ? const Center(child: Text("No collection assigned yet."))
                  : ListView.builder(
                      itemCount: _assignments.length,
                      itemBuilder: (context, index) {
  final assignment = _assignments[index];
  final rawDate = assignment['date'];
  final formattedDate = DateFormat.yMMMMd().format(DateTime.parse(rawDate));
  final phone = assignment['collector_phone'];

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: const Icon(Icons.calendar_today, color: Colors.green),
      title: Text("Collection Date: $formattedDate"),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Collector: ${assignment['collector_name']}"),
          Row(
            children: [
              Text("Phone: $phone"),
              IconButton(
                icon: const Icon(Icons.call, color: Colors.green),
                tooltip: 'Call Collector',
                onPressed: () async {
                  final Uri uri = Uri(scheme: 'tel', path: phone);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Unable to open dialer')),
                    );
                  }
                },
              )

            ],
          ),
        ],
      ),
    ),
  );
}

                    ),
    );
  }
}
