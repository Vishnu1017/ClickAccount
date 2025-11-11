import 'package:hive/hive.dart';
import 'rental_item.dart'; // make sure RentalBooking is imported

part 'customer_model.g.dart';

@HiveType(typeId: 5)
class CustomerModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String phone;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  List<RentalBooking> rentals; // ✅ list of rental bookings

  CustomerModel({
    required this.name,
    required this.phone,
    required this.createdAt,
    this.rentals = const [],
  });
}
