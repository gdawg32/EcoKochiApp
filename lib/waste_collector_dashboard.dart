import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

const String baseUrl = "https://ecokochi.pythonanywhere.com/api/";

// Color scheme for modern eco-themed design
class AppColors {
  static const Color primary = Color(0xFF4CAF50);
  static const Color secondary = Color(0xFF2E7D32);
  static const Color accent = Color(0xFF81C784);
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color error = Color(0xFFE53935);
}

class WasteCollectorDashboard extends StatefulWidget {
  final String token;
  final int collectorId;

  const WasteCollectorDashboard({super.key, required this.token, required this.collectorId});

  @override
  _WasteCollectorDashboardState createState() => _WasteCollectorDashboardState();
}

class _WasteCollectorDashboardState extends State<WasteCollectorDashboard> with SingleTickerProviderStateMixin {
  List<dynamic> _collections = [];
  DateTime? _selectedDate;
  List<dynamic> _assignments = [];
  bool _isLoadingAssignments = false;
  bool _isLoading = true;
  bool _isLoadingCollections = false;
  String _errorMessage = "";
  String _qrCode = "";
  Map<String, dynamic>? _residentData;
  bool _isVerified = false;
  late TabController _tabController; // Declare as late
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredCollections = [];
  double _totalBio = 0;
  double _totalRec = 0;
  double _totalNonRec = 0;
  double _totalHaz = 0;

  @override
  void initState() {
    super.initState();
    // Initialize the TabController here
    _tabController = TabController(length: 3, vsync: this);
    fetchCollections();
    fetchAssignments();
    _searchController.addListener(_filterCollections);
  }

  @override
  void dispose() {
    // Dispose the TabController to avoid memory leaks
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterCollections() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _filteredCollections = _collections;
      });
      return;
    }

    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCollections = _collections.where((item) {
        return item['resident_name'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  void _calculateTotals() {
    _totalBio = _collections.fold(0.0, (sum, item) => sum + (double.tryParse(item['biodegradable_waste'].toString()) ?? 0.0));
    _totalRec = _collections.fold(0.0, (sum, item) => sum + (double.tryParse(item['recyclable_waste'].toString()) ?? 0.0));
    _totalNonRec = _collections.fold(0.0, (sum, item) => sum + (double.tryParse(item['non_recyclable_waste'].toString()) ?? 0.0));
    _totalHaz = _collections.fold(0.0, (sum, item) => sum + (double.tryParse(item['hazardous_waste'].toString()) ?? 0.0));
  }


  Future<void> fetchCollections({DateTime? date}) async {
  setState(() {
    _isLoadingCollections = true;
  });

  String url = "${baseUrl}collector/collections/";
  if (date != null) {
    final formatted = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    url += "?date=$formatted";
  }

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Token ${widget.token}"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _collections = data;
        _filteredCollections = data;
        _calculateTotals();
        _isLoading = false; // This line was missing
      });
    } else {
      setState(() {
        _errorMessage = "Failed to fetch collections.";
        _isLoading = false; // This line was missing
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = "Error fetching collections: $e";
      _isLoading = false; // This line was missing
    });
  } finally {
    setState(() {
      _isLoadingCollections = false;
    });
  }
}

