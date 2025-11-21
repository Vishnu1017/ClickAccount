import 'package:bizmate/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../../../models/rental_sale_model.dart';

class RentalSaleDetailScreen extends StatefulWidget {
  final RentalSaleModel sale;
  final int index;
  final String userEmail;

  const RentalSaleDetailScreen({
    super.key,
    required this.sale,
    required this.index,
    required this.userEmail,
  });

  @override
  State<RentalSaleDetailScreen> createState() => _RentalSaleDetailScreenState();
}

class _RentalSaleDetailScreenState extends State<RentalSaleDetailScreen> {
  late TextEditingController customerController;
  late TextEditingController phoneController;
  late TextEditingController itemController;
  late TextEditingController rateController;
  late TextEditingController daysController;
  late TextEditingController totalController;
  late TextEditingController amountController;

  bool isFullyPaid = false;

  String _selectedMode = 'Cash';

  final List<String> _paymentModes = [
    'Cash',
    'UPI',
    'Card',
    'Bank Transfer',
    'Cheque',
    'Wallet',
  ];

  @override
  void initState() {
    super.initState();

    customerController = TextEditingController(text: widget.sale.customerName);
    phoneController = TextEditingController(text: widget.sale.customerPhone);
    itemController = TextEditingController(text: widget.sale.itemName);
    rateController = TextEditingController(
      text: widget.sale.ratePerDay.toString(),
    );
    daysController = TextEditingController(
      text: widget.sale.numberOfDays.toString(),
    );
    totalController = TextEditingController(
      text: widget.sale.totalCost.toStringAsFixed(2),
    );
    amountController = TextEditingController(
      text: widget.sale.amountPaid.toStringAsFixed(2),
    );

    _selectedMode =
        widget.sale.paymentMode.isNotEmpty ? widget.sale.paymentMode : "Cash";

    isFullyPaid = widget.sale.amountPaid >= widget.sale.totalCost;
  }

  // ⭐ FIXED: Correct Save Logic
  void saveChanges() async {
    if (customerController.text.trim().isEmpty) {
      AppSnackBar.showError(
        context,
        message: "Customer name cannot be empty!",
        duration: Duration(seconds: 2),
      );
      return;
    }

    if (phoneController.text.trim().length != 10 ||
        !RegExp(r'^[0-9]+$').hasMatch(phoneController.text)) {
      AppSnackBar.showError(
        context,
        message: "Enter a valid 10-digit phone number!",
        duration: Duration(seconds: 2),
      );
      return;
    }

    double total = double.tryParse(totalController.text) ?? 0;
    double paid =
        double.tryParse(
          amountController.text.isEmpty ? "0" : amountController.text,
        ) ??
        0;

    widget.sale.customerName = customerController.text;
    widget.sale.customerPhone = phoneController.text;
    widget.sale.totalCost = total;
    widget.sale.amountPaid = isFullyPaid ? total : paid;
    widget.sale.paymentMode = _selectedMode;

    // ⭐ CORRECT HIVE UPDATE (WORKS 100%)
    final safeEmail = widget.userEmail
        .replaceAll('.', '_')
        .replaceAll('@', '_');
    final box = Hive.box("userdata_$safeEmail");

    List<RentalSaleModel> list = List<RentalSaleModel>.from(
      box.get("rental_sales", defaultValue: []),
    );

    list[widget.index] = widget.sale; // replace old with new

    await box.put("rental_sales", list);

    AppSnackBar.showSuccess(
      context,
      message: "Rental sale updated successfully!",
    );

    Navigator.pop(context, true); // trigger refresh
  }

  InputDecoration customInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Color(0xFF1A237E)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.blue.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFF1A237E), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(widget.sale.rentalDateTime);

    double total = double.tryParse(totalController.text) ?? 0;
    double paid = double.tryParse(amountController.text) ?? 0;
    double balance = total - paid;

    return Scaffold(
      backgroundColor: Color(0xFFE3F2FD),
      appBar: AppBar(
        title: Text(
          "Rental Sale Details",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formattedDate, style: TextStyle(color: Colors.grey[700])),
              SizedBox(height: 20),

              TextField(
                controller: customerController,
                decoration: customInput("Customer Name", Icons.person),
              ),
              SizedBox(height: 20),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: customInput("Phone Number", Icons.phone),
              ),
              SizedBox(height: 20),

              TextField(
                controller: itemController,
                readOnly: true,
                decoration: customInput("Item Name", Icons.camera_alt),
              ),
              SizedBox(height: 20),

              TextField(
                controller: rateController,
                readOnly: true,
                decoration: customInput("Rate Per Day", Icons.currency_rupee),
              ),
              SizedBox(height: 20),

              TextField(
                controller: daysController,
                readOnly: true,
                decoration: customInput("Number of Days", Icons.today),
              ),
              SizedBox(height: 20),

              // Payment UI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Cost",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "₹ ${total.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Divider(),

              // Paid / Received
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isFullyPaid = !isFullyPaid;
                        if (isFullyPaid) {
                          amountController.text = total.toStringAsFixed(2);
                        }
                      });
                    },
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isFullyPaid ? Colors.green : Colors.grey,
                              width: 1.5,
                            ),
                            color:
                                isFullyPaid ? Colors.green : Colors.transparent,
                          ),
                          child:
                              isFullyPaid
                                  ? const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                  : null,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Received",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 100,
                    child:
                        isFullyPaid
                            ? Text(
                              "₹ ${total.toStringAsFixed(2)}",
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            )
                            : TextField(
                              controller: amountController,
                              textAlign: TextAlign.end,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                              ),
                            ),
                  ),
                ],
              ),
              Divider(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    balance > 0 ? "Balance Due" : "Paid in Full",
                    style: TextStyle(
                      color: balance > 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "₹ ${balance.abs().toStringAsFixed(2)}",
                    style: TextStyle(
                      color: balance > 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _selectedMode,
                items:
                    _paymentModes
                        .map(
                          (mode) => DropdownMenuItem(
                            value: mode,
                            child: Row(
                              children: [
                                Icon(Icons.payment, size: 20),
                                SizedBox(width: 8),
                                Text(mode),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _selectedMode = v!),
                decoration: customInput("Payment Mode", Icons.payment),
              ),

              SizedBox(height: 30),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: ElevatedButton.icon(
                  onPressed: saveChanges,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    child: Text(
                      "Save Changes",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
