// ignore_for_file: unused_local_variable, unnecessary_null_comparison

import 'package:bizmate/models/sale.dart';
import 'package:bizmate/models/user_model.dart';
import 'package:bizmate/screens/WhatsAppHelper.dart';
import 'package:bizmate/screens/sale_detail_screen.dart';
import 'package:bizmate/widgets/sale_options_menu.dart' show SaleOptionsMenu;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

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
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;
  DateTimeRange? selectedRange;
  DateRangePreset? selectedPreset;
  String _currentUserName = '';
  String _currentUserEmail = '';
  String _currentUserPhone = '';
  // String _currentUserUpiId = '';

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

  Future<void> _loadCurrentUserData() async {
    final currentUser = await _getCurrentUserName();
    setState(() {
      _currentUserName = currentUser?.name ?? '';
      _currentUserEmail = currentUser?.email ?? '';
      _currentUserPhone = currentUser?.phone ?? '';
      // _currentUserUpiId = currentUser?.upiId ?? '';
    });
  }

  // Add this method to your _HomePageState class
  Future<User?> _getCurrentUserName() async {
    try {
      final usersBox = await Hive.openBox<User>('users');
      final sessionBox = await Hive.openBox('session');
      final currentUserEmail = sessionBox.get('currentUserEmail');

      if (currentUserEmail != null) {
        return usersBox.values.firstWhere(
          (user) => user.email == currentUserEmail,
          orElse: () => usersBox.values.first,
        );
      } else {
        // If no session, get the first user
        if (usersBox.isNotEmpty) {
          return usersBox.values.first;
        }
      }
      return null; // Return null if no user found
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
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
    _getCurrentUserName();
    _loadCurrentUserData();

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
                                        '+91 ${sale.phoneNumber}',
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
                                              final signature =
                                                  _currentUserName.isNotEmpty
                                                      ? ' - $_currentUserName'
                                                      : '';
                                              final msg =
                                                  "Hello ${sale.customerName}, your payment of ₹${due.toStringAsFixed(2)} is overdue for more than 7 days. Please make the payment at the earliest. - $signature";
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
                                  // In your HomePage, replace the entire PopupMenuButton section with:
                                  SaleOptionsMenu(
                                    sale: sale,
                                    originalIndex: originalIndex,
                                    box: box,
                                    isSmallScreen: isSmallScreen,
                                    invoiceNumber: invoiceNumber.toString(),
                                    currentUserName: _currentUserName,
                                    currentUserPhone: _currentUserPhone,
                                    currentUserEmail: _currentUserEmail,
                                    parentContext: context,
                                  ),
                                ] else ...[
                                  // For very small screens
                                  SaleOptionsMenu(
                                    sale: sale,
                                    originalIndex: originalIndex,
                                    box: box,
                                    isSmallScreen: true,
                                    invoiceNumber: invoiceNumber.toString(),
                                    currentUserName: _currentUserName,
                                    currentUserPhone: _currentUserPhone,
                                    currentUserEmail: _currentUserEmail,
                                    parentContext: context,
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
