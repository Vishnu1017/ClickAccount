import 'dart:io';
import 'package:bizmate/models/rental_item.dart';
import 'package:bizmate/models/customer_model.dart';
import 'package:bizmate/models/rental_sale_model.dart' show RentalSaleModel;
import 'package:bizmate/screens/Camera%20rental%20page/rental_add_customer_page.dart'
    show RentalAddCustomerPage;
import 'package:bizmate/widgets/app_snackbar.dart' show AppSnackBar;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class ViewRentalDetailsPage extends StatefulWidget {
  final RentalItem item;
  final String name;
  final String imageUrl;
  final double pricePerDay;
  final String availability;

  const ViewRentalDetailsPage({
    Key? key,
    required this.item,
    required this.name,
    required this.imageUrl,
    required this.pricePerDay,
    required this.availability,
  }) : super(key: key);

  @override
  State<ViewRentalDetailsPage> createState() => _ViewRentalDetailsPageState();
}

class _ViewRentalDetailsPageState extends State<ViewRentalDetailsPage> {
  DateTime? fromDate;
  DateTime? toDate;
  String? selectedFromTime;
  String? selectedToTime;

  int noOfDays = 0;
  double totalAmount = 0.0;

  final List<String> timeSlots = [
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
  ];

  String availabilityStatus = "Available";

  void calculateTotal() {
    if (fromDate != null &&
        toDate != null &&
        selectedFromTime != null &&
        selectedToTime != null) {
      final DateTime fromDateTime = _combineDateAndTime(
        fromDate!,
        selectedFromTime!,
      );
      final DateTime toDateTime = _combineDateAndTime(toDate!, selectedToTime!);

      final difference = toDateTime.difference(fromDateTime).inHours;

      if (difference <= 0) {
        noOfDays = 0;
        totalAmount = 0;
      } else {
        noOfDays = (difference / 24).ceil();
        totalAmount = noOfDays * widget.pricePerDay;
      }

      // ✅ Update availability status
      checkAvailability(fromDateTime, toDateTime);

      setState(() {});
    }
  }

  DateTime _combineDateAndTime(DateTime date, String timeString) {
    final DateFormat format = DateFormat("hh:mm a");
    final time = format.parse(timeString);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void clearSelection() {
    setState(() {
      fromDate = null;
      toDate = null;
      selectedFromTime = null;
      selectedToTime = null;
      noOfDays = 0;
      totalAmount = 0;
      availabilityStatus = "Available";
    });
  }

  Future<void> pickDate(bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
          if (toDate != null && toDate!.isBefore(fromDate!)) {
            toDate = null;
          }
        } else {
          toDate = picked;
        }
        calculateTotal();
      });
    }
  }

  /// ✅ Check availability using all customers' rentals
  void checkAvailability(DateTime from, DateTime to) {
    bool isAvailable = true;

    // 1️⃣ Check CustomerModel rentals
    final customerBox = Hive.box<CustomerModel>('customers');
    for (var customer in customerBox.values) {
      for (var rental in customer.rentals) {
        if (rental.itemName == widget.item.name) {
          final bookedFrom = rental.from;
          final bookedTo = rental.to;

          if ((from.isBefore(bookedTo) && to.isAfter(bookedFrom)) ||
              from.isAtSameMomentAs(bookedFrom) ||
              to.isAtSameMomentAs(bookedTo)) {
            isAvailable = false;
            break;
          }
        }
      }
      if (!isAvailable) break;
    }

    // 2️⃣ Check RentalSaleModel records
    if (isAvailable) {
      final salesBox = Hive.box<RentalSaleModel>('rental_sales');
      for (var sale in salesBox.values) {
        if (sale.itemName == widget.item.name) {
          final bookedFrom = sale.fromDateTime;
          final bookedTo = sale.toDateTime;

          if ((from.isBefore(bookedTo) && to.isAfter(bookedFrom)) ||
              from.isAtSameMomentAs(bookedFrom) ||
              to.isAtSameMomentAs(bookedTo)) {
            isAvailable = false;
            break;
          }
        }
      }
    }

    setState(() {
      availabilityStatus = isAvailable ? "Available" : "Unavailable";
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedFrom =
        fromDate != null
            ? DateFormat('dd/MM/yyyy').format(fromDate!)
            : 'Select date';
    final formattedTo =
        toDate != null
            ? DateFormat('dd/MM/yyyy').format(toDate!)
            : 'Select date';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.3,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 700;
            return isWide
                ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildImageSection()),
                    Expanded(
                      flex: 2,
                      child: buildPricingCard(formattedFrom, formattedTo),
                    ),
                  ],
                )
                : Column(
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: 20),
                    buildPricingCard(formattedFrom, formattedTo),
                  ],
                );
          },
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 5,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(widget.imageUrl),
          height: 260,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder:
              (context, _, __) =>
                  const Icon(Icons.broken_image, size: 100, color: Colors.grey),
        ),
      ),
    );
  }

  Widget buildPricingCard(String formattedFrom, String formattedTo) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      shadowColor: Colors.teal.withOpacity(0.3),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.teal,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Check availability & pricing',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildDateTimeColumn("From", formattedFrom, true),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildDateTimeColumn("To", formattedTo, false)),
              ],
            ),
            const SizedBox(height: 16),

            if (fromDate != null &&
                toDate != null &&
                selectedFromTime != null &&
                selectedToTime != null)
              buildDetailRow('Status', availabilityStatus),
            buildDetailRow('No of days', '$noOfDays'),
            buildDetailRow(
              'Rate/day',
              '₹${widget.pricePerDay.toStringAsFixed(0)}',
            ),
            const Divider(height: 24),
            buildDetailRow(
              'Item Total',
              '₹${totalAmount.toStringAsFixed(0)}',
              isBold: true,
              color: Colors.teal,
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // ✅ Do not proceed if unavailable
                      if (availabilityStatus == "Unavailable") {
                        AppSnackBar.showError(
                          context,
                          message:
                              'Selected dates are not available. Please choose different dates.',
                          duration: Duration(seconds: 2),
                        );

                        return;
                      }

                      final fromDateTime = _combineDateAndTime(
                        fromDate!,
                        selectedFromTime!,
                      );
                      final toDateTime = _combineDateAndTime(
                        toDate!,
                        selectedToTime!,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => RentalAddCustomerPage(
                                rentalItem: widget.item,
                                noOfDays: noOfDays,
                                ratePerDay: widget.pricePerDay,
                                totalAmount: totalAmount,
                                fromDateTime: fromDateTime,
                                toDateTime: toDateTime,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(
                      Icons.person_add_alt_1,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Add Sale',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: clearSelection,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.teal),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.clear_rounded, color: Colors.teal, size: 22),
                        SizedBox(width: 6),
                        Text(
                          'Clear Selection',
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeColumn(String title, String formattedDate, bool isFrom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        buildDatePicker(
          label: '$title date',
          date: formattedDate,
          onTap: () => pickDate(isFrom),
        ),
        const SizedBox(height: 10),
        buildTimeDropdown(
          label: '$title time',
          value: isFrom ? selectedFromTime : selectedToTime,
          onChanged: (val) {
            setState(() {
              if (isFrom)
                selectedFromTime = val;
              else
                selectedToTime = val;
              calculateTotal();
            });
          },
        ),
      ],
    );
  }

  Widget buildDatePicker({
    required String label,
    required String date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(date, style: const TextStyle(fontSize: 14)),
            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget buildTimeDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items:
          timeSlots
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget buildDetailRow(
    String title,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
