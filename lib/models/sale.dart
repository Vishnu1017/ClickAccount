import 'package:bizmate/models/payment.dart';
import 'package:hive/hive.dart';

part 'sale.g.dart';

@HiveType(typeId: 1)
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
  String phoneNumber; // THIS IS YOUR CONTACT NUMBER

  @HiveField(5)
  double totalAmount;

  @HiveField(6)
  List<Payment> paymentHistory;

  @HiveField(7)
  String deliveryStatus;

  @HiveField(8)
  String deliveryLink;

  @HiveField(9)
  String paymentMode;

  @HiveField(10)
  List<Map<String, dynamic>>? deliveryStatusHistory;

  @HiveField(11)
  double discount;

  @HiveField(12)
  String item;

  Sale({
    required this.customerName,
    required this.amount,
    required this.productName,
    required this.dateTime,
    required this.phoneNumber, // FIXED HERE — This IS contactNumber
    required this.totalAmount,
    required this.discount,
    List<Payment>? paymentHistory,
    this.deliveryStatus = 'All Non Editing Images',
    this.deliveryLink = '',
    this.paymentMode = 'Cash',
    this.deliveryStatusHistory,
    required this.item,
  }) : paymentHistory = paymentHistory ?? [];

  // ----------- COMPUTED GETTERS -----------
  double get receivedAmount {
    return paymentHistory.fold(0.0, (sum, p) => sum + p.amount);
  }

  double get balanceAmount {
    return totalAmount - receivedAmount;
  }

  String get formattedDate {
    return "${dateTime.day.toString().padLeft(2, '0')}-"
        "${dateTime.month.toString().padLeft(2, '0')}-"
        "${dateTime.year}";
  }

  // ----------- DELIVERY STATUS UPDATE -----------
  void addDeliveryStatus(String status, String notes) {
    deliveryStatusHistory ??= [];
    deliveryStatusHistory!.add({
      'status': status,
      'dateTime': DateTime.now().toIso8601String(),
      'notes': notes,
    });
    deliveryStatus = status;
  }

  // ----------- DELETE VALIDATION -----------
  @override
  Future<void> delete() {
    if (discount > 0) {
      throw Exception(
        "Deleting this sale is not allowed because it has a discount.",
      );
    }
    return super.delete();
  }
}
