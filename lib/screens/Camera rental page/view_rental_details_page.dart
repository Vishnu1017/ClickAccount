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

  late Box userBox;
  List<CustomerModel> userCustomers = [];
  List<RentalSaleModel> userRentalSales = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final sessionBox = Hive.box('session');
    final email = sessionBox.get("currentUserEmail", defaultValue: "");

    final safeEmail = email
        .toString()
        .replaceAll('.', '_')
        .replaceAll('@', '_');

    final userBoxName = "userdata_$safeEmail";

    if (!Hive.isBoxOpen(userBoxName)) {
      Hive.openBox(userBoxName);
    }

    userBox = Hive.box(userBoxName);

    userCustomers = List<CustomerModel>.from(
      userBox.get('customers', defaultValue: []),
    );

    userRentalSales = List<RentalSaleModel>.from(
      userBox.get('rental_sales', defaultValue: []),
    );
  }

  void calculateTotal() {
    if (fromDate != null &&
        toDate != null &&
        selectedFromTime != null &&
        selectedToTime != null) {
      final fromDT = _combineDateAndTime(fromDate!, selectedFromTime!);
      final toDT = _combineDateAndTime(toDate!, selectedToTime!);

      final diff = toDT.difference(fromDT).inHours;

      if (diff <= 0) {
        noOfDays = 0;
        totalAmount = 0;
      } else {
        noOfDays = (diff / 24).ceil();
        totalAmount = noOfDays * widget.pricePerDay;
      }

      checkAvailability(fromDT, toDT);
      setState(() {});
    }
  }

  DateTime _combineDateAndTime(DateTime date, String timeString) {
    final DateFormat format = DateFormat("hh:mm a");
    final t = format.parse(timeString);
    return DateTime(date.year, date.month, date.day, t.hour, t.minute);
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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
          if (toDate != null && toDate!.isBefore(fromDate!)) toDate = null;
        } else {
          toDate = picked;
        }
        calculateTotal();
      });
    }
  }

  void checkAvailability(DateTime from, DateTime to) {
    bool isAvailable = true;

    for (var customer in userCustomers) {
      for (var rental in customer.rentals) {
        if (rental.itemName == widget.item.name) {
          if ((from.isBefore(rental.to) && to.isAfter(rental.from)) ||
              from.isAtSameMomentAs(rental.from) ||
              to.isAtSameMomentAs(rental.to)) {
            isAvailable = false;
            break;
          }
        }
      }
      if (!isAvailable) break;
    }

    if (isAvailable) {
      for (var sale in userRentalSales) {
        if (sale.itemName == widget.item.name) {
          if ((from.isBefore(sale.toDateTime) &&
                  to.isAfter(sale.fromDateTime)) ||
              from.isAtSameMomentAs(sale.fromDateTime) ||
              to.isAtSameMomentAs(sale.toDateTime)) {
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

  Widget _buildNeumorphicCard({
    required Widget child,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 20,
            offset: const Offset(10, 10),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 20,
            offset: const Offset(-10, -10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDateTimeButton(bool isFrom) {
    final dateTime = isFrom ? fromDate : toDate;
    final label = isFrom ? "From" : "To";
    final icon = isFrom ? Icons.calendar_today : Icons.calendar_month;

    return Expanded(
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(4, 4),
            ),
            BoxShadow(
              color: Colors.white,
              blurRadius: 10,
              offset: const Offset(-4, -4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: () => pickDate(isFrom),
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(icon, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dateTime == null
                          ? "Select $label Date"
                          : DateFormat('dd/MM/yyyy').format(dateTime),
                      style: TextStyle(
                        color:
                            dateTime == null
                                ? Colors.grey.shade500
                                : Colors.grey.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDropdown(bool isFrom) {
    final value = isFrom ? selectedFromTime : selectedToTime;
    final label = isFrom ? "From Time" : "To Time";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 10,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items:
            timeSlots
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(
                      t,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
        onChanged: (val) {
          setState(() {
            if (isFrom) {
              selectedFromTime = val;
            } else {
              selectedToTime = val;
            }
            calculateTotal();
          });
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        dropdownColor: Colors.white,
        style: TextStyle(
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w500,
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade600),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final isAvailable = availabilityStatus == "Available";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.error,
            color: isAvailable ? Colors.green.shade600 : Colors.red.shade600,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            availabilityStatus,
            style: TextStyle(
              color: isAvailable ? Colors.green.shade800 : Colors.red.shade800,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    return _buildNeumorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.attach_money_rounded,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Pricing Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPriceRow(
            "Daily Rate",
            "₹${widget.pricePerDay.toStringAsFixed(0)}",
          ),
          _buildPriceRow("Number of Days", "$noOfDays days"),
          if (fromDate != null &&
              toDate != null &&
              selectedFromTime != null &&
              selectedToTime != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Status",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _buildStatusIndicator(),
                ],
              ),
            ),
          Divider(height: 24, color: Colors.grey.shade300),
          _buildPriceRow(
            "Total Amount",
            "₹${totalAmount.toStringAsFixed(0)}",
            isTotal: true,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade300,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      onTap: () async {
                        if (availabilityStatus == "Unavailable") {
                          AppSnackBar.showError(
                            context,
                            message: 'Selected dates are not available.',
                            duration: const Duration(seconds: 2),
                          );
                          return;
                        }

                        if (fromDate == null ||
                            toDate == null ||
                            selectedFromTime == null ||
                            selectedToTime == null) {
                          AppSnackBar.showWarning(
                            context,
                            message: 'Please select both date and time',
                          );
                          return;
                        }

                        final fromDT = _combineDateAndTime(
                          fromDate!,
                          selectedFromTime!,
                        );
                        final toDT = _combineDateAndTime(
                          toDate!,
                          selectedToTime!,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => RentalAddCustomerPage(
                                  rentalItem: widget.item,
                                  noOfDays: noOfDays,
                                  ratePerDay: widget.pricePerDay,
                                  totalAmount: totalAmount,
                                  fromDateTime: fromDT,
                                  toDateTime: toDT,
                                ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_checkout,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Book Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset: const Offset(4, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                  child: InkWell(
                    onTap: clearSelection,
                    borderRadius: BorderRadius.circular(15),
                    child: Icon(
                      Icons.refresh,
                      color: Colors.grey.shade600,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? Colors.blue.shade800 : Colors.grey.shade800,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.grey.shade700,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.name,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              background: Stack(
                children: [
                  Positioned.fill(
                    child:
                        widget.imageUrl.isNotEmpty &&
                                File(widget.imageUrl).existsSync()
                            ? Image.file(
                              File(widget.imageUrl),
                              fit: BoxFit.cover,
                            )
                            : Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.photo_camera,
                                color: Colors.grey.shade400,
                                size: 60,
                              ),
                            ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Date Selection Section
                _buildNeumorphicCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.calendar_today,
                              color: Colors.orange.shade600,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Select Rental Period",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildDateTimeButton(true),
                          const SizedBox(width: 12),
                          _buildDateTimeButton(false),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTimeDropdown(true)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTimeDropdown(false)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Pricing Section
                _buildPriceCard(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
