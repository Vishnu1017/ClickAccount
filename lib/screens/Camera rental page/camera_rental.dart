import 'dart:io';
import 'package:bizmate/screens/Camera%20rental%20page/rental_sale_detail_screen.dart'
    show RentalSaleDetailScreen;
import 'package:bizmate/screens/rental_pdf_preview_screen.dart'
    show RentalPdfPreviewScreen;
import 'package:bizmate/widgets/app_snackbar.dart' show AppSnackBar;
import 'package:bizmate/widgets/confirm_delete_dialog.dart'
    show showConfirmDialog;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../../models/rental_sale_model.dart';

class CameraRentalPage extends StatefulWidget {
  final String userName;
  final String userPhone;
  final String userEmail;

  const CameraRentalPage({
    super.key,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
  });

  @override
  State<CameraRentalPage> createState() => _CameraRentalPageState();
}

class _CameraRentalPageState extends State<CameraRentalPage> {
  late Box<RentalSaleModel> salesBox;
  bool _isLoading = true;
  List<RentalSaleModel> rentalSales = [];

  @override
  void initState() {
    super.initState();
    _initHiveListener();
    _loadSales();
  }

  Future<void> _initHiveListener() async {
    if (!Hive.isBoxOpen('rental_sales')) {
      await Hive.openBox<RentalSaleModel>('rental_sales');
    }
    salesBox = Hive.box<RentalSaleModel>('rental_sales');

    // Initial load
    setState(() {
      rentalSales = salesBox.values.toList().reversed.toList();
      _isLoading = false;
    });

    // Listen for any changes in the box (add, update, delete)
    salesBox.listenable().addListener(() {
      setState(() {
        rentalSales = salesBox.values.toList().reversed.toList();
      });
    });
  }

