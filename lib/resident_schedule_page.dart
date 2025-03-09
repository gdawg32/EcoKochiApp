import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = "https://ecokochi.pythonanywhere.com/api/";

class ResidentSchedulePage extends StatefulWidget {
  final String token;

  const ResidentSchedulePage({super.key, required this.token});

  @override
  _ResidentSchedulePageState createState() => _ResidentSchedulePageState();
}

class _ResidentSchedulePageState extends State<ResidentSchedulePage> {
  List<dynamic> schedules = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchSchedule();
  }

  Future<void> fetchSchedule() async {
    const String scheduleUrl = "${baseUrl}resident/schedule/";

    try {
      final response = await http.get(
        Uri.parse(scheduleUrl),
        headers: {
          "Authorization": "Token ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          schedules = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load schedule.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "An error occurred: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Waste Collection Schedule"),
        backgroundColor: Colors.green[800],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
              : schedules.isEmpty
                  ? const Center(child: Text("No schedule available."))
                  : ListView.builder(
                      itemCount: schedules.length,
                      itemBuilder: (context, index) {
                        final schedule = schedules[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.calendar_today, color: Colors.green[800]),
                            title: Text(
                              "${schedule['collection_day']}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Time: ${schedule['start_time']} - ${schedule['end_time']}",
                              style: TextStyle(color: Colors.green[800]),
                            ),
                            trailing: schedule['active']
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : const Icon(Icons.cancel, color: Colors.red),
                          ),
                        );
                      },
                    ),
    );
  }
}
