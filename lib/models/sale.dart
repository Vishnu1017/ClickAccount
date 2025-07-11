import 'package:click_account/models/payment.dart';
import 'package:hive/hive.dart';

part 'sale.g.dart';

@HiveType(typeId: 65) // 👈 Ensure this matches your main.dart registration
class Sale extends HiveObject {
  @HiveField(0)
  String customerName;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String productName;

  @HiveField(3)
  DateTime dateTime;

  @HiveField(4)
  String phoneNumber;

  @HiveField(5)
  double totalAmount;

  @HiveField(6)
  List<Payment> paymentHistory;

  @HiveField(7)
  String deliveryStatus; // Editing, Delivered, Printed

  @HiveField(8)
  String deliveryLink;

  @HiveField(9) // 👈 Add this field for payment mode
  String paymentMode;

  Sale({
    required this.customerName,
    required this.amount,
    required this.productName,
    required this.dateTime,
    required this.phoneNumber,
    required this.totalAmount,
    List<Payment>? paymentHistory,
    this.deliveryStatus = 'Editing',
    this.deliveryLink = '',
    this.paymentMode = 'Cash',
  }) : this.paymentHistory = paymentHistory ?? [];
}