  Future<void> _loadSales() async {
    try {
      if (!Hive.isBoxOpen('rental_sales')) {
        await Hive.openBox<RentalSaleModel>('rental_sales');
      }
      salesBox = Hive.box<RentalSaleModel>('rental_sales');

      setState(() {
        rentalSales = salesBox.values.toList().reversed.toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading sales: $e');
      setState(() => _isLoading = false);
      AppSnackBar.showError(
        context,
        message: 'Error loading sales: $e',
        duration: const Duration(seconds: 2),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} "
        "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _deleteSale(int index) async {
    final sale = rentalSales[index];
    await sale.delete();
    setState(() {
      rentalSales.removeAt(index);
    });
    AppSnackBar.showSuccess(
      context,
      message: '${sale.customerName} deleted successfully',
    );
  }

  Future<void> _confirmDelete(int index) async {
    showConfirmDialog(
      context: context,
      title: "Delete Sale?",
      message: "Are you sure you want to remove this item permanently?",
      onConfirm: () {
        _deleteSale(index);
      },
    );
  }

  Widget _buildImage(RentalSaleModel sale, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child:
          sale.imageUrl != null &&
                  sale.imageUrl!.isNotEmpty &&
                  File(sale.imageUrl!).existsSync()
              ? Image.file(
                File(sale.imageUrl!),
                height: size,
                width: size,
                fit: BoxFit.cover,
              )
              : Container(
                height: size,
                width: size,
                decoration: BoxDecoration(
                  color: Colors.blue.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 40,
                ),
              ),
    );
  }

  String getSaleStatus(RentalSaleModel sale) {
    if (sale.amountPaid >= sale.totalCost) {
      return "PAID";
    } else if (sale.amountPaid > 0) {
      return "PARTIAL";
    } else {
      return "DUE";
    }
  }

  Color getSaleStatusColor(RentalSaleModel sale) {
    switch (getSaleStatus(sale)) {
      case "PAID":
        return Colors.green;
      case "PARTIAL":
        return Colors.orange;
      case "DUE":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTextDetails(RentalSaleModel sale, bool isWide, int index) {
    final balanceDue = sale.totalCost - sale.amountPaid;

    return Column(
      crossAxisAlignment:
          isWide ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                sale.customerName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getSaleStatusColor(sale),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    getSaleStatus(sale),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade300.withOpacity(0.6),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '₹ ${sale.ratePerDay.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDelete(index);
                    } else if (value == 'share_pdf') {
                      _sharePdf(sale);
                    }
                  },
                  itemBuilder:
                      (context) => const [
                        PopupMenuItem(
                          value: 'share_pdf',
                          child: Row(
                            children: [
                              Icon(Icons.picture_as_pdf, color: Colors.blue),
                              SizedBox(width: 10),
                              Text('Share PDF'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                  icon: const Icon(Icons.more_vert, color: Colors.blueGrey),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left column: Item, Rate/day, Days
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                    children: [
                      const TextSpan(
                        text: 'Item: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: sale.itemName,
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                    children: [
                      const TextSpan(
                        text: 'Rate/day: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: '₹ ${sale.ratePerDay.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                    children: [
                      const TextSpan(
                        text: 'Days: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: '${sale.numberOfDays}',
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                    children: [
                      const TextSpan(
                        text: 'Total: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: '₹ ${sale.totalCost.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                    children: [
                      const TextSpan(
                        text: 'Paid: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: '₹ ${sale.amountPaid.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 15),

                    children: [
                      const TextSpan(
                        text: 'Balance: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: '₹ ${balanceDue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "From: ${_formatDateTime(sale.fromDateTime)}",
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            Text(
              "To: ${_formatDateTime(sale.toDateTime)}",
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _sharePdf(RentalSaleModel sale) async {
    try {
      final pdf = pw.Document();
      final ttf = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
      );

      final userName =
          widget.userName.isNotEmpty ? widget.userName : 'Unknown User';
      final customerName =
          (sale.customerName.isNotEmpty) ? sale.customerName : 'N/A';
      final customerPhone =
          (sale.customerPhone.isNotEmpty) ? sale.customerPhone : 'N/A';
      final itemName = (sale.itemName.isNotEmpty) ? sale.itemName : 'N/A';
      final ratePerDay = sale.ratePerDay.toStringAsFixed(2);
      final numberOfDays = sale.numberOfDays.toString();
      final totalCost = sale.totalCost.toStringAsFixed(2);
      final invoiceDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

      pw.Widget? saleImage;
      if (sale.imageUrl != null &&
          sale.imageUrl!.isNotEmpty &&
          File(sale.imageUrl!).existsSync()) {
        try {
          final bytes = File(sale.imageUrl!).readAsBytesSync();
          if (bytes.isNotEmpty) {
            saleImage = pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover);
          }
        } catch (_) {
          saleImage = null;
        }
      }

      final qrData =
          'upi://pay?pa=example@upi&pn=${Uri.encodeComponent(customerName)}&am=$totalCost&cu=INR';

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (saleImage != null)
                      pw.Container(width: 60, height: 60, child: saleImage),
                    if (saleImage != null) pw.SizedBox(width: 16),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          userName,
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Phone: +91 ${widget.userPhone.isNotEmpty ? widget.userPhone : "N/A"}',
                        ),
                        pw.Text(
                          'Email: ${widget.userEmail.isNotEmpty ? widget.userEmail : "N/A"}',
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Divider(),
                pw.Center(
                  child: pw.Text(
                    'Rental Invoice',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo,
                    ),
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Bill To',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(customerName),
                          pw.Text('Phone: +91 $customerPhone'),
                          pw.SizedBox(height: 12),
                          pw.BarcodeWidget(
                            data: qrData,
                            barcode: pw.Barcode.qrCode(),
                            width: 120,
                            height: 120,
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Scan to Pay UPI',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Invoice Details',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text('Invoice No.: #001'),
                          pw.Text('Date: $invoiceDate'),
                          pw.SizedBox(height: 8),
                          pw.Table(
                            border: pw.TableBorder.all(
                              color: PdfColors.grey300,
                            ),
                            columnWidths: {
                              0: pw.FlexColumnWidth(3),
                              1: pw.FlexColumnWidth(2),
                            },
                            children: [
                              _buildTableRow('Item', itemName, ttf),
                              _buildTableRow('Rate/Day', '₹ $ratePerDay', ttf),
                              _buildTableRow('Days', numberOfDays, ttf),
                              _buildTableRow('Total', '₹ $totalCost', ttf),
                              _buildTableRow(
                                'Paid',
                                '₹ ${sale.amountPaid.toStringAsFixed(2)}',
                                ttf,
                              ),
                              _buildTableRow(
                                'Balance',
                                '₹ ${(sale.totalCost - sale.amountPaid).toStringAsFixed(2)}',
                                ttf,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Terms and Conditions:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '1. All rented items must be returned by the agreed date and time.\n'
                  '2. The customer is responsible for any loss, theft, or damage to the rented items.\n'
                  '3. Payment must be completed in full before item delivery.\n'
                  '4. Late returns will incur additional charges as specified in the rental agreement.\n'
                  '5. Items must be returned in the same condition as received, including all accessories and packaging.\n'
                  '6. Any modification, tampering, or misuse of the rented items is strictly prohibited.\n'
                  '7. Cancellation or rescheduling may be subject to a fee as per the rental policy.\n'
                  '8. The rental provider reserves the right to refuse service for misuse or violation of terms.\n'
                  '9. Insurance or damage protection fees, if applicable, must be paid upfront.\n'
                  '10. By renting, the customer agrees to these terms and acknowledges responsibility for compliance.',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 16),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'For: $customerName',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${customerName}_rental.pdf');
      await file.writeAsBytes(await pdf.save());

      sale.pdfFilePath = file.path;
      await sale.save();

      if (file.existsSync()) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => RentalPdfPreviewScreen(
                  filePath: file.path,
                  sale: sale,
                  userName: widget.userName,
                  customerName: widget.userName,
                ),
          ),
        );
      }
    } catch (e) {
      debugPrint('PDF generation error: $e');
      if (mounted) {
        AppSnackBar.showError(
          context,
          message: 'Failed to generate PDF: $e',
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  pw.TableRow _buildTableRow(String title, String value, pw.Font font) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            title,
            style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(value, style: pw.TextStyle(font: font)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : rentalSales.isEmpty
              ? const Center(
                child: Text(
                  "No Rental Sales Found",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: rentalSales.length,
                itemBuilder: (context, index) {
                  final sale = rentalSales[index];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      bool isWide = constraints.maxWidth > 600;
                      double imageSize = isWide ? 120 : 100;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade100,
                              Colors.blue.shade300,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade300.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => RentalSaleDetailScreen(
                                        sale: rentalSales[index],
                                        index: index,
                                      ),
                                ),
                              );
                              setState(() {
                                rentalSales =
                                    salesBox.values.toList().reversed.toList();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child:
                                  isWide
                                      ? Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildImage(sale, imageSize),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: _buildTextDetails(
                                              sale,
                                              isWide,
                                              index,
                                            ),
                                          ),
                                        ],
                                      )
                                      : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _buildImage(sale, imageSize),
                                          const SizedBox(height: 12),
                                          _buildTextDetails(
                                            sale,
                                            isWide,
                                            index,
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
              ),
    );
  }
}
