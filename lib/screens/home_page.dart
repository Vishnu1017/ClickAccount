// ignore_for_file: unused_local_variable, unnecessary_null_comparison

import 'package:bizmate/models/sale.dart';
import 'package:bizmate/models/user_model.dart';
import 'package:bizmate/screens/WhatsAppHelper.dart';
import 'package:bizmate/screens/sale_detail_screen.dart';
import 'package:bizmate/widgets/advanced_search_bar.dart'
    show AdvancedSearchBar;
import 'package:bizmate/widgets/sale_options_menu.dart' show SaleOptionsMenu;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

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
  DateTimeRange? selectedRange;
  String _currentUserName = '';
  String _currentUserEmail = '';
  String _currentUserPhone = '';
  // String _currentUserUpiId = '';

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _handleDateRangeChanged(DateTimeRange? range) {
    setState(() {
      selectedRange = range;
    });
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
                AdvancedSearchBar(
                  hintText:
                      isVerySmallScreen
                          ? 'Search...'
                          : isSmallScreen
                          ? 'Search sales...'
                          : 'Search by customer, product, phone, amount...',
                  onSearchChanged: _handleSearchChanged,
                  onDateRangeChanged: _handleDateRangeChanged,
                  showDateFilter: true,
                ),

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
                                                      // ignore: deprecated_member_use
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
