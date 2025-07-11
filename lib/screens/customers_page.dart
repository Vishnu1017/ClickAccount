import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sale.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomersPage extends StatefulWidget {
  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  List<Map<String, String>> customers = [];

  @override
  void initState() {
    super.initState();
    fetchUniqueCustomers();
  }

  void fetchUniqueCustomers() {
    final box = Hive.box<Sale>('sales');
    final Set<String> seen = {};
    final List<Map<String, String>> uniqueList = [];

    for (var i = 0; i < box.length; i++) {
      final sale = box.getAt(i);
      if (sale != null) {
        final key = "${sale.customerName}_${sale.phoneNumber}";
        if (!seen.contains(key)) {
          seen.add(key);
          uniqueList.add({
            'name': sale.customerName,
            'phone': sale.phoneNumber,
          });
        }
      }
    }

    setState(() => customers = uniqueList);
  }

  Future<bool> _confirmDelete(int index) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 10),
                    Text("Confirm Deletion"),
                  ],
                ),
                content: Text(
                  "Delete all sales by ${customers[index]['name']}?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(Icons.delete_forever),
                    label: Text("Delete"),
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _deleteCustomer(int index) async {
    final box = Hive.box<Sale>('sales');
    final customerToDelete = customers[index];
    final toRemove = <int>[];

    for (var i = 0; i < box.length; i++) {
      final sale = box.getAt(i);
      if (sale != null &&
          sale.customerName == customerToDelete['name'] &&
          sale.phoneNumber == customerToDelete['phone']) {
        toRemove.add(i);
      }
    }

    for (int i = toRemove.length - 1; i >= 0; i--) {
      await box.deleteAt(toRemove[i]);
    }

    fetchUniqueCustomers(); // Refresh
  }

  void _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openWhatsApp(String phone, String name, {String? purpose}) async {
    final cleanedPhone = phone.replaceAll(' ', '');
    final customerName = name.isNotEmpty ? name : "there";

    // Default simple message
    String message =
        "Hi $customerName! This is Shutter Life Photography. How can we help you today?";

    // Optional message variations
    if (purpose != null) {
      switch (purpose) {
        case 'followup':
          message =
              "Hi $customerName! Just following up from Shutter Life Photography. Do you need any assistance?";
          break;
        case 'feedback':
          message =
              "Hi $customerName! We'd love your feedback about your recent Shutter Life Photography experience.";
          break;
        case 'promo':
          message =
              "Hi $customerName! Shutter Life Photography here with an exclusive offer for you!";
          break;
      }
    }

    final encodedMsg = Uri.encodeComponent(message);
    final url = "https://wa.me/$cleanedPhone?text=$encodedMsg";

    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Couldn't open WhatsApp")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6FA),
      body:
          customers.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      "No Customers Yet",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  final name = customer['name'] ?? '';
                  final phone = customer['phone'] ?? '';
                  final initials =
                      name
                          .split(' ')
                          .map((e) => e.isNotEmpty ? e[0] : '')
                          .join()
                          .toUpperCase();

                  return Dismissible(
                    key: Key(name + index.toString()),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete(index),
                    onDismissed: (_) => _deleteCustomer(index),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      margin: EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.delete, color: Colors.white, size: 30),
                    ),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00BCD4), Color(0xFF1A237E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Text(
                            initials,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          phone,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        trailing: Wrap(
                          spacing: 0,
                          children: [
                            IconButton(
                              icon: Icon(Icons.phone, color: Colors.white),
                              onPressed: () => _makePhoneCall(phone),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                FontAwesomeIcons.whatsapp,
                                color: Colors.white,
                              ),
                              itemBuilder:
                                  (context) => [
                                    PopupMenuItem(
                                      value: 'default',
                                      child: Text("General Inquiry"),
                                    ),
                                    PopupMenuItem(
                                      value: 'followup',
                                      child: Text("Follow Up"),
                                    ),
                                    PopupMenuItem(
                                      value: 'feedback',
                                      child: Text("Feedback Request"),
                                    ),
                                    PopupMenuItem(
                                      value: 'promo',
                                      child: Text("Special Offer"),
                                    ),
                                  ],
                              onSelected: (purpose) {
                                if (purpose == 'default') {
                                  _openWhatsApp(phone, name);
                                } else {
                                  _openWhatsApp(phone, name, purpose: purpose);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
