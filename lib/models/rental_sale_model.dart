import 'package:hive/hive.dart';

part 'rental_sale_model.g.dart';

@HiveType(typeId: 6)
class RentalSaleModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String customerName;

  @HiveField(2)
  String customerPhone;

  @HiveField(3)
  String itemName;

  @HiveField(4)
  double ratePerDay;

  @HiveField(5)
  int numberOfDays;

  @HiveField(6)
  double totalCost;

  @HiveField(7)
  DateTime fromDateTime;

  @HiveField(8)
  DateTime toDateTime;

  @HiveField(9)
  String? imageUrl;

  @HiveField(10)
  String? pdfFilePath;

  @HiveField(11)
  String paymentMode;

  @HiveField(12)
  double amountPaid;

  @HiveField(13)
  DateTime rentalDateTime;

  RentalSaleModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.itemName,
    required this.ratePerDay,
    required this.numberOfDays,
    required this.totalCost,
    required this.fromDateTime,
    required this.toDateTime,
    this.imageUrl,
    this.pdfFilePath,
    this.paymentMode = 'Cash',
    this.amountPaid = 0,
    DateTime? rentalDateTime,
  }) : rentalDateTime = rentalDateTime ?? DateTime.now();

  /// 🔹 Computed Sale Status: PAID, PARTIAL, DUE
  String get saleStatus {
    if (amountPaid >= totalCost) {
      return 'PAID';
    } else if (amountPaid > 0 && amountPaid < totalCost) {
      return 'PARTIAL';
    } else {
      return 'DUE';
    }
  }

  /// 🔹 Remaining Balance
  double get balanceDue => totalCost - amountPaid;
}
