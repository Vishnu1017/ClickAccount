import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
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
              (ctx) => LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive sizing values
                  final bool isSmallScreen = constraints.maxWidth < 600;
                  final double iconSize = isSmallScreen ? 24.0 : 28.0;
                  final double fontSize = isSmallScreen ? 16.0 : 18.0;
                  final double padding = isSmallScreen ? 12.0 : 16.0;
                  final double buttonPadding = isSmallScreen ? 10.0 : 14.0;

                  return AlertDialog(
                    insetPadding: EdgeInsets.all(padding),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    titlePadding: EdgeInsets.fromLTRB(
                      padding,
                      padding,
                      padding,
                      8,
                    ),
                    contentPadding: EdgeInsets.fromLTRB(
                      padding,
                      8,
                      padding,
                      padding,
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: iconSize),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Text(
                          "Confirm Deletion",
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      "Delete all sales by ${customers[index]['name']}?",
                      style: TextStyle(fontSize: fontSize - 2),
                    ),
                    actionsPadding: EdgeInsets.symmetric(
                      horizontal: padding,
                      vertical: 8,
                    ),
                    actions: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: buttonPadding,
                                  vertical: buttonPadding - 4,
                                ),
                              ),
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: fontSize - 2,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 16),
                          Flexible(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: buttonPadding,
                                  vertical: buttonPadding - 4,
                                ),
                              ),
                              icon: Icon(
                                Icons.delete_forever,
                                size: iconSize - 2,
                              ),
                              label: Text(
                                "Delete",
                                style: TextStyle(fontSize: fontSize - 2),
                              ),
                              onPressed: () => Navigator.of(ctx).pop(true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
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

  void _openWhatsApp(
    String phone,
    String name, {
    String? purpose,
    DateTime? dueDate,
    double? amount,
    String? invoiceNumber,
  }) async {
    try {
      final cleanedPhone = phone.replaceAll(' ', '');

      if (cleanedPhone.length < 10 ||
          !RegExp(r'^[0-9]+$').hasMatch(cleanedPhone)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter a valid 10-digit phone number"),
          ),
        );
        return;
      }

      final customerName = name.isNotEmpty ? name : "there";

      String message =
          "Hi $customerName! This is Shutter Life Photography. How can we help you today?";

      if (purpose != null) {
        switch (purpose) {
          case 'followup':
            message =
                "Hi $customerName! 👋\n\nThis is Shutter Life Photography following up on your recent experience with us. "
                "Please let us know if you need any assistance or have any questions!\n\n"
                "We appreciate your business! ❤️";
            break;

          case 'feedback':
            message =
                "Dear $customerName,\n\nThank you for choosing Shutter Life Photography! 🌟\n\n"
                "We would truly value your feedback about your recent experience with us. "
                "Your thoughts help us serve you better!\n\n"
                "Please leave your review here: https://g.page/r/CZdlwsr8XKiUEBM/review\n\n"
                "Warm regards,\nThe Shutter Life Team";
            break;

          case 'promo':
            message =
                "Hello $customerName! 🎉\n\nShutter Life Photography has an exclusive offer just for you:\n\n"
                "✨ 15% OFF your next photo session\n"
                "📸 Free 8x10 print with every booking\n"
                "🎁 Referral bonuses available\n\n"
                "Limited time offer - book now!";
            break;

          case 'instagram_promo':
            message =
                "Hi $customerName! 😊\n\n"
                "Want to see our latest work? 📸\n"
                "Check out our Instagram for stunning shots from weddings, baby shoots, maternity, and more! 💖\n"
                "👉 https://www.instagram.com/shutter_life_photography\n\n"
                "Let us know what style you love most! 😊";
            break;

          case 'payment_confirmation':
            message =
                "Hi $customerName! 🎉\n\n"
                "Payment received ✅ & your booking is now locked in! 🥳\n\n"
                "We can't wait to capture your moments with love and lens! 🎞️📷\n\n"
                "*– Team Shutter Life Photography*";
            break;

          default:
            message =
                "Hello $customerName! 👋\n\nThank you for contacting Shutter Life Photography. "
                "How may we assist you today?";
        }
      }

      final url1 =
          "https://wa.me/$cleanedPhone?text=${Uri.encodeComponent(message)}";
      final url2 =
          "https://wa.me/91$cleanedPhone?text=${Uri.encodeComponent(message)}";

      canLaunchUrl(Uri.parse(url1)).then((canLaunch) {
        if (canLaunch) {
          launchUrl(Uri.parse(url1), mode: LaunchMode.externalApplication);
        } else {
          launchUrl(Uri.parse(url2), mode: LaunchMode.externalApplication);
        }
      });
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
                              icon: const Icon(
                                FontAwesomeIcons.whatsapp,
                                color: Colors.white,
                              ),
                              itemBuilder:
                                  (context) => [
                                    const PopupMenuItem(
                                      value: 'default',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.chat,
                                          color: Colors.blue,
                                        ),
                                        title: Text("General Inquiry"),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'followup',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.update,
                                          color: Colors.orange,
                                        ),
                                        title: Text("Follow Up"),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'feedback',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.feedback,
                                          color: Colors.purple,
                                        ),
                                        title: Text("Feedback Request"),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'promo',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.local_offer,
                                          color: Colors.red,
                                        ),
                                        title: Text("Special Offer"),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'instagram_promo',
                                      child: ListTile(
                                        leading: FaIcon(
                                          FontAwesomeIcons.instagram,
                                          color: Colors.pink,
                                        ),
                                        title: Text("Instagram Promotion"),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'payment_confirmation',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.verified_rounded,
                                          color: Colors.green,
                                        ),
                                        title: Text("Payment Confirmation"),
                                      ),
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
