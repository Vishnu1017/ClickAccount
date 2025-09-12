import 'package:click_account/models/payment.dart';
import 'package:hive/hive.dart';

part 'sale.g.dart';

@HiveType(typeId: 65)
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
  String deliveryStatus;

  @HiveField(8)
  String deliveryLink;

  @HiveField(9)
  String paymentMode;

  @HiveField(10)
  List<Map<String, dynamic>>? deliveryStatusHistory;

  @HiveField(11) // New field for total discount
  double discount;

  Sale({
    required this.customerName,
    required this.amount,
    required this.productName,
    required this.dateTime,
    required this.phoneNumber,
    required this.totalAmount,
    required this.discount,
    List<Payment>? paymentHistory,
    this.deliveryStatus = 'All Non Editing Images',
    this.deliveryLink = '',
    this.paymentMode = 'Cash',
    this.deliveryStatusHistory,
  }) : paymentHistory = paymentHistory ?? [];

  // ✅ Computed getters
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

  void addDeliveryStatus(String status, String notes) {
    deliveryStatusHistory ??= [];
    deliveryStatusHistory!.add({
      'status': status,
      'dateTime': DateTime.now().toIso8601String(),
      'notes': notes,
    });
    deliveryStatus = status;
  }

  // ✅ Override delete() to prevent deletion if discount > 0
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
