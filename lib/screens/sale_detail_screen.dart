import 'package:click_account/models/payment.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';

class SaleDetailScreen extends StatefulWidget {
  final Sale sale;
  final int index;

  const SaleDetailScreen({super.key, required this.sale, required this.index});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  late TextEditingController customerController;
  late TextEditingController phoneController;
  late TextEditingController productController;
  late TextEditingController amountController;
  late TextEditingController totalAmountController;
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

  IconData _getIconForMode(String mode) {
    switch (mode) {
      case 'Cash':
        return Icons.money;
      case 'UPI':
        return Icons.qr_code_scanner;
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

  @override
  void initState() {
    super.initState();
    customerController = TextEditingController(text: widget.sale.customerName);
    phoneController = TextEditingController(text: widget.sale.phoneNumber);
    productController = TextEditingController(text: widget.sale.productName);
    amountController = TextEditingController(
      text: widget.sale.amount.toString(),
    );
    totalAmountController = TextEditingController(
      text: widget.sale.totalAmount.toString(),
    );
    _selectedMode =
        widget.sale.paymentMode.isNotEmpty ? widget.sale.paymentMode : 'Cash';
    isFullyPaid = widget.sale.amount >= widget.sale.totalAmount;
  }

  void saveChanges() async {
    final box = Hive.box<Sale>('sales');
    final newPayment = Payment(
      amount: double.tryParse(amountController.text) ?? 0,
      date: DateTime.now(),
      mode: _selectedMode,
    );

    final updatedSale = Sale(
      customerName: customerController.text,
      phoneNumber: phoneController.text,
      productName: productController.text,
      amount: newPayment.amount,
      totalAmount: double.tryParse(totalAmountController.text) ?? 0,
      dateTime: widget.sale.dateTime,
      paymentMode: _selectedMode,
      deliveryStatus: widget.sale.deliveryStatus,
      deliveryLink: widget.sale.deliveryLink,
      paymentHistory: [newPayment, ...widget.sale.paymentHistory],
      discount: widget.sale.discount, // ✅ Pass the existing discount value
    );

    await box.putAt(widget.index, updatedSale);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Sale updated successfully!"),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    await Future.delayed(Duration(milliseconds: 500));
    Navigator.pop(context);
  }

  InputDecoration customInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Color(0xFF1A237E),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: Color(0xFF1A237E)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFF1A237E), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFF90CAF9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFF1A237E), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(widget.sale.dateTime);

    return Scaffold(
      backgroundColor: Color(0xFFE3F2FD),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text(
            "Sale Details",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: IconThemeData(color: Colors.white),
          centerTitle: true,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
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
                Text(" $formatted", style: TextStyle(color: Colors.grey[700])),
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
                  controller: productController,
                  decoration: customInput("Product Name", Icons.shopping_bag),
                ),
                SizedBox(height: 30),

                // Fixed Checkbox Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Amount",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "₹ ${totalAmountController.text.isEmpty ? '0.00' : totalAmountController.text}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isFullyPaid = !isFullyPaid;
                              if (isFullyPaid) {
                                amountController.text =
                                    totalAmountController.text;
                              } else {
                                amountController.clear();
                              }
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Clickable Checkbox Only
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isFullyPaid = !isFullyPaid;
                                      if (isFullyPaid) {
                                        amountController.text =
                                            totalAmountController.text;
                                      } else {
                                        amountController.clear();
                                      }
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
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
                                            ? Icon(
                                              Icons.check,
                                              size: 18,
                                              color: Colors.white,
                                            )
                                            : null,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              // Non-clickable Text Label
                              Text(
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
                          width: 100, // Fixed width to match both states
                          height: 40, // Fixed height to match both states
                          alignment:
                              Alignment.centerRight, // Consistent alignment
                          child:
                              isFullyPaid
                                  ? Text(
                                    "₹ ${(double.tryParse(totalAmountController.text) ?? 0).toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.green[700],
                                    ),
                                    textAlign:
                                        TextAlign.end, // Align text to end
                                  )
                                  : TextFormField(
                                    controller: amountController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.end,
                                    decoration: InputDecoration(
                                      isDense: true, // Reduces internal padding
                                      hintText: "Enter",
                                      hintStyle: TextStyle(
                                        color: Colors.green.shade400,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.currency_rupee,
                                        color: Colors.green.shade700,
                                        size: 20, // Consistent icon size
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
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
                    Divider(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Balance Due",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.red[700],
                              ),
                            ),
                            Text(
                              "₹ ${(double.tryParse(totalAmountController.text) ?? 0) - (double.tryParse(amountController.text) ?? 0)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedMode,
                            items:
                                _paymentModes.map((mode) {
                                  return DropdownMenuItem(
                                    value: mode,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getIconForMode(mode),
                                          color: Color(0xFF1A237E),
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          mode,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            dropdownColor: Colors.white,
                            onChanged: (value) {
                              setState(() {
                                _selectedMode = value!;
                              });
                            },
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.payment,
                                color: Color(0xFF1A237E),
                              ),
                              labelText: 'Select payment mode',
                              labelStyle: TextStyle(
                                color: Color(0xFF1A237E),
                                fontWeight: FontWeight.w600,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.95),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.blue.shade100,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Color(0xFF1A237E),
                                  width: 2,
                                ),
                              ),
                            ),
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 30),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: saveChanges,
                    icon: Icon(Icons.save, color: Colors.white),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
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
}
