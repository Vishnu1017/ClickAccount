import 'package:flutter/material.dart';
import 'package:click_account/models/sale.dart';
import 'package:intl/intl.dart';

class PaymentHistoryPage extends StatelessWidget {
  final Sale sale;

  PaymentHistoryPage({required this.sale});

  @override
  Widget build(BuildContext context) {
    final balance = (sale.totalAmount - sale.amount).clamp(0, double.infinity);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: true,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(
              "Payment History",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Color(0xFFF1F6FB),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildAmountRow("Total Amount", sale.totalAmount, Colors.black87),
            buildAmountRow("Received Amount", sale.amount, Colors.green),
            buildAmountRow("Balance Due", balance.toDouble(), Colors.red),
            Divider(height: 30),
            Text(
              "Payments",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child:
                  sale.paymentHistory.isEmpty
                      ? Center(
                        child: Text(
                          "No payments recorded.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        itemCount: sale.paymentHistory.length,
                        itemBuilder: (context, index) {
                          if (index == 0) return SizedBox.shrink();
                          final payment = sale.paymentHistory[index];
                          final difference =
                              sale.paymentHistory[index - 1].amount -
                              payment.amount;

                          return Stack(
                            children: [
                              Positioned(
                                left: 24,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 2,
                                  color: Colors.blue[100],
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 20,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.currency_rupee,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 5,
                                              offset: Offset(2, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "₹ ${difference.toStringAsFixed(2)}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.credit_card,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  payment.mode,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.blueGrey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  DateFormat(
                                                    'dd MMM yyyy, hh:mm a',
                                                  ).format(payment.date),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAmountRow(String title, double value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
          Text(
            "₹ ${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
