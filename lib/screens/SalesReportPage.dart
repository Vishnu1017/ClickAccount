import 'package:click_account/models/sale.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DateRangePreset {
  today,
  thisWeek,
  thisMonth,
  thisQuarter,
  thisFinancialYear,
  custom,
}

class SalesReportPage extends StatefulWidget {
  final List<Sale> sales;

  const SalesReportPage({Key? key, required this.sales}) : super(key: key);

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  DateTimeRange? selectedRange;
  DateRangePreset? selectedPreset;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    selectedRange = DateTimeRange(start: start, end: end);
    selectedPreset = DateRangePreset.thisMonth;
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

  void _showPdfOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          margin: EdgeInsets.only(top: 40),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PDF Options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // PDF Options Cards
              _buildPdfOptionCard(
                context,
                icon: Icons.picture_as_pdf,
                iconColor: Colors.red[400],
                title: 'Open PDF',
                subtitle: 'View document immediately',
              ),
              SizedBox(height: 12),
              _buildPdfOptionCard(
                context,
                icon: Icons.print,
                iconColor: Colors.blue[400],
                title: 'Print PDF',
                subtitle: 'Send to printer',
              ),
              SizedBox(height: 12),
              _buildPdfOptionCard(
                context,
                icon: Icons.share,
                iconColor: Colors.green[400],
                title: 'Share PDF',
                subtitle: 'Send via other apps',
              ),
              SizedBox(height: 12),
              _buildPdfOptionCard(
                context,
                icon: Icons.save_alt,
                iconColor: Colors.purple[400],
                title: 'Save to Device',
                subtitle: 'Store in downloads',
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPdfOptionCard(
    BuildContext context, {
    required IconData icon,
    required Color? iconColor,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pop(context);
          // Add your functionality here
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor?.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showXlsOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          margin: EdgeInsets.only(top: 40),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Excel Options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          Colors.green[800], // Green instead of blue for Excel
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Excel Options Cards - Same design as PDF options
              _buildXlsOptionCard(
                context,
                icon: Icons.open_in_new,
                iconColor: Colors.green[600],
                title: 'Open Excel',
                subtitle: 'View spreadsheet immediately',
              ),
              SizedBox(height: 12),
              _buildXlsOptionCard(
                context,
                icon: Icons.share,
                iconColor: Colors.blue[400],
                title: 'Share Excel',
                subtitle: 'Send via other apps',
              ),
              SizedBox(height: 12),
              _buildXlsOptionCard(
                context,
                icon: Icons.download,
                iconColor: Colors.red[400],
                title: 'Export to Excel',
                subtitle: 'Download file',
              ),
              SizedBox(height: 12),
              _buildXlsOptionCard(
                context,
                icon: Icons.schedule,
                iconColor: Colors.purple[400],
                title: 'Schedule Report',
                subtitle: 'Set up automatic exports',
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildXlsOptionCard(
    BuildContext context, {
    required IconData icon,
    required Color? iconColor,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pop(context);
          // Add your Excel functionality here
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor?.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: selectedRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedRange = picked;
        selectedPreset = null;
      });
    }
  }

  String getFormattedRange() {
    if (selectedRange == null) return '';
    final start = DateFormat('dd/MM/yyyy').format(selectedRange!.start);
    final end = DateFormat('dd/MM/yyyy').format(selectedRange!.end);
    return "$start TO $end";
  }

  List<Sale> getFilteredSales() {
    if (selectedRange == null) return widget.sales;
    return widget.sales.where((sale) {
      return sale.dateTime.isAfter(
            selectedRange!.start.subtract(Duration(days: 1)),
          ) &&
          sale.dateTime.isBefore(selectedRange!.end.add(Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(
      locale: 'en_IN',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd MMM, yy');

    final filteredSales = getFilteredSales();
    final customerMap = <String, List<Sale>>{};
    for (final sale in filteredSales) {
      customerMap.putIfAbsent(sale.customerName, () => []).add(sale);
    }

    final totalTxns = filteredSales.length;
    final totalSales = filteredSales.fold(
      0.0,
      (sum, sale) => sum + sale.totalAmount,
    );
    final totalPaid = filteredSales.fold(0.0, (sum, sale) => sum + sale.amount);
    final totalBalance = totalSales - totalPaid;

    return Scaffold(
      appBar: AppBar(
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
        leading: BackButton(color: Colors.white),
        title: Text("Sale Report", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: () => _showPdfOptions(context),
          ),
          Stack(
            children: [
              IconButton(
                icon: CustomXlsIcon(),
                onPressed: () => _showXlsOptions(context),
              ),
              Positioned(
                right: 8,
                top: 10,
                child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _selectDateRange(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.blue[800],
                            ),
                            SizedBox(width: 8),
                            Text(
                              getFormattedRange(),
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Spacer(),
                    PopupMenuButton<DateRangePreset>(
                      icon: Icon(Icons.tune_rounded, color: Colors.blue[800]),
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
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _statTile(
                      value: totalTxns.toString(),
                      label: "Transactions",
                      icon: Icons.receipt_long,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 12),
                    _statTile(
                      value: currencyFormat.format(totalSales),
                      label: "Total Sales",
                      icon: Icons.currency_rupee,
                      color: Colors.indigo,
                    ),
                    SizedBox(width: 12),
                    _statTile(
                      value: currencyFormat.format(totalBalance),
                      label: "Balance",
                      icon: Icons.account_balance_wallet,
                      color:
                          totalBalance > 0 ? Colors.red : Colors.green.shade700,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              children: [
                Text(
                  "CUSTOMER TRANSACTIONS",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Spacer(),
                Text(
                  "${customerMap.length} records",
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: customerMap.length,
              separatorBuilder: (_, __) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final name = customerMap.keys.elementAt(index);
                final transactions = customerMap[name]!;
                final sale = transactions.first;
                final total = transactions.fold(
                  0.0,
                  (sum, s) => sum + s.totalAmount,
                );
                final paid = transactions.fold(0.0, (sum, s) => sum + s.amount);
                final balance = total - paid;
                final paidPercentage = (paid / total * 100).toStringAsFixed(0);

                return Material(
                  borderRadius: BorderRadius.circular(16),
                  elevation: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!, width: 1),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[50],
                            child: Icon(Icons.person, color: Colors.blue[800]),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            "${transactions.length} transactions",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  balance > 0
                                      ? Colors.red[50]
                                      : Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              currencyFormat.format(balance),
                              style: TextStyle(
                                color:
                                    balance > 0
                                        ? Colors.red[800]
                                        : Colors.green[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: LinearProgressIndicator(
                            value: paid / total,
                            backgroundColor: Colors.grey[200],
                            color: balance > 0 ? Colors.orange : Colors.green,
                            minHeight: 6,
                          ),
                        ),
                        SizedBox(height: 4),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "$paidPercentage% Paid",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                dateFormat.format(sale.dateTime),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "TOTAL AMOUNT",
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 10,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      currencyFormat.format(total),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "LAST PAYMENT",
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 10,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      currencyFormat.format(paid),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.green[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomXlsIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'XLS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12, // Slightly larger font
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
