import 'package:click_account/screens/SalesReportPage.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../models/sale.dart';

class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double totalSale = 0.0;
  double growthPercent = 0.0;
  List<FlSpot> salesData = [];
  List<String> monthLabels = [];
  double maxYValue = 0;
  String _selectedRange = '3m';
  final ScrollController _scrollController = ScrollController();

  double previousMonthsTotal = 0.0; // Total of previous months in range
  double previousMonthsAvg = 0.0; // Average of previous months
  int previousMonthsCount = 0; // Count of previous months

  @override
  void initState() {
    super.initState();
    fetchSaleOverview('3m');
  }

  int getMonthRange(String range) {
    switch (range) {
      case '3m':
        return 3;
      case '6m':
        return 6;
      case '9m':
        return 9;
      case '1y':
        return 12;
      case '5y':
        return 60;
      case 'max':
        return 120;
      default:
        return 3;
    }
  }

  void fetchSaleOverview(String range) {
    final box = Hive.box<Sale>('sales');
    final now = DateTime.now();
    final rangeInMonths = getMonthRange(range);

    // Generate month labels and keys for all months in range
    final months = List.generate(rangeInMonths, (i) {
      final date = DateTime(now.year, now.month - (rangeInMonths - 1 - i));
      return DateFormat('MMM').format(date);
    });

    final keys = List.generate(rangeInMonths, (i) {
      final date = DateTime(now.year, now.month - (rangeInMonths - 1 - i));
      return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    });

    // Initialize monthly totals
    Map<String, double> monthlyTotals = {for (var key in keys) key: 0.0};

    // Calculate totals for each month
    for (var sale in box.values) {
      final saleKey =
          '${sale.dateTime.year}-${sale.dateTime.month.toString().padLeft(2, '0')}';
      if (monthlyTotals.containsKey(saleKey)) {
        monthlyTotals[saleKey] = monthlyTotals[saleKey]! + sale.amount;
      }
    }

    // Get monthly values in order
    List<double> monthlyValues =
        keys.map((key) => monthlyTotals[key] ?? 0.0).toList();

    // Current month is always the last in the list
    final currentMonthTotal =
        monthlyValues.isNotEmpty ? monthlyValues.last : 0.0;

    // Previous months are all except the current month
    final previousMonths =
        monthlyValues.length > 1
            ? monthlyValues.sublist(0, monthlyValues.length - 1)
            : [];

    // Calculate previous months data
    previousMonthsTotal = previousMonths.fold(0.0, (a, b) => a + b);
    previousMonthsAvg =
        previousMonths.isNotEmpty
            ? previousMonthsTotal / previousMonths.length
            : 0.0;
    previousMonthsCount = previousMonths.length;

    // Calculate growth percentage
    growthPercent =
        previousMonthsAvg > 0
            ? ((currentMonthTotal - previousMonthsAvg) / previousMonthsAvg) *
                100
            : (currentMonthTotal > 0 ? 100 : 0);

    totalSale = currentMonthTotal;
    maxYValue =
        (monthlyValues.reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble();

    setState(() {
      monthLabels = months;
      salesData = List.generate(
        keys.length,
        (i) => FlSpot(i.toDouble(), monthlyTotals[keys[i]]!),
      );
      _selectedRange = range; // Make sure to update the selected range
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && salesData.length > 5) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _navigateToSalesReport() {
    final box = Hive.box<Sale>('sales');
    final sales = box.values.toList();
    sales.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SalesReportPage(sales: sales)),
    );
  }

  void _onRangeSelected(String value) {
    setState(() {
      _selectedRange = value;
    });
    fetchSaleOverview(value);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(
      locale: 'en_IN',
      decimalDigits: 2,
    );

    final isProfit = growthPercent >= 0;
    final difference = (totalSale - previousMonthsAvg).abs();
    final currentMonthName = DateFormat('MMMM').format(DateTime.now());

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, right: 10),
                        child: Text(
                          "Your Sale Overview (${monthLabels.isNotEmpty ? _selectedRange : '-'})",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton<String>(
                        onSelected: _onRangeSelected,
                        icon: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            FontAwesomeIcons.ellipsisV,
                            size: 15,
                            color: Colors.blueAccent,
                          ),
                        ),
                        offset: Offset(0, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.blue.shade100,
                            width: 1,
                          ),
                        ),
                        elevation: 8,
                        itemBuilder:
                            (context) => [
                              _buildMenuItem(
                                '3m',
                                Icons.timelapse,
                                Colors.blue,
                              ),
                              _buildMenuItem(
                                '6m',
                                Icons.hourglass_top,
                                Colors.green,
                              ),
                              _buildMenuItem(
                                '9m',
                                Icons.hourglass_full,
                                Colors.orange,
                              ),
                              _buildMenuItem(
                                '1y',
                                Icons.calendar_today,
                                Colors.purple,
                              ),
                              _buildMenuItem('5y', Icons.event, Colors.red),
                              _buildMenuItem(
                                'max',
                                Icons.all_inclusive,
                                Colors.teal,
                              ),
                            ],
                        child: null,
                      ),
                    ),
                  ],
                ),
                Center(
                  child: Text(
                    currencyFormat.format(totalSale),
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isProfit ? Icons.trending_up : Icons.trending_down,
                          color: isProfit ? Colors.green : Colors.red,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 14),
                            children: [
                              TextSpan(
                                text: "${growthPercent.toStringAsFixed(2)}% ",
                                style: TextStyle(
                                  fontSize: 15,
                                  color:
                                      isProfit
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: isProfit ? "Increase" : "Decrease",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      "In $currentMonthName compared to previous ${previousMonthsCount > 1 ? '$previousMonthsCount months' : 'month'} average",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "${isProfit ? 'Profit' : 'Loss'}: ₹${difference.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 14,
                        color: isProfit ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final chartWidth =
                          salesData.length > 5
                              ? salesData.length * 60.0 + 40
                              : constraints.maxWidth;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _scrollController,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Container(
                            width: chartWidth,
                            child: LineChart(
                              LineChartData(
                                minX: 0,
                                maxX: salesData.length.toDouble() - 1,
                                minY: 0,
                                maxY: maxYValue,
                                lineTouchData: LineTouchData(
                                  enabled: true,
                                  touchTooltipData: LineTouchTooltipData(
                                    tooltipPadding: EdgeInsets.all(8),
                                    tooltipMargin: 12,
                                    getTooltipItems: (touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        return LineTooltipItem(
                                          '₹${spot.y.toStringAsFixed(2)}',
                                          TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }).toList();
                                    },
                                  ),
                                  handleBuiltInTouches: true,
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: salesData,
                                    isCurved: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blueAccent,
                                        Color(0xFF1A237E),
                                      ],
                                    ),
                                    barWidth: 3,
                                    dotData: FlDotData(show: true),
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                ],
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1.0,
                                      reservedSize: 28,
                                      getTitlesWidget: (value, meta) {
                                        int index = value.toInt();
                                        if (index >= 0 &&
                                            index < monthLabels.length) {
                                          return Padding(
                                            padding: EdgeInsets.only(top: 8),
                                            child: Text(
                                              monthLabels[index],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                gridData: FlGridData(show: false),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ),
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
          SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 75),
            child: FloatingActionButton.extended(
              onPressed: _navigateToSalesReport,
              label: const Text(
                'View Sales Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              icon: const Icon(Icons.data_usage, color: Colors.white, size: 26),
              backgroundColor: Colors.blueAccent.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              elevation: 8,
            ),
          ),
          SizedBox(height: 65),
        ],
      ),
    );
  }

  // Helper method to create styled menu items
  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(6),
            child: Icon(icon, size: 16, color: color),
          ),
          SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
