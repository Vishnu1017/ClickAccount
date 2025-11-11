import 'dart:io';
import 'package:bizmate/widgets/app_snackbar.dart' show AppSnackBar;
import 'package:bizmate/widgets/confirm_delete_dialog.dart'
    show showConfirmDialog;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/rental_sale_model.dart';

class CameraRentalPage extends StatefulWidget {
  const CameraRentalPage({Key? key}) : super(key: key);

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
    _loadSales();
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

  Widget _buildTextDetails(RentalSaleModel sale, bool isWide, int index) {
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
                    '₹${sale.ratePerDay.toStringAsFixed(0)}',
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
                      (context) => [
                        const PopupMenuItem(
                          value: 'share_pdf',
                          child: Text('Share PDF'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                  icon: const Icon(Icons.more_vert, color: Colors.blueGrey),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "Item: ${sale.itemName}",
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        const SizedBox(height: 2),
        Text("Rate/day: ₹${sale.ratePerDay.toStringAsFixed(2)}"),
        Text("Days: ${sale.numberOfDays}"),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "From: ${_formatDateTime(sale.fromDateTime)}",
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            Text(
              "To: ${_formatDateTime(sale.toDateTime)}",
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _sharePdf(RentalSaleModel sale) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build:
              (pw.Context context) => pw.Center(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Customer: ${sale.customerName}'),
                    pw.Text('Phone: ${sale.customerPhone}'),
                    pw.Text('Item: ${sale.itemName}'),
                    pw.Text('Rate/day: ₹${sale.ratePerDay.toStringAsFixed(2)}'),
                    pw.Text('Days: ${sale.numberOfDays}'),
                    pw.Text(
                      'From: ${_formatDateTime(sale.fromDateTime)} To: ${_formatDateTime(sale.toDateTime)}',
                    ),
                  ],
                ),
              ),
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${sale.customerName}_rental.pdf');
      await file.writeAsBytes(await pdf.save());

      // save PDF path in the model
      sale.pdfFilePath = file.path;
      await sale.save();

      await Share.shareFiles([file.path], text: 'Rental Sale PDF');
    } catch (e) {
      AppSnackBar.showError(
        context,
        message: 'Failed to share PDF: $e',
        duration: const Duration(seconds: 2),
      );
    }
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
