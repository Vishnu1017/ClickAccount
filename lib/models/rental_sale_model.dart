import 'package:hive/hive.dart';

part 'rental_sale_model.g.dart';

@HiveType(typeId: 6)
class RentalSaleModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String customerName;

  @HiveField(2)
  String customerPhone; // Added

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
  String? pdfFilePath; // Added for PDF

  RentalSaleModel({
    required this.id,
    required this.customerName,
    required this.customerPhone, // Added
    required this.itemName,
    required this.ratePerDay,
    required this.numberOfDays,
    required this.totalCost,
    required this.fromDateTime,
    required this.toDateTime,
    this.imageUrl,
    this.pdfFilePath,
  });
}
