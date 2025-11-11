import 'package:hive/hive.dart';

part 'rental_booking.g.dart';

@HiveType(typeId: 6)
class RentalBooking extends HiveObject {
  @HiveField(0)
  String itemName;

  @HiveField(1)
  DateTime from;

  @HiveField(2)
  DateTime to;

  RentalBooking({required this.itemName, required this.from, required this.to});
}
