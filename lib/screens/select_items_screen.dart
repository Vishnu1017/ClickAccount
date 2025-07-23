import 'dart:ui';
import 'package:click_account/models/product_store.dart';
import 'package:flutter/material.dart';

class SelectItemsScreen extends StatefulWidget {
  final Function(String)? onItemSaved;

  SelectItemsScreen({this.onItemSaved});

  @override
  _SelectItemsScreenState createState() => _SelectItemsScreenState();
}

class _SelectItemsScreenState extends State<SelectItemsScreen> {
  final TextEditingController itemController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController discountPercentController =
      TextEditingController();
  final TextEditingController discountAmountController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isEditingPercent = true;
  bool showSummarySections = false;

  String? selectedUnit;
  String selectedTaxType = 'Without Tax';
  String? selectedTaxRate;

  final List<String> units = ['Unit', 'Hours', 'Days'];
  final List<String> taxChoiceOptions = ['With Tax', 'Without Tax'];
  final List<String> taxRateOptions = [
    'None',
    'Exempted',
    'GST@0.0%',
    'IGST@0.0%',
    'GST@0.25%',
    'IGST@0.25%',
    'GST@3.0%',
    'IGST@3.0%',
    'GST@5.0%',
    'IGST@5.0%',
    'GST@12.0%',
    'IGST@12.0%',
    'GST@18.0%',
    'IGST@18.0%',
    'GST@28.0%',
    'IGST@28.0%',
  ];

  @override
  void initState() {
    super.initState();
    itemController.addListener(() {
      setState(() {
        showSummarySections = itemController.text.trim().isNotEmpty;
      });
    });
    // Initialize quantity with default value 1
    quantityController.text = '1';
  }

  double parseTaxRate() {
    if (selectedTaxRate == null || !selectedTaxRate!.contains('%')) return 0;
    return double.tryParse(
          selectedTaxRate!.replaceAll(RegExp(r'[^\d.]'), ''),
        ) ??
        0;
  }

  Map<String, double> calculateSummary() {
    final qty = double.tryParse(quantityController.text) ?? 1.0;
    final rawRate = double.tryParse(rateController.text) ?? 0.0;
    final discountPercent =
        isEditingPercent
            ? (double.tryParse(discountPercentController.text) ?? 0.0)
            : 0.0;
    final discountAmount =
        !isEditingPercent
            ? (double.tryParse(discountAmountController.text) ?? 0.0)
            : 0.0;

    final taxPercent = parseTaxRate();
    final taxType = selectedTaxType;

    double rate = rawRate;
    double taxAmount = 0.0;
    double subtotal = 0.0;
    double calculatedDiscountAmount = 0.0;
    double totalAmount = 0.0;

    if (taxType == 'With Tax' && taxPercent > 0) {
      // Tax-inclusive: rawRate includes tax
      rate = (rawRate / (1 + (taxPercent / 100))).toDouble();
      subtotal = (rate * qty).toDouble();

      calculatedDiscountAmount =
          isEditingPercent
              ? (subtotal * discountPercent / 100).toDouble()
              : discountAmount;

      final taxableAmount = subtotal - calculatedDiscountAmount;

      taxAmount =
          calculatedDiscountAmount >= subtotal
              ? 0.0
              : (taxableAmount * taxPercent / 100).toDouble();

      totalAmount = taxableAmount + taxAmount;
    } else {
      // Tax-exclusive or Without Tax
      rate = rawRate;
      subtotal = (rate * qty).toDouble();

      calculatedDiscountAmount =
          isEditingPercent
              ? (subtotal * discountPercent / 100).toDouble()
              : discountAmount > subtotal
              ? subtotal
              : discountAmount;

      final taxableAmount = subtotal - calculatedDiscountAmount;

      taxAmount =
          taxPercent > 0 ? (taxableAmount * taxPercent / 100).toDouble() : 0.0;

      totalAmount = taxableAmount + taxAmount;
    }

    // Update controllers for real-time UI sync
    if (isEditingPercent) {
      discountAmountController.text = calculatedDiscountAmount.toStringAsFixed(
        2,
      );
    } else {
      discountPercentController.text =
          subtotal > 0
              ? ((calculatedDiscountAmount / subtotal) * 100).toStringAsFixed(2)
              : '0.00';
    }

    return {
      'rate': rate,
      'subtotal': subtotal,
      'discountAmount': calculatedDiscountAmount,
      'taxAmount': taxAmount,
      'total': totalAmount,
    };
  }

