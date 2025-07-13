import 'package:click_account/screens/SalesReportPage.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

  @override
  void initState() {
    super.initState();
    fetchSaleOverview();
  }

  void fetchSaleOverview() {
    final box = Hive.box<Sale>('sales');

    final now = DateTime.now();
    final last3Months = List.generate(3, (i) {
      final date = DateTime(now.year, now.month - (2 - i));
      return DateFormat('MMM').format(date);
    });

    final last3MonthKeys = List.generate(3, (i) {
      final date = DateTime(now.year, now.month - (2 - i));
      return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    });

    Map<String, double> monthlyTotals = {
      for (var key in last3MonthKeys) key: 0.0,
    };

    for (var sale in box.values) {
      final saleKey =
          '${sale.dateTime.year}-${sale.dateTime.month.toString().padLeft(2, '0')}';
      if (monthlyTotals.containsKey(saleKey)) {
        monthlyTotals[saleKey] = monthlyTotals[saleKey]! + sale.amount;
      }
    }

    totalSale = monthlyTotals[last3MonthKeys[2]]!;
    final prev = monthlyTotals[last3MonthKeys[1]]!;
    growthPercent =
        prev > 0
            ? ((totalSale - prev) / prev * 100)
            : (totalSale > 0 ? 100 : 0);

    List<double> monthlyValues =
        last3MonthKeys.map((key) => monthlyTotals[key] ?? 0.0).toList();
    maxYValue =
        (monthlyValues.reduce((a, b) => a > b ? a : b) * 1.2)
            .ceilToDouble(); // 20% padding

    setState(() {
      monthLabels = last3Months;
      salesData = List.generate(
        3,
        (i) => FlSpot(i.toDouble(), monthlyTotals[last3MonthKeys[i]]!),
      );
    });
  }

  void _navigateToSalesReport() {
    // Get all sales data for the report
    final box = Hive.box<Sale>('sales');
    final sales = box.values.toList();

    // Sort by date (newest first)
    sales.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SalesReportPage(sales: sales)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(
      locale: 'en_IN',
      decimalDigits: 2,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
              children: [
                Text(
                  "Your Sale Overview (${monthLabels.isNotEmpty ? monthLabels.last : '-'})",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  currencyFormat.format(totalSale),
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_upward, color: Colors.green, size: 18),
                    SizedBox(width: 4),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 14),
                        children: [
                          TextSpan(
                            text: "${growthPercent.toStringAsFixed(0)}% ",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: "More Growth This Month",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: 2,
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
                            colors: [Colors.blueAccent, Color(0xFF1A237E)],
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
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < monthLabels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
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
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),
          FloatingActionButton.extended(
            onPressed: _navigateToSalesReport,
            label: const Text(
              'View Sales Insights', // Action-oriented text
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            icon: const Icon(
              Icons.data_usage, // A unique data-related icon
              color: Colors.white,
              size: 26,
            ),
            backgroundColor:
                Colors.blueAccent.shade400, // A vibrant, eye-catching color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0), // More pill-shaped
            ),
            elevation: 8, // Prominent shadow
            // Optional: Add a hero tag if using multiple FABs
            // heroTag: "salesReportFab",
          ),
        ],
      ),
    );
  }
}
