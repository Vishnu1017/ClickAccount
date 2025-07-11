// ignore_for_file: unused_local_variable, unused_field

import 'package:click_account/models/sale.dart';
import 'package:click_account/screens/DeliveryTrackerPage.dart';
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

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String welcomeMessage = "";
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    fetchWelcomeMessage();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  void fetchWelcomeMessage() {
    setState(() {
      welcomeMessage = "🏠 Welcome back, Vishnu!";
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildSalesList() {
    final saleBox = Hive.box<Sale>('sales');
    return ValueListenableBuilder(
      valueListenable: saleBox.listenable(),
      builder: (context, Box<Sale> box, _) {
        return Column(
          children: [
            if (box.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Text(
                  welcomeMessage,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            if (box.isNotEmpty) SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 90),
                itemCount: box.length,
                itemBuilder: (context, index) {
                  final sale = box.getAt(index);
                  if (sale == null) return SizedBox.shrink();

                  final invoiceNumber = index + 1;
                  final formattedDate = DateFormat(
                    'dd MMM yyyy',
                  ).format(sale.dateTime);
                  final formattedTime = DateFormat(
                    'hh:mm a',
                  ).format(sale.dateTime);

                  double balanceAmount = (sale.totalAmount - sale.amount).clamp(
                    0,
                    double.infinity,
                  );

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                                (_) =>
                                    SaleDetailScreen(sale: sale, index: index),
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 👤 Avatar + Invoice + Date
                            Column(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Color(0xFF1A237E),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Invoice #$invoiceNumber",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.indigo,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMM').format(sale.dateTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  DateFormat('hh:mm a').format(sale.dateTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 16),

                            // 📋 Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sale.customerName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    sale.productName,
                                    style: TextStyle(
                                      fontSize: 14,
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
                                        ),
                                      ),
                                      Text(
                                        "₹${sale.totalAmount.toStringAsFixed(2)}",
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
                                        ),
                                      ),
                                      Text(
                                        "₹${sale.amount.toStringAsFixed(2)}",
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
                                        ),
                                      ),
                                      Text(
                                        "₹${(sale.totalAmount - sale.amount).clamp(0, double.infinity).toStringAsFixed(2)}",
                                        style: TextStyle(
                                          color: Colors.red[700],
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
                                        final bool isUnpaid = sale.amount == 0;
                                        final bool isDueOver7Days =
                                            isUnpaid &&
                                            // ignore: unnecessary_null_comparison
                                            sale.dateTime != null &&
                                            DateTime.now()
                                                    .difference(sale.dateTime)
                                                    .inDays >
                                                7;
                                        String label = '';
                                        Color badgeColor =
                                            Colors
                                                .orange[700]!; // Default to DUE

                                        if (isFullyPaid) {
                                          label = "SALE : PAID";
                                          badgeColor = Colors.green[600]!;
                                        } else if (isPartiallyPaid) {
                                          label = "SALE : PARTIAL";
                                          badgeColor = Colors.lightBlue;
                                        } else if (isDueOver7Days) {
                                          label = "SALE : DUE";
                                          badgeColor = Colors.orange[700]!;
                                        } else {
                                          label = "SALE : PARTIAL";
                                          badgeColor = Colors.lightBlue;
                                        }

                                        return Container(
                                          margin: EdgeInsets.only(top: 6),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: badgeColor,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // ☰ Delete option
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: Center(
                                            child: Text('Delete Sale?'),
                                          ),
                                          content: Text(
                                            'Are you sure you want to delete this sale? This action cannot be undone.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(false),
                                              child: Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              child: Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                  );

                                  if (confirm == true) {
                                    box.deleteAt(index);
                                    ScaffoldMessenger.of(context).showSnackBar(
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

                                  final balanceAmount = (sale.totalAmount -
                                          sale.amount)
                                      .clamp(0, double.infinity);

                                  final rupeeFont = pw.Font.ttf(
                                    await rootBundle.load(
                                      'assets/fonts/Roboto-Regular.ttf',
                                    ),
                                  );

                                  final qrData =
                                      'upi://pay?pa=playroll.vish-1@oksbi&pn=Vishnu&am=${balanceAmount.toStringAsFixed(2)}&cu=INR';

                                  final qrImage = pw.Barcode.qrCode().toSvg(
                                    qrData,
                                    width: 120,
                                    height: 120,
                                  );

                                  pdf.addPage(
                                    pw.Page(
                                      build:
                                          (pw.Context context) => pw.Container(
                                            decoration: pw.BoxDecoration(
                                              border: pw.Border.all(
                                                color: PdfColors.black,
                                                width: 2,
                                              ),
                                              borderRadius: pw
                                                  .BorderRadius.circular(6),
                                            ),
                                            padding: pw.EdgeInsets.all(16),
                                            child: pw.Container(
                                              padding: pw.EdgeInsets.all(16),
                                              child: pw.Column(
                                                crossAxisAlignment:
                                                    pw.CrossAxisAlignment.start,
                                                children: [
                                                  pw.Text(
                                                    'Shutter Life Photography',
                                                    style: pw.TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          pw.FontWeight.bold,
                                                    ),
                                                  ),
                                                  pw.SizedBox(height: 4),
                                                  pw.Text(
                                                    'Phone Number: +916360120253',
                                                  ),
                                                  pw.Text(
                                                    'Email: shutterlifephotography10@gmail.com',
                                                  ),
                                                  pw.Divider(),
                                                  pw.Center(
                                                    child: pw.Text(
                                                      'Tax Invoice',
                                                      style: pw.TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            pw.FontWeight.bold,
                                                        color: PdfColors.indigo,
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
                                                              '${sale.customerName}',
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
                                                                child:
                                                                    pw.SvgImage(
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
                                                                        pw
                                                                            .FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ),
                                                      pw.SizedBox(width: 20),
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
                                                                  decoration: pw.BoxDecoration(
                                                                    color:
                                                                        PdfColors
                                                                            .indigo100,
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
                                    ),
                                  );

                                  final output = await getTemporaryDirectory();
                                  final file = File(
                                    "${output.path}/invoice_$invoiceNumber.pdf",
                                  );
                                  await file.writeAsBytes(await pdf.save());

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => PdfPreviewScreen(
                                            filePath: file.path,
                                          ),
                                    ),
                                  );
                                } else if (value == 'payment_history') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => PaymentHistoryPage(sale: sale),
                                    ),
                                  );
                                } else if (value == 'delivery_tracker') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => DeliveryTrackerPage(
                                            sale: sale,
                                          ), // ⬅️ pass current sale
                                    ),
                                  );
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
                                          ),
                                          SizedBox(width: 8),
                                          Text('Share PDF'),
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
                                          ),
                                          SizedBox(width: 8),
                                          Text('View Payment History'),
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
                                          ),
                                          SizedBox(width: 8),
                                          Text('Photo Delivery Tracker'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                            ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(children: [buildSalesList()]),
    );
  }
}
