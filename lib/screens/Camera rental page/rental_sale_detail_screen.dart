import 'package:bizmate/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../../../models/rental_sale_model.dart';

class RentalSaleDetailScreen extends StatefulWidget {
  final RentalSaleModel sale;
  final int index;

  /// ✅ User Specific Support Added
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

  late Box userBox;
  List<RentalSaleModel> userSales = [];

  @override
  void initState() {
    super.initState();

    _initUserBox();

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
        widget.sale.paymentMode.isNotEmpty ? widget.sale.paymentMode : 'Cash';
    isFullyPaid = widget.sale.amountPaid >= widget.sale.totalCost;
  }

  Future<void> _initUserBox() async {
    final safeEmail = widget.userEmail
        .replaceAll('.', '_')
        .replaceAll('@', '_');

    userBox = await Hive.openBox("userdata_$safeEmail");

    final stored = userBox.get("rental_sales", defaultValue: []);
    userSales = List<RentalSaleModel>.from(stored);
  }

  /// SAVE CHANGES with user-specific writing
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
        !RegExp(r'^[0-9]+$').hasMatch(phoneController.text.trim())) {
      AppSnackBar.showError(
        context,
        message: "Enter a valid phone number!",
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

    // Update the sale object
    widget.sale.customerName = customerController.text;
    widget.sale.customerPhone = phoneController.text;
    widget.sale.totalCost = total;
    widget.sale.amountPaid = isFullyPaid ? total : paid;
    widget.sale.paymentMode = _selectedMode;

    // Save inside general Hive box
    await widget.sale.save();

    // Save inside USER-SPECIFIC box
    userSales[widget.index] = widget.sale;
    await userBox.put("rental_sales", userSales);

    AppSnackBar.showSuccess(
      context,
      message: 'Rental sale updated successfully!',
    );
    Navigator.pop(context, widget.sale);
  }

  InputDecoration customInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF1A237E),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.blueAccent, width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(widget.sale.rentalDateTime);

    double total = double.tryParse(totalController.text) ?? 0;
    double paid =
        double.tryParse(
          amountController.text.isEmpty ? "0" : amountController.text,
        ) ??
        0;

    double balanceDue = total - paid;

    String balanceText;
    Color balanceColor;

    if (balanceDue > 0) {
      balanceText = "Balance Due";
      balanceColor = Colors.red;
    } else if (balanceDue < 0) {
      balanceText = "Overpaid";
      balanceColor = Colors.green;
    } else {
      balanceText = "Paid in Full";
      balanceColor = Colors.green;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Rental Sale Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 20),
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatted, style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 20),

                TextField(
                  controller: customerController,
                  decoration: customInput("Customer Name", Icons.person),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: customInput("Phone Number", Icons.phone),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: itemController,
                  decoration: customInput("Item Name", Icons.camera_alt),
                  readOnly: true,
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: rateController,
                  readOnly: true,
                  decoration: customInput("Rate per Day", Icons.currency_rupee),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: daysController,
                  readOnly: true,
                  decoration: customInput("Number of Days", Icons.today),
                ),
                const SizedBox(height: 20),

                // PAYMENT SECTION
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Cost",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "₹ ${totalController.text}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isFullyPaid = !isFullyPaid;
                          if (isFullyPaid) {
                            amountController.text = totalController.text;
                          } else {
                            amountController.clear();
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
                                  isFullyPaid
                                      ? Colors.green
                                      : Colors.transparent,
                            ),
                            child:
                                isFullyPaid
                                    ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Received",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    isFullyPaid
                        ? Text(
                          "₹ ${total.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        )
                        : SizedBox(
                          width: 120,
                          child: TextFormField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            textAlign: TextAlign.end,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              prefixText: "₹ ",
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                  ],
                ),
                const Divider(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      balanceText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: balanceColor,
                      ),
                    ),
                    Text(
                      "₹ ${balanceDue.abs().toStringAsFixed(2)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: balanceColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Payment mode
                DropdownButtonFormField<String>(
                  value: _selectedMode,
                  items:
                      _paymentModes
                          .map(
                            (mode) => DropdownMenuItem(
                              value: mode,
                              child: Row(
                                children: [
                                  Icon(_getIconForMode(mode), size: 20),
                                  const SizedBox(width: 8),
                                  Text(mode),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _selectedMode = value!),
                  decoration: InputDecoration(
                    labelText: 'Payment Mode',
                    prefixIcon: const Icon(Icons.payment),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
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
                        style: TextStyle(color: Colors.white, fontSize: 18),
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
      ),
    );
  }

  IconData _getIconForMode(String mode) {
    switch (mode) {
      case 'Cash':
        return Icons.money;
      case 'UPI':
        return Icons.qr_code;
      case 'Card':
        return Icons.credit_card;
      case 'Bank Transfer':
        return Icons.account_balance;
      case 'Cheque':
        return Icons.receipt_long;
      case 'Wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payments;
    }
  }
}
