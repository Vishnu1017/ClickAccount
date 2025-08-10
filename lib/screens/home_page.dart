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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String welcomeMessage = "";
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    fetchWelcomeMessage();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _controller.forward();
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
                child: Center(
                  child: Text(
                    welcomeMessage,
                    textAlign:
                        TextAlign.center, // This ensures center alignment
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
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
                                            sale.dateTime != null &&
                                            DateTime.now()
                                                    .difference(sale.dateTime)
                                                    .inDays >
                                                7;

                                        String label = '';
                                        Color badgeColor = Colors.orange[700]!;

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
                                              sale.totalAmount - sale.amount;
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
                                              horizontal: 12,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: badgeColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: badgeColor.withOpacity(
                                                    0.3,
                                                  ),
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              label,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
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
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                final scaffoldContext =
                                    context; // Store context here

                                if (value == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder:
                                        (ctx) => LayoutBuilder(
                                          builder: (context, constraints) {
                                            // Responsive sizing values
                                            final bool isSmallScreen =
                                                constraints.maxWidth < 600;
                                            final double iconSize =
                                                isSmallScreen ? 24.0 : 28.0;
                                            final double fontSize =
                                                isSmallScreen ? 16.0 : 18.0;
                                            final double padding =
                                                isSmallScreen ? 12.0 : 16.0;
                                            final double buttonPadding =
                                                isSmallScreen ? 10.0 : 14.0;

                                            return AlertDialog(
                                              insetPadding: EdgeInsets.all(
                                                padding,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              titlePadding: EdgeInsets.fromLTRB(
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
                                                        isSmallScreen ? 8 : 12,
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
                                                textAlign: TextAlign.center,
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
                                                            () => Navigator.of(
                                                              ctx,
                                                            ).pop(false),
                                                        child: Text(
                                                          "Cancel",
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .grey[700],
                                                            fontSize:
                                                                fontSize - 2,
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
                                                              Colors.white,
                                                          padding: EdgeInsets.symmetric(
                                                            horizontal:
                                                                buttonPadding,
                                                            vertical:
                                                                buttonPadding -
                                                                4,
                                                          ),
                                                        ),
                                                        icon: Icon(
                                                          Icons.delete_forever,
                                                          size: iconSize - 2,
                                                        ),
                                                        label: Text(
                                                          "Delete",
                                                          style: TextStyle(
                                                            fontSize:
                                                                fontSize - 2,
                                                          ),
                                                        ),
                                                        onPressed:
                                                            () => Navigator.of(
                                                              ctx,
                                                            ).pop(true),
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
                                    box.deleteAt(index);
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

                                  // ✅ Load profile image from SharedPreferences
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final profileImagePath = prefs.getString(
                                    'profileImagePath',
                                  );
                                  pw.MemoryImage? headerImage;

                                  if (profileImagePath != null) {
                                    final profileFile = File(profileImagePath);
                                    if (await profileFile.exists()) {
                                      final imageBytes =
                                          await profileFile.readAsBytes();
                                      headerImage = pw.MemoryImage(imageBytes);
                                    }
                                  }

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
                                            child: pw.Column(
                                              crossAxisAlignment:
                                                  pw.CrossAxisAlignment.start,
                                              children: [
                                                // ✅ Show image and company info side-by-side (Vyapar-style)
                                                pw.Row(
                                                  crossAxisAlignment:
                                                      pw
                                                          .CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    if (headerImage != null)
                                                      pw.Container(
                                                        width: 60,
                                                        height: 60,
                                                        child: pw.Image(
                                                          headerImage,
                                                        ),
                                                      ),
                                                    if (headerImage != null)
                                                      pw.SizedBox(width: 16),
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
                                                        pw.SizedBox(height: 4),
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
                                                                  fontSize: 16,
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
                                                                decoration:
                                                                    pw.BoxDecoration(
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
                                                      pw.Alignment.centerRight,
                                                  child: pw.Text(
                                                    'For: Shutter Life Photography',
                                                  ),
                                                ),
                                              ],
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
                                          (_) => PaymentHistoryPage(sale: sale),
                                    ),
                                  );
                                } else if (value == 'delivery_tracker') {
                                  Navigator.push(
                                    scaffoldContext,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              DeliveryTrackerPage(sale: sale),
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
                                    final encodedMessage = Uri.encodeComponent(
                                      message,
                                    );
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
                                          mode: LaunchMode.externalApplication,
                                        );
                                      } else {
                                        launchUrl(
                                          Uri.parse(url2),
                                          mode: LaunchMode.externalApplication,
                                        );
                                      }
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Couldn't open WhatsApp"),
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
                                    if (sale.amount < sale.totalAmount)
                                      PopupMenuItem(
                                        value: 'payment_reminder',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.notifications_active,
                                              color: Colors.orange,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Send Payment Reminder'),
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
