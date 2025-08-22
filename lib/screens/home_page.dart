// ignore_for_file: unused_local_variable, unnecessary_null_comparison

import 'package:click_account/models/sale.dart';
import 'package:click_account/models/user_model.dart';
import 'package:click_account/screens/DeliveryTrackerPage.dart';
import 'package:click_account/screens/WhatsAppHelper.dart';
import 'package:click_account/screens/payment_history_page.dart';
import 'package:click_account/screens/pdf_preview_screen.dart';
import 'package:click_account/screens/sale_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum DateRangePreset {
  today,
  thisWeek,
  thisMonth,
  thisQuarter,
  thisFinancialYear,
  custom,
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String welcomeMessage = "";
  late AnimationController _controller;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;
  DateTimeRange? selectedRange;
  DateRangePreset? selectedPreset;

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: selectedRange,
    );
    if (picked != null) {
      setState(() {
        selectedRange = picked;
        selectedPreset = DateRangePreset.custom;
      });
    }
  }

  void _handlePresetSelection(DateRangePreset preset) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (preset) {
      case DateRangePreset.today:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day);
        break;
      case DateRangePreset.thisWeek:
        startDate = DateTime(now.year, now.month, now.day - now.weekday + 1);
        endDate = DateTime(now.year, now.month, now.day - now.weekday + 7);
        break;
      case DateRangePreset.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case DateRangePreset.thisQuarter:
        final quarter = (now.month - 1) ~/ 3 + 1;
        startDate = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
        endDate = DateTime(now.year, quarter * 3 + 1, 0);
        break;
      case DateRangePreset.thisFinancialYear:
        // Assuming financial year starts in April
        startDate =
            now.month >= 4
                ? DateTime(now.year, 4, 1)
                : DateTime(now.year - 1, 4, 1);
        endDate =
            now.month >= 4
                ? DateTime(now.year + 1, 3, 31)
                : DateTime(now.year, 3, 31);
        break;
      case DateRangePreset.custom:
        _selectDateRange(context);
        return;
    }

    setState(() {
      selectedRange = DateTimeRange(start: startDate, end: endDate);
      selectedPreset = preset;
    });
  }

  void _clearDateFilter() {
    setState(() {
      selectedRange = null;
      selectedPreset = null;
    });
  }

  Future<String> _getCurrentUserEmailFromHive() async {
    try {
      // Open the users box if not already open
      final usersBox = await Hive.openBox<User>('users');

      // Get the current user from your session or state management
      // This depends on how you're managing the current user in your app

      // Option 1: If you have a session box with current user email
      final sessionBox = await Hive.openBox('session');
      final currentUserEmail = sessionBox.get('currentUserEmail');

      if (currentUserEmail != null) {
        return currentUserEmail;
      }

      // Option 2: If you have only one user in the box
      if (usersBox.isNotEmpty) {
        final user = usersBox.values.first;
        return user.email;
      }

      // Option 3: If you're passing user context somehow
      // You might need to modify this based on your app's architecture

      // Fallback: Return empty string if no user found
      return '';
    } catch (e) {
      debugPrint('Error getting user email from Hive: $e');
      return '';
    }
  }

  void fetchWelcomeMessage() {
    final userBox = Hive.box<User>('users');

    // Assuming only one user is logged in or stored at a time
    final user = userBox.values.isNotEmpty ? userBox.values.first : null;

    setState(() {
      welcomeMessage =
          user != null ? "🏠 Welcome back, \n ${user.name}!" : "🏠 Welcome!";
    });
  }

  @override
  void initState() {
    super.initState();
    fetchWelcomeMessage();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _controller.forward();

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchExpanded =
            _searchFocusNode.hasFocus || _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildAdvancedSearchBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 600;
        final bool isVerySmallScreen = constraints.maxWidth < 400;

        return Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(
                horizontal:
                    isVerySmallScreen
                        ? 12
                        : isSmallScreen
                        ? 16
                        : 20,
                vertical: 15,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color:
                              _isSearchExpanded
                                  ? Colors.indigo.withOpacity(0.3)
                                  : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: isVerySmallScreen ? 16 : 20,
                                right: 10,
                              ),
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                decoration: InputDecoration(
                                  hintText:
                                      isVerySmallScreen
                                          ? 'Search...'
                                          : isSmallScreen
                                          ? 'Search sales...'
                                          : 'Search by customer, product, phone, amount...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: isVerySmallScreen ? 14 : null,
                                  ),
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                    _isSearchExpanded =
                                        value.isNotEmpty ||
                                        _searchFocusNode.hasFocus;
                                  });
                                },
                              ),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: Duration(milliseconds: 200),
                            child:
                                _searchController.text.isEmpty
                                    ? IconButton(
                                      icon: Icon(
                                        Icons.search,
                                        color: Colors.indigo,
                                        size: isVerySmallScreen ? 20 : 24,
                                      ),
                                      onPressed: () {
                                        _searchFocusNode.requestFocus();
                                      },
                                    )
                                    : IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        color: Colors.grey,
                                        size: isVerySmallScreen ? 20 : 24,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        _searchFocusNode.unfocus();
                                        setState(() {
                                          _searchQuery = "";
                                          _isSearchExpanded = false;
                                        });
                                      },
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: isVerySmallScreen ? 8 : 10),
                  Container(
                    height: 50,
                    width: isVerySmallScreen ? 50 : (isSmallScreen ? 50 : null),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: PopupMenuButton<DateRangePreset>(
                      icon: Icon(
                        Icons.tune_rounded,
                        color: Colors.blue[800],
                        size: isVerySmallScreen ? 20 : 24,
                      ),
                      onSelected: _handlePresetSelection,
                      itemBuilder:
                          (BuildContext context) =>
                              <PopupMenuEntry<DateRangePreset>>[
                                PopupMenuItem<DateRangePreset>(
                                  value: DateRangePreset.today,
                                  child: Text('Today'),
                                ),
                                PopupMenuItem<DateRangePreset>(
                                  value: DateRangePreset.thisWeek,
                                  child: Text('This Week'),
                                ),
                                PopupMenuItem<DateRangePreset>(
                                  value: DateRangePreset.thisMonth,
                                  child: Text('This Month'),
                                ),
                                PopupMenuItem<DateRangePreset>(
                                  value: DateRangePreset.thisQuarter,
                                  child: Text('This Quarter'),
                                ),
                                PopupMenuItem<DateRangePreset>(
                                  value: DateRangePreset.thisFinancialYear,
                                  child: Text('This Financial Year'),
                                ),
                                PopupMenuItem<DateRangePreset>(
                                  value: DateRangePreset.custom,
                                  child: Text('Custom Range'),
                                ),
                              ],
                    ),
                  ),
                ],
              ),
            ),
            if (selectedRange != null)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      isVerySmallScreen
                          ? 12
                          : isSmallScreen
                          ? 16
                          : 20,
                ),
                child: Row(
                  children: [
                    Chip(
                      label: Text(
                        '${DateFormat('dd MMM yyyy').format(selectedRange!.start)} - ${DateFormat('dd MMM yyyy').format(selectedRange!.end)}',
                        style: TextStyle(fontSize: isVerySmallScreen ? 10 : 12),
                      ),
                      backgroundColor: Colors.blue[50],
                      deleteIcon: Icon(Icons.close, size: 16),
                      onDeleted: _clearDateFilter,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget buildSalesList() {
    final saleBox = Hive.box<Sale>('sales');
    return ValueListenableBuilder(
      valueListenable: saleBox.listenable(),
      builder: (context, Box<Sale> box, _) {
        // Get all sales and sort them by date in descending order (newest first)
        List<Sale> sales =
            box.values.toList()
              ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

        // Filter sales based on search query
        if (_searchQuery.isNotEmpty) {
          sales =
              sales.where((sale) {
                final customerName = sale.customerName.toLowerCase();
                final productName = sale.productName.toLowerCase();
                final phoneNumber = sale.phoneNumber.toLowerCase();
                final amount = sale.totalAmount.toString();
                final date = DateFormat('dd MMM yyyy').format(sale.dateTime);
                final query = _searchQuery.toLowerCase();

                return customerName.contains(query) ||
                    productName.contains(query) ||
                    phoneNumber.contains(query) ||
                    amount.contains(query) ||
                    date.contains(query);
              }).toList();
        }

        // Filter sales based on date range
        if (selectedRange != null) {
          sales =
              sales.where((sale) {
                return sale.dateTime.isAfter(
                      selectedRange!.start.subtract(Duration(days: 1)),
                    ) &&
                    sale.dateTime.isBefore(
                      selectedRange!.end.add(Duration(days: 1)),
                    );
              }).toList();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isSmallScreen = constraints.maxWidth < 600;
            final bool isVerySmallScreen = constraints.maxWidth < 400;
            final bool isLargeScreen = constraints.maxWidth > 900;

            return Column(
              children: [
                _buildAdvancedSearchBar(),

                if (box.isEmpty &&
                    _searchQuery.isEmpty &&
                    selectedRange == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Center(
                      child: Text(
                        welcomeMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize:
                              isVerySmallScreen
                                  ? 16
                                  : isSmallScreen
                                  ? 18
                                  : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (sales.isEmpty &&
                    (_searchQuery.isNotEmpty || selectedRange != null))
                  Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Center(
                      child: Text(
                        _searchQuery.isNotEmpty && selectedRange != null
                            ? "No results found for '$_searchQuery' in selected date range"
                            : _searchQuery.isNotEmpty
                            ? "No results found for '$_searchQuery'"
                            : "No sales found in selected date range",
                        style: TextStyle(
                          fontSize:
                              isVerySmallScreen
                                  ? 12
                                  : isSmallScreen
                                  ? 14
                                  : 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                if (box.isNotEmpty &&
                    _searchQuery.isEmpty &&
                    selectedRange == null)
                  SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.only(
                      bottom: 90,
                      left:
                          isVerySmallScreen
                              ? 4
                              : isSmallScreen
                              ? 8
                              : 0,
                      right:
                          isVerySmallScreen
                              ? 4
                              : isSmallScreen
                              ? 8
                              : 0,
                    ),
                    itemCount: sales.length,
                    itemBuilder: (context, index) {
                      final sale = sales[index];
                      if (sale == null) return SizedBox.shrink();

                      // Get the original index from the box to maintain invoice numbering
                      final originalIndex = box.values.toList().indexOf(sale);
                      final invoiceNumber = originalIndex + 1;
                      final formattedDate = DateFormat(
                        'dd MMM yyyy',
                      ).format(sale.dateTime);
                      final formattedTime = DateFormat(
                        'hh:mm a',
                      ).format(sale.dateTime);

                      double balanceAmount = (sale.totalAmount - sale.amount)
                          .clamp(0, double.infinity);

                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal:
                              isVerySmallScreen
                                  ? 13
                                  : isSmallScreen
                                  ? 15
                                  : 27,
                          vertical: isVerySmallScreen ? 6 : 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => SaleDetailScreen(
                                      sale: sale,
                                      index: originalIndex,
                                    ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(
                              isVerySmallScreen
                                  ? 10
                                  : isSmallScreen
                                  ? 12
                                  : 16,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 15),
                                if (!isVerySmallScreen) ...[
                                  Column(
                                    children: [
                                      CircleAvatar(
                                        radius: isSmallScreen ? 20 : 24,
                                        backgroundColor: Color(0xFF1A237E),
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: isSmallScreen ? 20 : 24,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Invoice #$invoiceNumber",
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 10 : 12,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        DateFormat(
                                          'dd MMM',
                                        ).format(sale.dateTime),
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 10 : 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'hh:mm a',
                                        ).format(sale.dateTime),
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 10 : 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: isSmallScreen ? 12 : 16),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (isVerySmallScreen) ...[
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Color(
                                                0xFF1A237E,
                                              ),
                                              child: Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                sale.customerName,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Invoice #$invoiceNumber • ${DateFormat('dd MMM, hh:mm a').format(sale.dateTime)}",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ] else ...[
                                        Text(
                                          sale.customerName,
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 15 : 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                      SizedBox(
                                        height: isVerySmallScreen ? 4 : 6,
                                      ),
                                      Text(
                                        sale.productName,
                                        style: TextStyle(
                                          fontSize:
                                              isVerySmallScreen
                                                  ? 12
                                                  : isSmallScreen
                                                  ? 13
                                                  : 14,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        sale.phoneNumber,
                                        style: TextStyle(
                                          fontSize:
                                              isVerySmallScreen
                                                  ? 12
                                                  : isSmallScreen
                                                  ? 13
                                                  : 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Divider(height: 16, thickness: 1),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Total:",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize:
                                                  isVerySmallScreen
                                                      ? 12
                                                      : isSmallScreen
                                                      ? 13
                                                      : null,
                                            ),
                                          ),
                                          Text(
                                            "₹${sale.totalAmount.toStringAsFixed(2)}",
                                            style: TextStyle(
                                              fontSize:
                                                  isVerySmallScreen
                                                      ? 12
                                                      : isSmallScreen
                                                      ? 13
                                                      : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Paid:",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize:
                                                  isVerySmallScreen
                                                      ? 12
                                                      : isSmallScreen
                                                      ? 13
                                                      : null,
                                            ),
                                          ),
                                          Text(
                                            "₹${sale.amount.toStringAsFixed(2)}",
                                            style: TextStyle(
                                              fontSize:
                                                  isVerySmallScreen
                                                      ? 12
                                                      : isSmallScreen
                                                      ? 13
                                                      : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Balance:",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize:
                                                  isVerySmallScreen
                                                      ? 12
                                                      : isSmallScreen
                                                      ? 13
                                                      : null,
                                            ),
                                          ),
                                          Text(
                                            "₹${(sale.totalAmount - sale.amount).clamp(0, double.infinity).toStringAsFixed(2)}",
                                            style: TextStyle(
                                              color: Colors.red[700],
                                              fontSize:
                                                  isVerySmallScreen
                                                      ? 12
                                                      : isSmallScreen
                                                      ? 13
                                                      : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Builder(
                                          builder: (context) {
                                            final bool isFullyPaid =
                                                sale.amount >= sale.totalAmount;
                                            final bool isPartiallyPaid =
                                                sale.amount > 0 &&
                                                sale.amount < sale.totalAmount;
                                            final bool isUnpaid =
                                                sale.amount == 0;

                                            final bool isDueOver7Days =
                                                isUnpaid &&
                                                sale.dateTime != null &&
                                                DateTime.now()
                                                        .difference(
                                                          sale.dateTime,
                                                        )
                                                        .inDays >
                                                    7;

                                            String label = '';
                                            Color badgeColor =
                                                Colors.orange[700]!;

                                            if (isFullyPaid) {
                                              label = "SALE : PAID";
                                              badgeColor = Colors.green[600]!;
                                            } else if (isPartiallyPaid) {
                                              label = "SALE : PARTIAL";
                                              badgeColor = Colors.lightBlue;
                                            } else if (isDueOver7Days) {
                                              label = "SALE : DUE";
                                              badgeColor = Colors.orange[700]!;

                                              final due =
                                                  sale.totalAmount -
                                                  sale.amount;
                                              final phone =
                                                  sale.phoneNumber
                                                      .replaceAll('+91', '')
                                                      .trim();
                                              final msg =
                                                  "Hello ${sale.customerName}, your payment of ₹${due.toStringAsFixed(2)} is overdue for more than 7 days. Please make the payment at the earliest. - Shutter Life Photography";
                                              if (phone != null &&
                                                  phone.isNotEmpty) {
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                      WhatsAppHelper.sendWhatsAppMessage(
                                                        phone: phone,
                                                        message: msg,
                                                      );
                                                    });
                                              }
                                            } else {
                                              label = "SALE : PARTIAL";
                                              badgeColor = Colors.lightBlue;
                                            }

                                            return Align(
                                              alignment: Alignment.centerRight,
                                              child: Container(
                                                margin: EdgeInsets.only(top: 6),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      isVerySmallScreen
                                                          ? 6
                                                          : isSmallScreen
                                                          ? 8
                                                          : 12,
                                                  vertical:
                                                      isVerySmallScreen
                                                          ? 3
                                                          : isSmallScreen
                                                          ? 4
                                                          : 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: badgeColor,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: badgeColor
                                                          .withOpacity(0.3),
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  label,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        isVerySmallScreen
                                                            ? 9
                                                            : isSmallScreen
                                                            ? 10
                                                            : 12,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isVerySmallScreen) ...[
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert,
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                    onSelected: (value) async {
                                      final scaffoldContext = context;

                                      if (value == 'delete') {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          barrierDismissible: false,
                                          builder:
                                              (ctx) => LayoutBuilder(
                                                builder: (
                                                  context,
                                                  constraints,
                                                ) {
                                                  // Responsive sizing values
                                                  final bool isSmallScreen =
                                                      constraints.maxWidth <
                                                      600;
                                                  final double iconSize =
                                                      isSmallScreen
                                                          ? 24.0
                                                          : 28.0;
                                                  final double fontSize =
                                                      isSmallScreen
                                                          ? 16.0
                                                          : 18.0;
                                                  final double padding =
                                                      isSmallScreen
                                                          ? 12.0
                                                          : 16.0;
                                                  final double buttonPadding =
                                                      isSmallScreen
                                                          ? 10.0
                                                          : 14.0;

                                                  return AlertDialog(
                                                    insetPadding:
                                                        EdgeInsets.all(padding),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                    titlePadding:
                                                        EdgeInsets.fromLTRB(
                                                          padding,
                                                          padding,
                                                          padding,
                                                          8,
                                                        ),
                                                    contentPadding:
                                                        EdgeInsets.fromLTRB(
                                                          padding,
                                                          8,
                                                          padding,
                                                          padding,
                                                        ),
                                                    title: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.warning,
                                                          color: Colors.red,
                                                          size: iconSize,
                                                        ),
                                                        SizedBox(
                                                          width:
                                                              isSmallScreen
                                                                  ? 8
                                                                  : 12,
                                                        ),
                                                        Text(
                                                          "Confirm Deletion",
                                                          style: TextStyle(
                                                            fontSize: fontSize,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    content: Text(
                                                      'Are you sure you want to delete this sale? This action cannot be undone.',
                                                      style: TextStyle(
                                                        fontSize: fontSize - 2,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    actionsPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: padding,
                                                          vertical: 8,
                                                        ),
                                                    actions: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Flexible(
                                                            child: TextButton(
                                                              style: TextButton.styleFrom(
                                                                padding: EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      buttonPadding,
                                                                  vertical:
                                                                      buttonPadding -
                                                                      4,
                                                                ),
                                                              ),
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.of(
                                                                        ctx,
                                                                      ).pop(
                                                                        false,
                                                                      ),
                                                              child: Text(
                                                                "Cancel",
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .grey[700],
                                                                  fontSize:
                                                                      fontSize -
                                                                      2,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width:
                                                                isSmallScreen
                                                                    ? 8
                                                                    : 16,
                                                          ),
                                                          Flexible(
                                                            child: ElevatedButton.icon(
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors.red,
                                                                foregroundColor:
                                                                    Colors
                                                                        .white,
                                                                padding: EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      buttonPadding,
                                                                  vertical:
                                                                      buttonPadding -
                                                                      4,
                                                                ),
                                                              ),
                                                              icon: Icon(
                                                                Icons
                                                                    .delete_forever,
                                                                size:
                                                                    iconSize -
                                                                    2,
                                                              ),
                                                              label: Text(
                                                                "Delete",
                                                                style: TextStyle(
                                                                  fontSize:
                                                                      fontSize -
                                                                      2,
                                                                ),
                                                              ),
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.of(
                                                                        ctx,
                                                                      ).pop(
                                                                        true,
                                                                      ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                        );

                                        if (confirm == true) {
                                          box.deleteAt(originalIndex);
                                          ScaffoldMessenger.of(
                                            scaffoldContext,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "🗑️ Sale deleted successfully.",
                                              ),
                                              backgroundColor: Colors.red[400],
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } else if (value == 'share_pdf') {
                                        final pdf = pw.Document();
                                        final balanceAmount =
                                            (sale.totalAmount - sale.amount)
                                                .clamp(0, double.infinity);
                                        final rupeeFont = pw.Font.ttf(
                                          await rootBundle.load(
                                            'assets/fonts/Roboto-Regular.ttf',
                                          ),
                                        );

                                        // Ask user for editable amount before QR generation
                                        final TextEditingController
                                        _amountController =
                                            TextEditingController(
                                              text: balanceAmount
                                                  .toStringAsFixed(2),
                                            );

                                        final enteredAmount = await showDialog<
                                          double?
                                        >(
                                          context: scaffoldContext,
                                          builder: (context) {
                                            final controller =
                                                TextEditingController(
                                                  text: balanceAmount
                                                      .toStringAsFixed(2),
                                                );

                                            final screenWidth =
                                                MediaQuery.of(
                                                  context,
                                                ).size.width;

                                            return Dialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth:
                                                      screenWidth < 400
                                                          ? screenWidth * 0.9
                                                          : 400,
                                                ),
                                                child: SingleChildScrollView(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 16,
                                                        ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        // Header
                                                        Container(
                                                          width:
                                                              double.infinity,
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Colors
                                                                    .deepPurple,
                                                            borderRadius:
                                                                BorderRadius.vertical(
                                                                  top:
                                                                      Radius.circular(
                                                                        16,
                                                                      ),
                                                                ),
                                                          ),
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                vertical: 20,
                                                              ),
                                                          child: Column(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .qr_code_2_rounded,
                                                                size: 40,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                              SizedBox(
                                                                height: 8,
                                                              ),
                                                              Text(
                                                                'Customize UPI Amount',
                                                                style: TextStyle(
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),

                                                        // Body
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 20,
                                                                vertical: 20,
                                                              ),
                                                          child: Column(
                                                            children: [
                                                              Text(
                                                                "Enter the amount you want to show in the UPI QR. Leave it empty if the customer should enter manually.",
                                                                style: TextStyle(
                                                                  fontSize: 14,
                                                                  color:
                                                                      Colors
                                                                          .black87,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              ),
                                                              SizedBox(
                                                                height: 16,
                                                              ),
                                                              TextField(
                                                                controller:
                                                                    controller,
                                                                keyboardType:
                                                                    TextInputType.numberWithOptions(
                                                                      decimal:
                                                                          true,
                                                                    ),
                                                                decoration: InputDecoration(
                                                                  labelText:
                                                                      'Amount (₹)',
                                                                  prefixIcon: Icon(
                                                                    Icons
                                                                        .currency_rupee,
                                                                  ),
                                                                  border: OutlineInputBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          10,
                                                                        ),
                                                                  ),
                                                                  filled: true,
                                                                  fillColor:
                                                                      Colors
                                                                          .grey[100],
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: 24,
                                                              ),
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .end,
                                                                children: [
                                                                  TextButton(
                                                                    child: Text(
                                                                      'Cancel',
                                                                      style: TextStyle(
                                                                        color:
                                                                            Colors.grey[700],
                                                                      ),
                                                                    ),
                                                                    onPressed:
                                                                        () => Navigator.pop(
                                                                          context,
                                                                          null,
                                                                        ),
                                                                  ),
                                                                  SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  ElevatedButton(
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .deepPurple,
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              10,
                                                                            ),
                                                                      ),
                                                                      padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            24,
                                                                        vertical:
                                                                            12,
                                                                      ),
                                                                    ),
                                                                    onPressed: () {
                                                                      final input =
                                                                          controller
                                                                              .text
                                                                              .trim();
                                                                      final parsed =
                                                                          double.tryParse(
                                                                            input,
                                                                          );
                                                                      Navigator.pop(
                                                                        context,
                                                                        (input.isEmpty ||
                                                                                parsed ==
                                                                                    null ||
                                                                                parsed <=
                                                                                    0)
                                                                            ? null
                                                                            : parsed,
                                                                      );
                                                                    },
                                                                    child: Text(
                                                                      'Generate QR',
                                                                      style: TextStyle(
                                                                        color:
                                                                            Colors.white,
                                                                        fontSize:
                                                                            15,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );

                                        final qrData =
                                            enteredAmount != null
                                                ? 'upi://pay?pa=playroll.vish-1@oksbi&pn=Vishnu&am=${enteredAmount.toStringAsFixed(2)}&cu=INR'
                                                : 'upi://pay?pa=playroll.vish-1@oksbi&pn=Vishnu&cu=INR';

                                        final qrImage = pw.Barcode.qrCode()
                                            .toSvg(
                                              qrData,
                                              width: 120,
                                              height: 120,
                                            );

                                        final prefs =
                                            await SharedPreferences.getInstance();

                                        // FIX: Get the current user's email from Hive
                                        final currentUserEmail =
                                            await _getCurrentUserEmailFromHive();

                                        final profileImagePath = prefs.getString(
                                          '${currentUserEmail}_profileImagePath',
                                        );
                                        pw.MemoryImage? headerImage;

                                        if (profileImagePath != null) {
                                          final profileFile = File(
                                            profileImagePath,
                                          );
                                          if (await profileFile.exists()) {
                                            final imageBytes =
                                                await profileFile.readAsBytes();
                                            headerImage = pw.MemoryImage(
                                              imageBytes,
                                            );
                                          }
                                        }

                                        pdf.addPage(
                                          pw.Page(
                                            build:
                                                (
                                                  pw.Context context,
                                                ) => pw.Container(
                                                  decoration: pw.BoxDecoration(
                                                    border: pw.Border.all(
                                                      color: PdfColors.black,
                                                      width: 2,
                                                    ),
                                                    borderRadius: pw
                                                        .BorderRadius.circular(
                                                      6,
                                                    ),
                                                  ),
                                                  padding: pw.EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: pw.Column(
                                                    crossAxisAlignment:
                                                        pw
                                                            .CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      pw.Row(
                                                        crossAxisAlignment:
                                                            pw
                                                                .CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          if (headerImage !=
                                                              null)
                                                            pw.Container(
                                                              width: 60,
                                                              height: 60,
                                                              child: pw.Image(
                                                                headerImage,
                                                                fit:
                                                                    pw
                                                                        .BoxFit
                                                                        .cover,
                                                              ),
                                                            ),
                                                          if (headerImage !=
                                                              null)
                                                            pw.SizedBox(
                                                              width: 16,
                                                            ),
                                                          pw.Column(
                                                            crossAxisAlignment:
                                                                pw
                                                                    .CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              pw.Text(
                                                                'Shutter Life Photography',
                                                                style: pw.TextStyle(
                                                                  fontSize: 22,
                                                                  fontWeight:
                                                                      pw
                                                                          .FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              pw.SizedBox(
                                                                height: 4,
                                                              ),
                                                              pw.Text(
                                                                'Phone Number: +91 63601 20253',
                                                              ),
                                                              pw.Text(
                                                                'Email: shutterlifephotography10@gmail.com',
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      pw.SizedBox(height: 12),
                                                      pw.Divider(),
                                                      pw.Center(
                                                        child: pw.Text(
                                                          'Tax Invoice',
                                                          style: pw.TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                pw
                                                                    .FontWeight
                                                                    .bold,
                                                            color:
                                                                PdfColors
                                                                    .indigo,
                                                          ),
                                                        ),
                                                      ),
                                                      pw.SizedBox(height: 12),
                                                      pw.Row(
                                                        crossAxisAlignment:
                                                            pw
                                                                .CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          pw.Expanded(
                                                            flex: 2,
                                                            child: pw.Column(
                                                              crossAxisAlignment:
                                                                  pw
                                                                      .CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                pw.Text(
                                                                  'Bill To',
                                                                  style: pw.TextStyle(
                                                                    fontWeight:
                                                                        pw
                                                                            .FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                pw.Text(
                                                                  sale.customerName,
                                                                ),
                                                                pw.Text(
                                                                  'Contact No.: ${sale.phoneNumber}',
                                                                ),
                                                                pw.SizedBox(
                                                                  height: 12,
                                                                ),
                                                                pw.Text(
                                                                  'Terms And Conditions',
                                                                  style: pw.TextStyle(
                                                                    fontWeight:
                                                                        pw
                                                                            .FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                pw.Text(
                                                                  'Thank you for doing business with us.',
                                                                ),
                                                                if (balanceAmount >
                                                                    0) ...[
                                                                  pw.SizedBox(
                                                                    height: 20,
                                                                  ),
                                                                  pw.Center(
                                                                    child: pw.SvgImage(
                                                                      svg:
                                                                          qrImage,
                                                                    ),
                                                                  ),
                                                                  pw.SizedBox(
                                                                    height: 6,
                                                                  ),
                                                                  pw.Center(
                                                                    child: pw.Text(
                                                                      "Scan to Pay UPI",
                                                                      style: pw.TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                        fontWeight:
                                                                            pw.FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                          ),
                                                          pw.SizedBox(
                                                            width: 20,
                                                          ),
                                                          pw.Expanded(
                                                            flex: 2,
                                                            child: pw.Column(
                                                              crossAxisAlignment:
                                                                  pw
                                                                      .CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                pw.Text(
                                                                  'Invoice Details',
                                                                  style: pw.TextStyle(
                                                                    fontWeight:
                                                                        pw
                                                                            .FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                pw.Text(
                                                                  'Invoice No.: #$invoiceNumber',
                                                                ),
                                                                pw.Text(
                                                                  'Date: ${DateFormat('dd-MM-yyyy').format(sale.dateTime)}',
                                                                ),
                                                                pw.SizedBox(
                                                                  height: 8,
                                                                ),
                                                                pw.Table(
                                                                  border: pw
                                                                      .TableBorder.all(
                                                                    color:
                                                                        PdfColors
                                                                            .grey300,
                                                                  ),
                                                                  columnWidths: {
                                                                    0: pw.FlexColumnWidth(
                                                                      3,
                                                                    ),
                                                                    1: pw.FlexColumnWidth(
                                                                      2,
                                                                    ),
                                                                  },
                                                                  children: [
                                                                    pw.TableRow(
                                                                      decoration:
                                                                          pw.BoxDecoration(
                                                                            color:
                                                                                PdfColors.indigo100,
                                                                          ),
                                                                      children: [
                                                                        pw.Padding(
                                                                          padding: pw
                                                                              .EdgeInsets.all(
                                                                            6,
                                                                          ),
                                                                          child: pw.Text(
                                                                            'Total',
                                                                            style: pw.TextStyle(
                                                                              fontWeight:
                                                                                  pw.FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        pw.Padding(
                                                                          padding: pw
                                                                              .EdgeInsets.all(
                                                                            6,
                                                                          ),
                                                                          child: pw.Text(
                                                                            '₹ ${sale.totalAmount.toStringAsFixed(2)}',
                                                                            style: pw.TextStyle(
                                                                              font:
                                                                                  rupeeFont,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    pw.TableRow(
                                                                      children: [
                                                                        pw.Padding(
                                                                          padding: pw
                                                                              .EdgeInsets.all(
                                                                            6,
                                                                          ),
                                                                          child: pw.Text(
                                                                            'Received',
                                                                          ),
                                                                        ),
                                                                        pw.Padding(
                                                                          padding: pw
                                                                              .EdgeInsets.all(
                                                                            6,
                                                                          ),
                                                                          child: pw.Text(
                                                                            '₹ ${sale.amount.toStringAsFixed(2)}',
                                                                            style: pw.TextStyle(
                                                                              font:
                                                                                  rupeeFont,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    pw.TableRow(
                                                                      children: [
                                                                        pw.Padding(
                                                                          padding: pw
                                                                              .EdgeInsets.all(
                                                                            6,
                                                                          ),
                                                                          child: pw.Text(
                                                                            'Balance',
                                                                          ),
                                                                        ),
                                                                        pw.Padding(
                                                                          padding: pw
                                                                              .EdgeInsets.all(
                                                                            6,
                                                                          ),
                                                                          child: pw.Text(
                                                                            '₹ ${balanceAmount.toStringAsFixed(2)}',
                                                                            style: pw.TextStyle(
                                                                              font:
                                                                                  rupeeFont,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    pw.TableRow(
                                                                      children: [
                                                                        pw.Padding(
                                                                          padding: pw
                                                                              .EdgeInsets.all(
                                                                            6,
                                                                          ),
                                                                          child: pw.Text(
                                                                            'Payment Mode',
                                                                          ),
                                                                        ),
                                                                        pw.Padding(
                                                                          padding: pw
                                                                              .EdgeInsets.all(
                                                                            6,
                                                                          ),
                                                                          child: pw.Text(
                                                                            sale.paymentMode,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      pw.SizedBox(height: 16),
                                                      pw.Align(
                                                        alignment:
                                                            pw
                                                                .Alignment
                                                                .centerRight,
                                                        child: pw.Text(
                                                          'For: Shutter Life Photography',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                          ),
                                        );

                                        final output =
                                            await getTemporaryDirectory();
                                        final file = File(
                                          "${output.path}/invoice_$invoiceNumber.pdf",
                                        );
                                        await file.writeAsBytes(
                                          await pdf.save(),
                                        );

                                        Navigator.push(
                                          scaffoldContext,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => PdfPreviewScreen(
                                                  filePath: file.path,
                                                  sale: sale,
                                                ),
                                          ),
                                        );
                                      } else if (value == 'payment_history') {
                                        Navigator.push(
                                          scaffoldContext,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => PaymentHistoryPage(
                                                  sale: sale,
                                                ),
                                          ),
                                        );
                                      } else if (value == 'delivery_tracker') {
                                        Navigator.push(
                                          scaffoldContext,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => DeliveryTrackerPage(
                                                  sale: sale,
                                                ),
                                          ),
                                        );
                                      } else if (value == 'payment_reminder') {
                                        final balanceAmount =
                                            sale.totalAmount - sale.amount;
                                        final phone =
                                            sale.phoneNumber
                                                .replaceAll('+91', '')
                                                .replaceAll(' ', '')
                                                .trim();

                                        if (phone == null ||
                                            phone.isEmpty ||
                                            phone.length < 10) {
                                          ScaffoldMessenger.of(
                                            scaffoldContext,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Phone number not available or invalid",
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        String message;
                                        if (sale.dateTime != null &&
                                            balanceAmount != null &&
                                            invoiceNumber != null) {
                                          message =
                                              "Dear ${sale.customerName},\n\nFriendly reminder from Shutter Life Photography:\n\n"
                                              "📅 Payment Due: ${DateFormat('dd MMM yyyy').format(sale.dateTime)}\n"
                                              "💰 Amount: ₹${balanceAmount.toStringAsFixed(2)}\n"
                                              "📋 Invoice #: $invoiceNumber\n\n"
                                              "Payment Methods:\n"
                                              "• UPI: playroll.vish-1@oksbi\n"
                                              "• Bank Transfer (Details attached)\n"
                                              "• Cash (At our studio)\n\n"
                                              "Please confirm once payment is made. Thank you for your prompt attention!\n\n"
                                              "Warm regards,\nAccounts Team\nShutter Life Photography";
                                        } else {
                                          message =
                                              "Dear ${sale.customerName},\n\nThis is a friendly reminder regarding your payment. "
                                              "Please contact us for invoice details.\n\n"
                                              "Warm regards,\nAccounts Team\nShutter Life Photography";
                                        }

                                        try {
                                          final encodedMessage =
                                              Uri.encodeComponent(message);
                                          final url1 =
                                              "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";
                                          final url2 =
                                              "https://wa.me/91$phone?text=${Uri.encodeComponent(message)}";

                                          canLaunchUrl(Uri.parse(url1)).then((
                                            canLaunch,
                                          ) {
                                            if (canLaunch) {
                                              launchUrl(
                                                Uri.parse(url1),
                                                mode:
                                                    LaunchMode
                                                        .externalApplication,
                                              );
                                            } else {
                                              launchUrl(
                                                Uri.parse(url2),
                                                mode:
                                                    LaunchMode
                                                        .externalApplication,
                                              );
                                            }
                                          });
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Couldn't open WhatsApp",
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    itemBuilder:
                                        (context) => [
                                          PopupMenuItem(
                                            value: 'share_pdf',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.picture_as_pdf,
                                                  color: Colors.blue,
                                                  size: isSmallScreen ? 18 : 24,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Share PDF',
                                                  style: TextStyle(
                                                    fontSize:
                                                        isSmallScreen
                                                            ? 12
                                                            : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'payment_history',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.history,
                                                  color: Colors.green,
                                                  size: isSmallScreen ? 18 : 24,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'View Payment History',
                                                  style: TextStyle(
                                                    fontSize:
                                                        isSmallScreen
                                                            ? 12
                                                            : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delivery_tracker',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delivery_dining_rounded,
                                                  color: Colors.purple,
                                                  size: isSmallScreen ? 18 : 24,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Photo Delivery Tracker',
                                                  style: TextStyle(
                                                    fontSize:
                                                        isSmallScreen
                                                            ? 12
                                                            : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (sale.amount < sale.totalAmount)
                                            PopupMenuItem(
                                              value: 'payment_reminder',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.notifications_active,
                                                    color: Colors.orange,
                                                    size:
                                                        isSmallScreen ? 18 : 24,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Send Payment Reminder',
                                                    style: TextStyle(
                                                      fontSize:
                                                          isSmallScreen
                                                              ? 12
                                                              : null,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                  size: isSmallScreen ? 18 : 24,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    fontSize:
                                                        isSmallScreen
                                                            ? 12
                                                            : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                  ),
                                ] else ...[
                                  // For very small screens, show a more compact menu
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert, size: 18),
                                    onSelected: (value) async {
                                      // Same implementation as above
                                      final scaffoldContext = context;

                                      if (value == 'delete') {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          barrierDismissible: false,
                                          builder:
                                              (ctx) => LayoutBuilder(
                                                builder: (
                                                  context,
                                                  constraints,
                                                ) {
                                                  final bool isSmallScreen =
                                                      constraints.maxWidth <
                                                      600;
                                                  final double iconSize =
                                                      isSmallScreen
                                                          ? 24.0
                                                          : 28.0;
                                                  final double fontSize =
                                                      isSmallScreen
                                                          ? 16.0
                                                          : 18.0;
                                                  final double padding =
                                                      isSmallScreen
                                                          ? 12.0
                                                          : 16.0;
                                                  final double buttonPadding =
                                                      isSmallScreen
                                                          ? 10.0
                                                          : 14.0;

                                                  return AlertDialog(
                                                    insetPadding:
                                                        EdgeInsets.all(padding),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                    titlePadding:
                                                        EdgeInsets.fromLTRB(
                                                          padding,
                                                          padding,
                                                          padding,
                                                          8,
                                                        ),
                                                    contentPadding:
                                                        EdgeInsets.fromLTRB(
                                                          padding,
                                                          8,
                                                          padding,
                                                          padding,
                                                        ),
                                                    title: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.warning,
                                                          color: Colors.red,
                                                          size: iconSize,
                                                        ),
                                                        SizedBox(
                                                          width:
                                                              isSmallScreen
                                                                  ? 8
                                                                  : 12,
                                                        ),
                                                        Text(
                                                          "Confirm Deletion",
                                                          style: TextStyle(
                                                            fontSize: fontSize,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    content: Text(
                                                      'Are you sure you want to delete this sale? This action cannot be undone.',
                                                      style: TextStyle(
                                                        fontSize: fontSize - 2,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    actionsPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: padding,
                                                          vertical: 8,
                                                        ),
                                                    actions: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Flexible(
                                                            child: TextButton(
                                                              style: TextButton.styleFrom(
                                                                padding: EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      buttonPadding,
                                                                  vertical:
                                                                      buttonPadding -
                                                                      4,
                                                                ),
                                                              ),
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.of(
                                                                        ctx,
                                                                      ).pop(
                                                                        false,
                                                                      ),
                                                              child: Text(
                                                                "Cancel",
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .grey[700],
                                                                  fontSize:
                                                                      fontSize -
                                                                      2,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width:
                                                                isSmallScreen
                                                                    ? 8
                                                                    : 16,
                                                          ),
                                                          Flexible(
                                                            child: ElevatedButton.icon(
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors.red,
                                                                foregroundColor:
                                                                    Colors
                                                                        .white,
                                                                padding: EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      buttonPadding,
                                                                  vertical:
                                                                      buttonPadding -
                                                                      4,
                                                                ),
                                                              ),
                                                              icon: Icon(
                                                                Icons
                                                                    .delete_forever,
                                                                size:
                                                                    iconSize -
                                                                    2,
                                                              ),
                                                              label: Text(
                                                                "Delete",
                                                                style: TextStyle(
                                                                  fontSize:
                                                                      fontSize -
                                                                      2,
                                                                ),
                                                              ),
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.of(
                                                                        ctx,
                                                                      ).pop(
                                                                        true,
                                                                      ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                        );

                                        if (confirm == true) {
                                          box.deleteAt(originalIndex);
                                          ScaffoldMessenger.of(
                                            scaffoldContext,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "🗑️ Sale deleted successfully.",
                                              ),
                                              backgroundColor: Colors.red[400],
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } else if (value == 'share_pdf') {
                                        // Calculate balance
                                        final balanceAmount =
                                            (sale.totalAmount - sale.amount)
                                                .clamp(0, double.infinity);

                                        // Get amount from user if balance is > 0
                                        num enteredAmount = balanceAmount;
                                        if (balanceAmount > 0) {
                                          final entered = await showDialog<
                                            double?
                                          >(
                                            context: scaffoldContext,
                                            builder: (context) {
                                              final controller =
                                                  TextEditingController(
                                                    text: balanceAmount
                                                        .toStringAsFixed(2),
                                                  );

                                              return LayoutBuilder(
                                                builder: (
                                                  context,
                                                  constraints,
                                                ) {
                                                  final screenWidth =
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width;
                                                  final maxWidth =
                                                      screenWidth < 400
                                                          ? screenWidth * 0.9
                                                          : 400.0;

                                                  return Dialog(
                                                    insetPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 24,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                    child: ConstrainedBox(
                                                      constraints:
                                                          BoxConstraints(
                                                            maxWidth: maxWidth,
                                                          ),
                                                      child: SingleChildScrollView(
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                bottom: 16,
                                                              ),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              // Header
                                                              Container(
                                                                width:
                                                                    double
                                                                        .infinity,
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      Colors
                                                                          .deepPurple,
                                                                  borderRadius:
                                                                      const BorderRadius.vertical(
                                                                        top: Radius.circular(
                                                                          16,
                                                                        ),
                                                                      ),
                                                                ),
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      vertical:
                                                                          20,
                                                                    ),
                                                                child: Column(
                                                                  children: const [
                                                                    Icon(
                                                                      Icons
                                                                          .qr_code_2_rounded,
                                                                      size: 40,
                                                                      color:
                                                                          Colors
                                                                              .white,
                                                                    ),
                                                                    SizedBox(
                                                                      height: 8,
                                                                    ),
                                                                    Text(
                                                                      'Customize UPI Amount',
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            20,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        color:
                                                                            Colors.white,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),

                                                              // Body
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          20,
                                                                      vertical:
                                                                          20,
                                                                    ),
                                                                child: Column(
                                                                  children: [
                                                                    const Text(
                                                                      "Enter the amount you want to show in the UPI QR. Leave it empty if the customer should enter manually.",
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            Colors.black87,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          16,
                                                                    ),
                                                                    TextField(
                                                                      controller:
                                                                          controller,
                                                                      keyboardType: const TextInputType.numberWithOptions(
                                                                        decimal:
                                                                            true,
                                                                      ),
                                                                      decoration: InputDecoration(
                                                                        labelText:
                                                                            'Amount (₹)',
                                                                        prefixIcon: const Icon(
                                                                          Icons
                                                                              .currency_rupee,
                                                                        ),
                                                                        border: OutlineInputBorder(
                                                                          borderRadius: BorderRadius.circular(
                                                                            10,
                                                                          ),
                                                                        ),
                                                                        filled:
                                                                            true,
                                                                        fillColor:
                                                                            Colors.grey[100],
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          24,
                                                                    ),
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .end,
                                                                      children: [
                                                                        TextButton(
                                                                          child: Text(
                                                                            'Cancel',
                                                                            style: TextStyle(
                                                                              color:
                                                                                  Colors.grey[700],
                                                                            ),
                                                                          ),
                                                                          onPressed:
                                                                              () => Navigator.pop(
                                                                                context,
                                                                                null,
                                                                              ),
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              10,
                                                                        ),
                                                                        ElevatedButton(
                                                                          style: ElevatedButton.styleFrom(
                                                                            backgroundColor:
                                                                                Colors.deepPurple,
                                                                            shape: RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(
                                                                                10,
                                                                              ),
                                                                            ),
                                                                            padding: const EdgeInsets.symmetric(
                                                                              horizontal:
                                                                                  24,
                                                                              vertical:
                                                                                  12,
                                                                            ),
                                                                          ),
                                                                          onPressed: () {
                                                                            final input =
                                                                                controller.text.trim();
                                                                            final parsed = double.tryParse(
                                                                              input,
                                                                            );
                                                                            Navigator.pop(
                                                                              context,
                                                                              (input.isEmpty ||
                                                                                      parsed ==
                                                                                          null ||
                                                                                      parsed <=
                                                                                          0)
                                                                                  ? null
                                                                                  : parsed,
                                                                            );
                                                                          },
                                                                          child: const Text(
                                                                            'Generate QR',
                                                                            style: TextStyle(
                                                                              color:
                                                                                  Colors.white,
                                                                              fontSize:
                                                                                  15,
                                                                              fontWeight:
                                                                                  FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          );

                                          if (entered != null) {
                                            enteredAmount = entered;
                                          }
                                        }

                                        // Create PDF
                                        final pdf = pw.Document();
                                        final rupeeFont = pw.Font.ttf(
                                          await rootBundle.load(
                                            'assets/fonts/Roboto-Regular.ttf',
                                          ),
                                        );

                                        final qrData =
                                            'upi://pay?pa=playroll.vish-1@oksbi&pn=Vishnu&am=${enteredAmount.toStringAsFixed(2)}&cu=INR';

                                        final prefs =
                                            await SharedPreferences.getInstance();

                                        // Get current user email from Hive
                                        final currentUserEmail =
                                            await _getCurrentUserEmailFromHive();

                                        // Use email-specific key for profile image
                                        final profileImagePath = prefs.getString(
                                          '${currentUserEmail}_profileImagePath',
                                        );
                                        pw.MemoryImage? headerImage;

                                        if (profileImagePath != null) {
                                          final profileFile = File(
                                            profileImagePath,
                                          );
                                          if (await profileFile.exists()) {
                                            final imageBytes =
                                                await profileFile.readAsBytes();
                                            headerImage = pw.MemoryImage(
                                              imageBytes,
                                            );
                                          }
                                        }

                                        pdf.addPage(
                                          pw.Page(
                                            build:
                                                (
                                                  pw.Context context,
                                                ) => pw.Container(
                                                  decoration: pw.BoxDecoration(
                                                    border: pw.Border.all(
                                                      color: PdfColors.black,
                                                      width: 2,
                                                    ),
                                                    borderRadius: pw
                                                        .BorderRadius.circular(
                                                      6,
                                                    ),
                                                  ),
                                                  padding: pw.EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: pw.Column(
                                                    crossAxisAlignment:
                                                        pw
                                                            .CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      pw.Row(
                                                        crossAxisAlignment:
                                                            pw
                                                                .CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          if (headerImage !=
                                                              null)
                                                            pw.Container(
                                                              width: 60,
                                                              height: 60,
                                                              child: pw.Image(
                                                                headerImage,
                                                              ),
                                                            ),
                                                          if (headerImage !=
                                                              null)
                                                            pw.SizedBox(
                                                              width: 16,
                                                            ),
                                                          pw.Column(
                                                            crossAxisAlignment:
                                                                pw
                                                                    .CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              pw.Text(
                                                                'Shutter Life Photography',
                                                                style: pw.TextStyle(
                                                                  fontSize: 22,
                                                                  fontWeight:
                                                                      pw
                                                                          .FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              pw.SizedBox(
                                                                height: 4,
                                                              ),
                                                              pw.Text(
                                                                'Phone Number: +91 63601 20253',
                                                              ),
                                                              pw.Text(
                                                                'Email: shutterlifephotography10@gmail.com',
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      pw.SizedBox(height: 12),
                                                      pw.Divider(),
                                                      pw.Center(
                                                        child: pw.Text(
                                                          'Tax Invoice',
                                                          style: pw.TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                pw
                                                                    .FontWeight
                                                                    .bold,
                                                            color:
                                                                PdfColors
                                                                    .indigo,
                                                          ),
                                                        ),
                                                      ),
                                                      pw.SizedBox(height: 12),
                                                      pw.Row(
                                                        crossAxisAlignment:
                                                            pw
                                                                .CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          pw.Expanded(
                                                            flex: 2,
                                                            child: pw.Column(
                                                              crossAxisAlignment:
                                                                  pw
                                                                      .CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                pw.Text(
                                                                  'Bill To',
                                                                  style: pw.TextStyle(
                                                                    fontWeight:
                                                                        pw
                                                                            .FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                pw.Text(
                                                                  sale.customerName,
                                                                ),
                                                                pw.Text(
                                                                  'Contact No.: ${sale.phoneNumber}',
                                                                ),
                                                                pw.SizedBox(
                                                                  height: 12,
                                                                ),
                                                                pw.Text(
                                                                  'Terms And Conditions',
                                                                  style: pw.TextStyle(
                                                                    fontWeight:
                                                                        pw
                                                                            .FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                pw.Text(
                                                                  'Thank you for doing business with us.',
                                                                ),
                                                                if (enteredAmount >
                                                                    0) ...[
                                                                  pw.SizedBox(
                                                                    height: 20,
                                                                  ),
                                                                  pw.Center(
                                                                    child: pw.BarcodeWidget(
                                                                      data:
                                                                          qrData,
                                                                      barcode:
                                                                          pw.Barcode.qrCode(),
                                                                      width:
                                                                          120,
                                                                      height:
                                                                          120,
                                                                    ),
                                                                  ),
                                                                  pw.SizedBox(
                                                                    height: 6,
                                                                  ),
                                                                  pw.Center(
                                                                    child: pw.Text(
                                                                      "Scan to Pay UPI",
                                                                      style: pw.TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                        fontWeight:
                                                                            pw.FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                          ),
                                                          pw.SizedBox(
                                                            width: 20,
                                                          ),
                                                          pw.Expanded(
                                                            flex: 2,
                                                            child: pw.Column(
                                                              crossAxisAlignment:
                                                                  pw
                                                                      .CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                pw.Text(
                                                                  'Invoice Details',
                                                                  style: pw.TextStyle(
                                                                    fontWeight:
                                                                        pw
                                                                            .FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                pw.Text(
                                                                  'Invoice No.: #$invoiceNumber',
                                                                ),
                                                                pw.Text(
                                                                  'Date: ${DateFormat('dd-MM-yyyy').format(sale.dateTime)}',
                                                                ),
                                                                pw.SizedBox(
                                                                  height: 8,
                                                                ),
                                                                pw.Table(
                                                                  border: pw
                                                                      .TableBorder.all(
                                                                    color:
                                                                        PdfColors
                                                                            .grey300,
                                                                  ),
                                                                  columnWidths: {
                                                                    0: pw.FlexColumnWidth(
                                                                      3,
                                                                    ),
                                                                    1: pw.FlexColumnWidth(
                                                                      2,
                                                                    ),
                                                                  },
                                                                  children: [
                                                                    pw.TableRow(
                                                                      decoration:
                                                                          pw.BoxDecoration(
                                                                            color:
                                                                                PdfColors.indigo100,
                                                                          ),
                                                                      children: [
                                                                        pw.Padding(
                                                                          padding: pw
                                                                              .EdgeInsets.all(
                                                                            6,
                                                                          ),
                                                                          child: pw.Text(
                                                                            'Total',
                                                                            style: pw.TextStyle(
                                                                              fontWeight:
                                                                                  pw.FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        pw.Padding(
                                                                          padding: pw
                                                                              .EdgeInsets.all(
                                                                            6,
                                                                          ),
                                                                          child: pw.Text(
                                                                            '₹ ${sale.totalAmount.toStringAsFixed(2)}',
                                                                            style: pw.TextStyle(
                                                                              font:
                                                                                  rupeeFont,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    pw.TableRow(
                                                                      children: [
                                                                        pw.Padding(
                                                                          padding: pw
                                                                              .EdgeInsets.all(
                                                                            6,
                                                                          ),
                                                                          child: pw.Text(
                                                                            'Received',
                                                                          ),
                                                                        ),
                                                                        pw.Padding(
                                                                          padding: pw
                                                                              .EdgeInsets.all(
                                                                            6,
                                                                          ),
                                                                          child: pw.Text(
                                                                            '₹ ${sale.amount.toStringAsFixed(2)}',
                                                                            style: pw.TextStyle(
                                                                              font:
                                                                                  rupeeFont,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    pw.TableRow(
                                                                      children: [
                                                                        pw.Padding(
                                                                          padding: pw
                                                                              .EdgeInsets.all(
                                                                            6,
                                                                          ),
                                                                          child: pw.Text(
                                                                            'Balance',
                                                                          ),
                                                                        ),
                                                                        pw.Padding(
                                                                          padding: pw
                                                                              .EdgeInsets.all(
                                                                            6,
                                                                          ),
                                                                          child: pw.Text(
                                                                            '₹ ${balanceAmount.toStringAsFixed(2)}',
                                                                            style: pw.TextStyle(
                                                                              font:
                                                                                  rupeeFont,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    pw.TableRow(
                                                                      children: [
                                                                        pw.Padding(
                                                                          padding: pw
                                                                              .EdgeInsets.all(
                                                                            6,
                                                                          ),
                                                                          child: pw.Text(
                                                                            'Payment Mode',
                                                                          ),
                                                                        ),
                                                                        pw.Padding(
                                                                          padding: pw
                                                                              .EdgeInsets.all(
                                                                            6,
                                                                          ),
                                                                          child: pw.Text(
                                                                            sale.paymentMode,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      pw.SizedBox(height: 16),
                                                      pw.Align(
                                                        alignment:
                                                            pw
                                                                .Alignment
                                                                .centerRight,
                                                        child: pw.Text(
                                                          'For: Shutter Life Photography',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                          ),
                                        );

                                        final output =
                                            await getTemporaryDirectory();
                                        final file = File(
                                          "${output.path}/invoice_$invoiceNumber.pdf",
                                        );
                                        await file.writeAsBytes(
                                          await pdf.save(),
                                        );

                                        Navigator.push(
                                          scaffoldContext,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => PdfPreviewScreen(
                                                  filePath: file.path,
                                                  sale: sale,
                                                ),
                                          ),
                                        );
                                      } else if (value == 'payment_history') {
                                        Navigator.push(
                                          scaffoldContext,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => PaymentHistoryPage(
                                                  sale: sale,
                                                ),
                                          ),
                                        );
                                      } else if (value == 'delivery_tracker') {
                                        Navigator.push(
                                          scaffoldContext,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => DeliveryTrackerPage(
                                                  sale: sale,
                                                ),
                                          ),
                                        );
                                      } else if (value == 'payment_reminder') {
                                        final balanceAmount =
                                            sale.totalAmount - sale.amount;
                                        final phone =
                                            sale.phoneNumber
                                                .replaceAll('+91', '')
                                                .replaceAll(' ', '')
                                                .trim();

                                        if (phone == null ||
                                            phone.isEmpty ||
                                            phone.length < 10) {
                                          ScaffoldMessenger.of(
                                            scaffoldContext,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Phone number not available or invalid",
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        String message;
                                        if (sale.dateTime != null &&
                                            balanceAmount != null &&
                                            invoiceNumber != null) {
                                          message =
                                              "Dear ${sale.customerName},\n\nFriendly reminder from Shutter Life Photography:\n\n"
                                              "📅 Payment Due: ${DateFormat('dd MMM yyyy').format(sale.dateTime)}\n"
                                              "💰 Amount: ₹${balanceAmount.toStringAsFixed(2)}\n"
                                              "📋 Invoice #: $invoiceNumber\n\n"
                                              "Payment Methods:\n"
                                              "• UPI: playroll.vish-1@oksbi\n"
                                              "• Bank Transfer (Details attached)\n"
                                              "• Cash (At our studio)\n\n"
                                              "Please confirm once payment is made. Thank you for your prompt attention!\n\n"
                                              "Warm regards,\nAccounts Team\nShutter Life Photography";
                                        } else {
                                          message =
                                              "Dear ${sale.customerName},\n\nThis is a friendly reminder regarding your payment. "
                                              "Please contact us for invoice details.\n\n"
                                              "Warm regards,\nAccounts Team\nShutter Life Photography";
                                        }

                                        try {
                                          final encodedMessage =
                                              Uri.encodeComponent(message);
                                          final url1 =
                                              "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";
                                          final url2 =
                                              "https://wa.me/91$phone?text=${Uri.encodeComponent(message)}";

                                          canLaunchUrl(Uri.parse(url1)).then((
                                            canLaunch,
                                          ) {
                                            if (canLaunch) {
                                              launchUrl(
                                                Uri.parse(url1),
                                                mode:
                                                    LaunchMode
                                                        .externalApplication,
                                              );
                                            } else {
                                              launchUrl(
                                                Uri.parse(url2),
                                                mode:
                                                    LaunchMode
                                                        .externalApplication,
                                              );
                                            }
                                          });
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Couldn't open WhatsApp",
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    itemBuilder:
                                        (context) => [
                                          PopupMenuItem(
                                            value: 'share_pdf',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.picture_as_pdf,
                                                  color: Colors.blue,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Share PDF',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'payment_history',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.history,
                                                  color: Colors.green,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Payment History',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delivery_tracker',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delivery_dining_rounded,
                                                  color: Colors.purple,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Delivery Tracker',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (sale.amount < sale.totalAmount)
                                            PopupMenuItem(
                                              value: 'payment_reminder',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.notifications_active,
                                                    color: Colors.orange,
                                                    size: 16,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Payment Reminder',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(children: [buildSalesList()]),
    );
  }
}
