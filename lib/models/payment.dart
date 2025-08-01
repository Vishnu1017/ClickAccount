import 'package:hive/hive.dart';

part 'payment.g.dart';

@HiveType(typeId: 34) // Use a unique typeId
class Payment {
  @HiveField(0)
  double amount;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String mode;

  Payment({required this.amount, required this.date, required this.mode});
}
