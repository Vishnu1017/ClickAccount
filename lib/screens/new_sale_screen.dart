import 'package:click_account/models/payment.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/sale.dart';
import 'select_items_screen.dart';
import 'dart:ui';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final customerController = TextEditingController();
  final productController = TextEditingController();
  final amountController = TextEditingController();
  final totalAmountController = TextEditingController();
  final receivedController = TextEditingController();
  final phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  bool isFullyPaid = false;
  // ignore: prefer_final_fields
  String _selectedMode = 'Cash';
  bool isCustomerSelectedFromList = false;

  List<Map<String, String>> customerList = [];
  Map<String, dynamic>? selectedItemDetails;
  List<Map<String, dynamic>> selectedItems = [];

  double get totalQty => selectedItems.length.toDouble();
  double get totalDiscount {
    double discount = 0.0;

    for (final item in selectedItems) {
      final qty = double.tryParse(item['qty']?.toString() ?? '1') ?? 1;
      final rawRate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
      final discountPercent =
          double.tryParse(item['discount']?.toString() ?? '0') ?? 0;
      final taxPercent = double.tryParse(item['tax']?.toString() ?? '0') ?? 0;
      final taxType = item['taxType']?.toString() ?? 'Without Tax';

      double rate = rawRate;

      if (taxType == 'With Tax' && taxPercent > 0) {
        rate = rawRate / (1 + (taxPercent / 100));
      }

      final itemSubtotal = rate * qty;
      final discountAmount = itemSubtotal * discountPercent / 100;

      discount += discountAmount;
    }

    return discount;
  }

  double get totalTaxAmount {
    double totalTax = 0.0;

    for (final item in selectedItems) {
      final qty = double.tryParse(item['qty']?.toString() ?? '1') ?? 1;
      final rawRate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
      final discountPercent =
          double.tryParse(item['discount']?.toString() ?? '0') ?? 0;
      final taxPercent = double.tryParse(item['tax']?.toString() ?? '0') ?? 0;
      final taxType = item['taxType']?.toString() ?? 'Without Tax';

      double rate = rawRate;

      if (taxType == 'With Tax' && taxPercent > 0) {
        rate = rawRate / (1 + (taxPercent / 100));
      }

      final itemSubtotal = rate * qty;
      final discountAmount = subtotal * discountPercent / 100;
      final taxableAmount = itemSubtotal - discountAmount;

      double taxAmount = 0.0;
      if (taxType == 'With Tax' && discountPercent < 100) {
        taxAmount = taxableAmount * taxPercent / 100;
      }

      totalTax += taxAmount;
    }

    return totalTax;
  }

  double get subtotal {
    double sum = 0.0;

    for (final item in selectedItems) {
      final qty = double.tryParse(item['qty']?.toString() ?? '1') ?? 1;
      final rawRate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
      final discountPercent =
          double.tryParse(item['discount']?.toString() ?? '0') ?? 0;
      final taxPercent = double.tryParse(item['tax']?.toString() ?? '0') ?? 0;
      final taxType = item['taxType']?.toString() ?? 'Without Tax';

      double rate = rawRate;

      if (taxType == 'With Tax' && taxPercent > 0) {
        rate = rawRate / (1 + (taxPercent / 100));
      }

      final itemSubtotal = rate * qty;
      final discountAmount = itemSubtotal * discountPercent / 100;
      final taxableAmount = itemSubtotal - discountAmount;
      final taxAmount =
          discountPercent == 100
              ? 0.0
              : (taxType == 'With Tax' && taxPercent > 0)
              ? taxableAmount * taxPercent / 100
              : 0.0;
      final totalAmount = taxableAmount + taxAmount;

      sum += totalAmount;
    }

    return sum;
  }

  @override
  void initState() {
    super.initState();
    fetchCustomerList();
  }

  void fetchCustomerList() {
    final box = Hive.box<Sale>('sales');
    final Set<String> seen = {};
    final List<Map<String, String>> uniqueCustomers = [];

    for (var i = 0; i < box.length; i++) {
      final sale = box.getAt(i);
      if (sale != null) {
        final key = "${sale.customerName}_${sale.phoneNumber}";
        if (!seen.contains(key)) {
          seen.add(key);
          uniqueCustomers.add({
            'name': sale.customerName,
            'phone': sale.phoneNumber,
          });
        }
      }
    }

    setState(() {
      customerList = uniqueCustomers;
    });
  }

  Future<bool> isPhoneNumberDuplicate() async {
    // Skip duplicate check if customer was selected from list
    if (isCustomerSelectedFromList) return false;

    final saleBox = Hive.box<Sale>('sales');
    final phoneNumber = phoneController.text.trim();

    if (phoneNumber.isEmpty) return false;

    return saleBox.values.any((sale) => sale.phoneNumber.trim() == phoneNumber);
  }

  void addItem() async {
    final newItem = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SelectItemsScreen()),
    );

    if (newItem != null && newItem is Map<String, dynamic>) {
      newItem['tax'] = _parsePercent(newItem['tax']);
      newItem['discount'] = _parsePercent(newItem['discount']);
      newItem['qty'] =
          double.tryParse(newItem['qty']?.toString() ?? '1') ?? 1.0;
      newItem['rate'] =
          double.tryParse(newItem['rate']?.toString() ?? '0') ?? 0.0;
      newItem['itemName'] ??= '';
      newItem['totalAmount'] ??= 0.0;

      setState(() {
        selectedItems.add(newItem);
        productController.text = selectedItems
            .map((e) => e['itemName'])
            .join(', ');
        totalAmountController.text = subtotal.toStringAsFixed(2);
      });
    }
  }

  void _showCustomCalendar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          height: 440,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "📅 Select Date",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  physics: ClampingScrollPhysics(),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TableCalendar(
                      focusedDay: selectedDate,
                      firstDay: DateTime(2000),
                      lastDay: DateTime(2100),
                      selectedDayPredicate:
                          (day) => isSameDay(selectedDate, day),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.deepOrange,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Colors.indigo,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                        ),
                      ),
                      onDaySelected: (day, focusedDay) {
                        setState(() {
                          selectedDate = day;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _parsePercent(dynamic value) {
    if (value == null) return 0.0;
    final str = value.toString().replaceAll('%', '').trim();
    return double.tryParse(str) ?? 0.0;
  }

  Widget buildItemCard(int index, Map<String, dynamic> item) {
    final qty = double.tryParse(item['qty']?.toString() ?? '1') ?? 1.0;
    final rawRate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0.0;
    final discountPercent =
        double.tryParse(item['discount']?.toString() ?? '0') ?? 0.0;
    final taxPercent = double.tryParse(item['tax']?.toString() ?? '0') ?? 0.0;
    final taxType = item['taxType']?.toString() ?? 'Without Tax';

    double rate = rawRate;
    double taxAmount = 0.0;
    double subtotal = 0.0;
    double discountAmount = 0.0;
    double totalAmount = 0.0;

    if (taxType == 'With Tax' && taxPercent > 0) {
      rate = rawRate / (1 + taxPercent / 100);
      subtotal = rate * qty;

      discountAmount = subtotal * discountPercent / 100;
      final taxableAmount = subtotal - discountAmount;

      taxAmount =
          discountAmount >= subtotal ? 0.0 : taxableAmount * taxPercent / 100;

      totalAmount = taxableAmount + taxAmount;
    } else {
      rate = rawRate;
      subtotal = rate * qty;

      discountAmount = subtotal * discountPercent / 100;
      final taxableAmount = subtotal - discountAmount;

      taxAmount = taxPercent > 0 ? taxableAmount * taxPercent / 100 : 0.0;

      totalAmount = taxableAmount + taxAmount;
    }

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "#${index + 1}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['itemName']?.toString() ?? '',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                Text(
                  "₹ ${totalAmount.toStringAsFixed(2)}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              "Item Subtotal: $qty x ₹${rate.toStringAsFixed(2)} = ₹${subtotal.toStringAsFixed(2)}",
              style: TextStyle(color: Colors.black87),
            ),
            Text(
              "Discount (${discountPercent.toStringAsFixed(2)}%): ₹${discountAmount.toStringAsFixed(2)}",
              style: TextStyle(color: Colors.orange[800]),
            ),
            if (taxPercent > 0)
              Text(
                "Tax (${taxPercent.toStringAsFixed(2)}%): ₹${taxAmount.toStringAsFixed(2)}",
                style: TextStyle(color: Colors.blueGrey[700]),
              ),
          ],
        ),
      ),
    );
  }

  void showCustomerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 420,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  Text(
                    "Select Customer",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 2;
                        if (constraints.maxWidth > 600) {
                          crossAxisCount = 3;
                        }
                        if (constraints.maxWidth > 900) {
                          crossAxisCount = 4;
                        }

                        return GridView.builder(
                          itemCount: customerList.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 3.2,
                              ),
                          itemBuilder: (context, index) {
                            final customer = customerList[index];
                            final initials =
                                customer['name']!
                                    .split(' ')
                                    .map((e) => e.isNotEmpty ? e[0] : '')
                                    .join();

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  customerController.text = customer['name']!;
                                  phoneController.text = customer['phone']!;
                                  isCustomerSelectedFromList = true;
                                });
                                Navigator.pop(context);
                              },
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF00BCD4),
                                      Color(0xFF1A237E),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(2, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: Text(
                                        initials.toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A237E),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            customer['name']!,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            customer['phone']!,
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void saveSale() async {
    setState(() => isLoading = true);

    final saleBox = Hive.box<Sale>('sales');
    final newPayment = Payment(
      amount: double.tryParse(amountController.text) ?? 0,
      date: DateTime.now(),
      mode: _selectedMode,
    );

    final sale = Sale(
      customerName: customerController.text,
      productName: productController.text,
      phoneNumber: phoneController.text,
      amount: newPayment.amount,
      totalAmount: double.tryParse(totalAmountController.text) ?? 0,
      dateTime: selectedDate,
      deliveryStatus: 'Editing',
      paymentHistory: [newPayment],
    );

    await saleBox.add(sale);

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Sale saved successfully!"),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    await Future.delayed(Duration(milliseconds: 800));
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
    return Scaffold(
      backgroundColor: Color(0xFFE3F2FD),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("New Sale", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: customerController,
                onTap: showCustomerPicker,
                decoration: customInput("Customer Name", Icons.person).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(Icons.arrow_drop_down),
                    onPressed: showCustomerPicker,
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                validator:
                    (val) => val!.trim().isEmpty ? 'Enter customer name' : null,
                onChanged: (value) {
                  if (value.isNotEmpty && value[0] != value[0].toUpperCase()) {
                    customerController.text = value.splitMapJoin(
                      ' ',
                      onNonMatch:
                          (word) =>
                              word.isNotEmpty
                                  ? word[0].toUpperCase() +
                                      (word.length > 1
                                          ? word.substring(1).toLowerCase()
                                          : '')
                                  : '',
                    );
                    customerController.selection = TextSelection.fromPosition(
                      TextPosition(offset: customerController.text.length),
                    );
                  }
                  if (isCustomerSelectedFromList) {
                    setState(() {
                      isCustomerSelectedFromList = false;
                    });
                  }
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: customInput("Phone Number", Icons.phone),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Enter phone number';
                  }
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(val)) {
                    return 'Enter valid 10-digit number';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (isCustomerSelectedFromList) {
                    setState(() {
                      isCustomerSelectedFromList = false;
                    });
                  }
                },
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () => _showCustomCalendar(context),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Color(0xFF1A237E)),
                          SizedBox(width: 10),
                          Text(
                            "Select Sale Date",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text(
                    'Add Items',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: addItem,
                ),
              ),
              SizedBox(height: 20),
              if (selectedItems.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Billed Items',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                ...selectedItems
                    .asMap()
                    .entries
                    .map((entry) => buildItemCard(entry.key, entry.value))
                    .toList(),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Disc: ₹ ${totalDiscount.toStringAsFixed(2)}"),
                    Text(
                      "Total Tax Amt: ₹ ${totalTaxAmount.toStringAsFixed(2)}",
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Qty: ${totalQty.toStringAsFixed(1)}"),
                    Text("Subtotal: ${subtotal.toStringAsFixed(2)}"),
                  ],
                ),
              ],
              SizedBox(height: 20),
              Container(
                margin: EdgeInsets.only(top: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 4),
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
                  ],
                ),
              ),
              SizedBox(height: 30),
              isLoading
                  ? CircularProgressIndicator()
                  : Container(
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
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;

                        // Check for duplicate phone number only if customer wasn't selected from list
                        if (!isCustomerSelectedFromList) {
                          final isDuplicate = await isPhoneNumberDuplicate();
                          if (isDuplicate) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "A customer with this phone number already exists!",
                                ),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                        }

                        // Proceed with saving
                        saveSale();
                      },
                      icon: Icon(Icons.save, color: Colors.white),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        child: Text(
                          "Save Sale",
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
