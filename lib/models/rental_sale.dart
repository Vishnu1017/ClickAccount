import 'package:hive/hive.dart';

part 'rental_sale.g.dart';

@HiveType(typeId: 6)
class RentalSale extends HiveObject {
  @HiveField(0)
  String customerName;

  @HiveField(1)
  String customerPhone;

  @HiveField(2)
  String itemName;

  @HiveField(3)
  double rentalPrice;

  @HiveField(4)
  DateTime startDate;

  @HiveField(5)
  DateTime endDate;

  @HiveField(6)
  String imageUrl;

  @HiveField(7) // new field for PDF file
  String? pdfFilePath;

  RentalSale({
    required this.customerName,
    required this.customerPhone,
    required this.itemName,
    required this.rentalPrice,
    required this.startDate,
    required this.endDate,
    required this.imageUrl,
    this.pdfFilePath,
  });
}