Future<void> fetchAssignments({DateTime? date}) async {
  setState(() {
    _isLoadingAssignments = true;
  });

  String url = "${baseUrl}collector/assignments/";
  if (date != null) {
    final formatted = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    url += "?date=$formatted";
  }

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Token ${widget.token}"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _assignments = data;
      });
    } else {
      setState(() {
        _errorMessage = "Failed to fetch assignments.";
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = "Error fetching assignments: $e";
    });
  } finally {
    setState(() {
      _isLoadingAssignments = false;
    });
  }
}


  Future<void> pickDateAndFetchCollections() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.cardBg,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      fetchCollections(date: picked);
    }
  }

  Future<void> scanQRCode() async {
    String scannedCode = await FlutterBarcodeScanner.scanBarcode(
      "#4CAF50", "Cancel", true, ScanMode.QR);

    if (scannedCode != "-1") {
      setState(() {
        _qrCode = scannedCode;
        _isVerified = false;
        _residentData = null;
      });
      verifyQRCode(scannedCode);
    }
  }

  Future<void> verifyQRCode(String qrCode) async {
    final String apiUrl = "${baseUrl}garbage-collector/waste-collections/verify_qr/";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Token ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "qr_code": qrCode,
          "collector_id": widget.collectorId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data.containsKey("resident_id")) {
        setState(() {
          _isVerified = true;
          _residentData = data;
          _tabController.animateTo(1); // Switch to the logging tab
        });
        _showSuccessSnackBar("QR code validated!", "Ready to log waste for ${data['name']}");
      } else {
        setState(() {
          _isVerified = false;
          _errorMessage = data["message"] ?? "Invalid QR code.";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Invalid QR code."),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred: $e";
      });
    }
  }

  Future<void> deleteCollection(int id) async {
    final String url = "${baseUrl}waste-collection/delete/$id/";

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Authorization": "Token ${widget.token}",
        },
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar("Success", "Collection deleted successfully");
        fetchCollections(date: _selectedDate); // Refresh the list
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${error['error'] ?? 'Failed to delete.'}"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> updateCollection(int id, double bio, double rec, double nonRec, double haz) async {
    final String url = "${baseUrl}waste-collection/update/$id/";

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Authorization": "Token ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "biodegradable_waste": bio,
          "recyclable_waste": rec,
          "non_recyclable_waste": nonRec,
          "hazardous_waste": haz,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar("Success", "Collection updated successfully");
        fetchCollections(date: _selectedDate);
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${error['error'] ?? 'Failed to update.'}"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> logWasteCollection(double biodegradable, double recyclable, double nonRecyclable, double hazardous) async {
    if (!_isVerified || _residentData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please verify a QR code before logging waste collection."),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    const String apiUrl = "${baseUrl}waste-collection/add/";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Token ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "resident": _residentData!['resident_id'],
          "collector_id": widget.collectorId,
          "biodegradable_waste": biodegradable,
          "recyclable_waste": recyclable,
          "non_recyclable_waste": nonRecyclable,
          "hazardous_waste": hazardous,
        }),
      );

      if (response.statusCode == 201) {
        _showSuccessSnackBar("Success", "Waste collection logged successfully!");
        setState(() {
          _residentData = null;
          _isVerified = false;
        });
        fetchCollections(); // Refresh the collections list
        _tabController.animateTo(0); // Switch back to the collections tab
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to log waste collection."),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(message, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.secondary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDate(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      final parts = dateTimeString.split('T');
      if (parts.isEmpty) return 'N/A';
      
      final dateParts = parts[0].split('-');
      if (dateParts.length != 3) return parts[0];
      
      return "${dateParts[2]}-${dateParts[1]}-${dateParts[0]}";
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "EcoKochi Collection",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        actions: [
  IconButton(
    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
    onPressed: scanQRCode,
    tooltip: "Scan Resident QR Code",
  ),
  IconButton(
    icon: const Icon(Icons.refresh, color: Colors.white),
    onPressed: () {
      fetchCollections(date: _selectedDate);
      fetchAssignments(date: _selectedDate);
    },
    tooltip: "Refresh Data",
  ),
],
        bottom: TabBar(
  controller: _tabController,
  indicatorColor: Colors.white,
  tabs: [
    Tab(
      icon: const Icon(Icons.list, color: Colors.white),
      child: Text(
        "Collections",
        style: GoogleFonts.poppins(color: Colors.white),
      ),
    ),
    Tab(
      icon: const Icon(Icons.assignment, color: Colors.white),
      child: Text(
        "Assignments",
        style: GoogleFonts.poppins(color: Colors.white),
      ),
    ),
    Tab(
      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
      child: Text(
        "Log Waste",
        style: GoogleFonts.poppins(color: Colors.white),
      ),
    ),
  ],
),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: GoogleFonts.poppins(
                          color: AppColors.error,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _errorMessage = "";
                            _isLoading = true;
                          });
                          fetchCollections();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: Text("Retry", style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Collections Tab
                    RefreshIndicator(
                      onRefresh: () => fetchCollections(date: _selectedDate),
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search and date filter
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: "Search by resident",
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: pickDateAndFetchCollections,
                                    icon: const Icon(Icons.date_range),
                                    label: Text(
                                      _selectedDate == null
                                          ? "Filter Date"
                                          : DateFormat('dd/MM/yy').format(_selectedDate!),
                                      style: GoogleFonts.poppins(),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Stats Snapshot
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Collection Summary",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          _statCard("Bio", _totalBio.toStringAsFixed(1), "kg", Colors.green[100]!, Colors.green),
                                          _statCard("Recylable", _totalRec.toStringAsFixed(1), "kg", Colors.blue[100]!, Colors.blue),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _statCard("Non-Recylable", _totalNonRec.toStringAsFixed(1), "kg", Colors.orange[100]!, Colors.orange),
                                          _statCard("Hazardous", _totalHaz.toStringAsFixed(1), "kg", Colors.red[100]!, Colors.red),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            Text(
                              "Recent Collections",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Collections List
                            _isLoadingCollections
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      ),
                                    ),
                                  )
                                : _filteredCollections.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(32.0),
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.inventory_2_outlined,
                                                size: 60,
                                                color: AppColors.textSecondary,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                "No collections found",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _filteredCollections.length,
                                        itemBuilder: (context, index) {
                                          final item = _filteredCollections[index];
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey.withOpacity(0.1),
                                                  blurRadius: 5,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: ExpansionTile(
                                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              expandedCrossAxisAlignment: CrossAxisAlignment.start,
                                              title: Row(
                                                children: [
                                                  const CircleAvatar(
                                                    backgroundColor: AppColors.accent,
                                                    child: Icon(Icons.person, color: Colors.white),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          item['resident_name'] ?? "Unknown",
                                                          style: GoogleFonts.poppins(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        Text(
                                                          "Date: ${_formatDate(item['date_time'])}",
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 14,
                                                            color: AppColors.textSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Divider(),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                        children: [
                                                          _wasteTypeIndicator("Bio", item['biodegradable_waste'].toString(), Colors.green),
                                                          _wasteTypeIndicator("Rec", item['recyclable_waste'].toString(), Colors.blue),
                                                          _wasteTypeIndicator("Non-Rec", item['non_recyclable_waste'].toString(), Colors.orange),
                                                          _wasteTypeIndicator("Haz", item['hazardous_waste'].toString(), Colors.red),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 16),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                        children: [
                                                          OutlinedButton.icon(
                                                            icon: const Icon(Icons.edit, size: 18),
                                                            label: const Text("Edit"),
                                                            onPressed: () {
                                                              showDialog(
                                                                context: context,
                                                                builder: (ctx) => UpdateWasteDialog(
                                                                  initialData: item,
                                                                  onUpdate: (bio, rec, nonRec, haz) {
                                                                    updateCollection(item['id'], bio, rec, nonRec, haz);
                                                                  },
                                                                ),
                                                              );
                                                            },
                                                            style: OutlinedButton.styleFrom(
                                                              foregroundColor: AppColors.primary,
                                                              side: const BorderSide(color: AppColors.primary),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          OutlinedButton.icon(
                                                            icon: const Icon(Icons.delete, size: 18),
                                                            label: const Text("Delete"),
                                                            onPressed: () {
                                                              showDialog(
                                                                context: context,
                                                                builder: (ctx) => AlertDialog(
                                                                  title: Text(
                                                                    "Confirm Delete",
                                                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                                                  ),
                                                                  content: Text(
                                                                    "Are you sure you want to delete this collection?",
                                                                    style: GoogleFonts.poppins(),
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () => Navigator.pop(ctx),
                                                                      child: Text(
                                                                        "Cancel",
                                                                        style: GoogleFonts.poppins(),
                                                                      ),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed: () {
                                                                        Navigator.pop(ctx);
                                                                        deleteCollection(item['id']);
                                                                      },
                                                                      child: Text(
                                                                        "Delete",
                                                                        style: GoogleFonts.poppins(color: AppColors.error),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                            style: OutlinedButton.styleFrom(
                                                              foregroundColor: AppColors.error,
                                                              side: const BorderSide(color: AppColors.error),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                          ],
                        ),
                      ),
                    ),
                    
                  // Assignments Tab (new)
    RefreshIndicator(
      onRefresh: () => fetchAssignments(date: _selectedDate),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date filter
            Row(
              children: [
                const Spacer(),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.primary,
                                onPrimary: Colors.white,
                                surface: AppColors.cardBg,
                                onSurface: AppColors.textPrimary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        fetchAssignments(date: picked);
                      }
                    },
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _selectedDate == null
                          ? "Filter Date"
                          : DateFormat('dd/MM/yy').format(_selectedDate!),
                      style: GoogleFonts.poppins(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Text(
              "Assigned Residents",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            // Assignments List
            _isLoadingAssignments
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  )
                : _assignments.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.assignment_outlined,
                                size: 60,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No assignments found for this date",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _assignments.length,
                        itemBuilder: (context, index) {
                          final assignment = _assignments[index];
                          print("Assignment: $assignment");
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.accent,
                                child: Text(
                                  assignment['house_number']?.toString() ?? 'N/A',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                assignment['name'] ?? 'Unknown Resident',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    "Address: ${assignment['address'] ?? 'Not available'}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "Phone: ${assignment['phone'] ?? 'Not available'}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: ElevatedButton.icon(
                                onPressed: () {
                                  scanQRCode();
                                },
                                icon: const Icon(Icons.assignment_turned_in, color: Colors.white),
                                label: const Text("Collect", style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    ),

                    // Log Waste Tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_residentData != null) ...[
                            // Resident Info Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_circle,
                                          color: AppColors.primary,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Resident Verified",
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              _residentData!['name'],
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Resident ID: ${_residentData!['resident_id']}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Waste Logging Form
                          WasteLoggingForm(
                            onSubmit: logWasteCollection,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // Helper Widgets
  Widget _statCard(String label, String value, String unit, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "$value $unit",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wasteTypeIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "$value kg",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// Waste Logging Form Widget
class WasteLoggingForm extends StatefulWidget {
  final Function(double, double, double, double) onSubmit;

  const WasteLoggingForm({super.key, required this.onSubmit});

  @override
  _WasteLoggingFormState createState() => _WasteLoggingFormState();
}

class _WasteLoggingFormState extends State<WasteLoggingForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController biodegradableController = TextEditingController();
  final TextEditingController recyclableController = TextEditingController();
  final TextEditingController nonRecyclableController = TextEditingController();
  final TextEditingController hazardousController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: biodegradableController,
            decoration: const InputDecoration(
              labelText: "Biodegradable (kg)",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter a value";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: recyclableController,
            decoration: const InputDecoration(
              labelText: "Recyclable (kg)",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter a value";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: nonRecyclableController,
            decoration: const InputDecoration(
              labelText: "Non-Recyclable (kg)",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter a value";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: hazardousController,
            decoration: const InputDecoration(
              labelText: "Hazardous (kg)",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter a value";
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                widget.onSubmit(
                  double.tryParse(biodegradableController.text) ?? 0.0,
                  double.tryParse(recyclableController.text) ?? 0.0,
                  double.tryParse(nonRecyclableController.text) ?? 0.0,
                  double.tryParse(hazardousController.text) ?? 0.0,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Log Waste Collection",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Update Waste Dialog Widget
class UpdateWasteDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(double, double, double, double) onUpdate;

  const UpdateWasteDialog({super.key, required this.initialData, required this.onUpdate});

  @override
  State<UpdateWasteDialog> createState() => _UpdateWasteDialogState();
}

class _UpdateWasteDialogState extends State<UpdateWasteDialog> {
  late TextEditingController bioCtrl;
  late TextEditingController recCtrl;
  late TextEditingController nonRecCtrl;
  late TextEditingController hazCtrl;

  @override
  void initState() {
    super.initState();
    bioCtrl = TextEditingController(text: widget.initialData['biodegradable_waste'].toString());
    recCtrl = TextEditingController(text: widget.initialData['recyclable_waste'].toString());
    nonRecCtrl = TextEditingController(text: widget.initialData['non_recyclable_waste'].toString());
    hazCtrl = TextEditingController(text: widget.initialData['hazardous_waste'].toString());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Update Waste Collection",
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: bioCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Biodegradable (kg)"),
            ),
            TextField(
              controller: recCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Recyclable (kg)"),
            ),
            TextField(
              controller: nonRecCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Non-Recyclable (kg)"),
            ),
            TextField(
              controller: hazCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Hazardous (kg)"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Cancel",
            style: GoogleFonts.poppins(),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final bio = double.tryParse(bioCtrl.text) ?? 0.0;
            final rec = double.tryParse(recCtrl.text) ?? 0.0;
            final nonRec = double.tryParse(nonRecCtrl.text) ?? 0.0;
            final haz = double.tryParse(hazCtrl.text) ?? 0.0;
            Navigator.pop(context);
            widget.onUpdate(bio, rec, nonRec, haz);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: Text(
            "Update",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      ],
    );
  }
}