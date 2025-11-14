import 'package:bizmate/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // ✅ Added for input formatter
import '../../../models/rental_sale_model.dart';

class RentalSaleDetailScreen extends StatefulWidget {
  final RentalSaleModel sale;
  final int index;

  const RentalSaleDetailScreen({
    super.key,
    required this.sale,
    required this.index,
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
        widget.sale.paymentMode.isNotEmpty ? widget.sale.paymentMode : 'Cash';
    isFullyPaid = widget.sale.amountPaid >= widget.sale.totalCost;
  }

  void saveChanges() async {
    if (customerController.text.trim().isEmpty) {
      AppSnackBar.showError(
        context,
        message: "Customer name cannot be empty!",
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (phoneController.text.trim().isEmpty ||
        phoneController.text.trim().length != 10 ||
        !RegExp(r'^[0-9]+$').hasMatch(phoneController.text.trim())) {
      AppSnackBar.showError(
        context,
        message: "Enter a valid 10-digit phone number!",
        duration: const Duration(seconds: 2),
      );
      return;
    }

    double total = double.tryParse(totalController.text) ?? 0;
    double paid =
        double.tryParse(
          amountController.text.isEmpty ? "0" : amountController.text,
        ) ??
        0;

    if (!isFullyPaid && paid < 0) {
      AppSnackBar.showError(
        context,
        message: "Paid amount cannot be negative!",
        duration: const Duration(seconds: 2),
      );
      return;
    }

    widget.sale.customerName = customerController.text;
    widget.sale.customerPhone = phoneController.text;
    widget.sale.totalCost = total;
    widget.sale.amountPaid = paid == 0 && isFullyPaid ? total : paid;
    widget.sale.paymentMode = _selectedMode;

    await widget.sale.save();

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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
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
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
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
                  keyboardType: TextInputType.number,
                  decoration: customInput("Rate per Day", Icons.currency_rupee),
                  readOnly: true,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  decoration: customInput("Number of Days", Icons.today),
                  readOnly: true,
                ),
                const SizedBox(height: 20),

                // 💰 Payment Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Cost",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "₹ ${totalController.text.isEmpty ? '0.00' : totalController.text}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
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
                                    color:
                                        isFullyPaid
                                            ? Colors.green
                                            : Colors.grey,
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
                          height: 40,
                          alignment: Alignment.centerRight,
                          child:
                              isFullyPaid
                                  ? Text(
                                    "₹ ${(double.tryParse(totalController.text) ?? 0).toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.green[700],
                                    ),
                                    textAlign: TextAlign.end,
                                  )
                                  : TextFormField(
                                    controller: amountController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}'),
                                      ), // ✅ only numbers & decimal
                                    ],
                                    textAlign: TextAlign.end,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: "Enter",
                                      hintStyle: TextStyle(
                                        color: Colors.green.shade400,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.currency_rupee,
                                        color: Colors.green.shade700,
                                        size: 20,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.green[700],
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                        ),
                      ],
                    ),
                    const Divider(),

                    // ✅ Dynamic Balance Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          balanceText,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: balanceColor,
                          ),
                        ),
                        Text(
                          "₹ ${balanceDue.abs().toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: balanceColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedMode,
                      items:
                          _paymentModes
                              .map(
                                (mode) => DropdownMenuItem(
                                  value: mode,
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getIconForMode(mode),
                                        color: const Color(0xFF1A237E),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(mode),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) => setState(() => _selectedMode = value!),
                      decoration: InputDecoration(
                        labelText: 'Payment Mode',
                        prefixIcon: const Icon(Icons.payment),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.95),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.blue.shade100),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF1A237E),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
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