  @override
  Widget build(BuildContext context) {
    final summary = calculateSummary();

    if (!isEditingPercent) {
      final totalBeforeDiscount = summary['subtotal']! + summary['taxAmount']!;
      final discAmt = double.tryParse(discountAmountController.text) ?? 0;
      final discPct =
          totalBeforeDiscount == 0 ? 0 : (discAmt / totalBeforeDiscount) * 100;
      discountPercentController.text = discPct.toStringAsFixed(2);
    } else {
      discountAmountController.text = summary['discountAmount']!
          .toStringAsFixed(2);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Add Items to Sale"),
        centerTitle: true,
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
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardSection(
                title: "Item Details",
                children: [
                  _buildTextField(
                    itemController,
                    "e.g. Premium Photography",
                    onTap: showItemPicker,
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an item name';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          quantityController,
                          "Quantity",
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: false,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter quantity';
                            }
                            final quantity = int.tryParse(value);
                            if (quantity == null || quantity <= 0) {
                              return 'Quantity must be greater than 0';
                            }
                            if (quantity > 9999) {
                              return 'Maximum quantity is 9999';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          "Unit",
                          selectedUnit,
                          units,
                          (val) => setState(() => selectedUnit = val),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          rateController,
                          "Rate (Price/Unit)",
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a rate';
                            }
                            final rate = double.tryParse(value);
                            if (rate == null || rate <= 0) {
                              return 'Rate must be greater than 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          "Tax Type",
                          selectedTaxType,
                          taxChoiceOptions,
                          (val) => setState(() => selectedTaxType = val!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24),
              if (showSummarySections)
                Column(
                  children: [
                    _buildCardSection(
                      title: "Discount & Tax",
                      children: [
                        _buildSummaryRow("Subtotal", summary['subtotal']!),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                discountPercentController,
                                "Discount %",
                                suffixText: "%",
                                onTap:
                                    () =>
                                        setState(() => isEditingPercent = true),
                                validator:
                                    isEditingPercent
                                        ? (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return null; // Allow empty discount
                                          }
                                          final percent = double.tryParse(
                                            value,
                                          );
                                          if (percent == null ||
                                              percent < 0 ||
                                              percent > 100) {
                                            return 'Enter 0-100%';
                                          }
                                          return null;
                                        }
                                        : null,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                discountAmountController,
                                "Discount ₹",
                                prefixText: "₹ ",
                                onTap:
                                    () => setState(
                                      () => isEditingPercent = false,
                                    ),
                                validator:
                                    !isEditingPercent
                                        ? (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return null; // Allow empty discount
                                          }
                                          final amount = double.tryParse(value);
                                          if (amount == null || amount < 0) {
                                            return 'Invalid amount';
                                          }
                                          if (amount > summary['subtotal']!) {
                                            return 'Cannot exceed subtotal';
                                          }
                                          return null;
                                        }
                                        : null,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        IgnorePointer(
                          ignoring: selectedTaxType != 'With Tax',
                          child: Opacity(
                            opacity: selectedTaxType == 'With Tax' ? 1.0 : 0.4,
                            child: _buildDropdown(
                              "Select Tax Rate",
                              selectedTaxRate,
                              taxRateOptions,
                              (val) => setState(() => selectedTaxRate = val),
                            ),
                          ),
                        ),
                        if (selectedTaxType == 'With Tax' &&
                            parseTaxRate() > 0) ...[
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  "Tax Rate",
                                  "${parseTaxRate().toStringAsFixed(2)}%",
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard(
                                  "Tax Amount",
                                  "₹ ${summary['taxAmount']!.toStringAsFixed(2)}",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 24),
                    _buildCardSection(
                      title: "Total Summary",
                      children: [
                        _buildSummaryRow(
                          "Total Amount",
                          summary['total']!,
                          isBold: true,
                          fontSize: 18,
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                color: Colors.white,
                child: TextButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final itemName = itemController.text.trim();
                      final itemRate =
                          double.tryParse(rateController.text.trim()) ?? 0.0;

                      // ✅ Save to Hive
                      if (itemName.isNotEmpty && itemRate > 0) {
                        ProductStore().add(itemName, itemRate);
                      }

                      // Clear fields
                      itemController.clear();
                      quantityController.text = '1'; // Reset to default value
                      rateController.clear();
                      discountPercentController.clear();
                      discountAmountController.clear();
                      setState(() {
                        selectedUnit = null;
                        selectedTaxRate = null;
                        selectedTaxType = 'Without Tax';
                        showSummarySections = false;
                      });
                    }
                  },
                  child: Text("Save & New"),
                ),
              ),
            ),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00BCD4), Color(0xFF1A237E)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: TextButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final summary = calculateSummary();
                      Navigator.pop(context, {
                        'itemName': itemController.text.trim(),
                        'qty': double.tryParse(quantityController.text) ?? 0,
                        'rate': double.tryParse(rateController.text) ?? 0,
                        'unit': selectedUnit ?? '',
                        'tax': parseTaxRate(),
                        'discount':
                            double.tryParse(discountPercentController.text) ??
                            0,
                        'discountAmount':
                            double.tryParse(discountAmountController.text) ?? 0,
                        'totalAmount': summary['total']!,
                        'subtotal': summary['subtotal']!,
                        'taxType': selectedTaxType,
                      });
                    }
                  },
                  child: Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showItemPicker() {
    final items = ProductStore().getAll(); // returns List<Product>
    if (items.isEmpty) return;

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
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
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
                    "Select Product",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 3.2,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              itemController.text = item.name;
                              rateController.text = item.rate.toStringAsFixed(
                                2,
                              );
                              showSummarySections = true;
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
                                colors: [Color(0xFF00BCD4), Color(0xFF1A237E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    item.name.isNotEmpty
                                        ? item.name[0].toUpperCase()
                                        : '',
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        "₹ ${item.rate.toStringAsFixed(2)}", // 🟢 Show rate
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

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    String? hint,
    String? suffixText,
    String? prefixText,
    Color? fillColor,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffixText,
        prefixText: prefixText,
        border: OutlineInputBorder(),
        fillColor: fillColor,
        filled: fillColor != null,
      ),
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      items:
          options
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSummaryRow(
    String label,
    double value, {
    bool isBold = false,
    double fontSize = 16,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          "₹ ${value.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.black54)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Divider(thickness: 1.2, color: Colors.black),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
