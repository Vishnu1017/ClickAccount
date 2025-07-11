// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SaleAdapter extends TypeAdapter<Sale> {
  @override
  final int typeId = 65;

  @override
  Sale read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return Sale(
      customerName: fields[0] as String? ?? '',
      amount: fields[1] as double? ?? 0.0,
      productName: fields[2] as String? ?? '',
      dateTime: fields[3] as DateTime? ?? DateTime.now(),
      phoneNumber: fields[4] as String? ?? '',
      totalAmount: fields[5] as double? ?? 0.0,
      paymentHistory: (fields[6] as List?)?.cast<Payment>() ?? [], // safe cast
      deliveryStatus: fields[7] as String? ?? 'Editing',
      deliveryLink: fields[8] as String? ?? '',
      paymentMode: fields[9] as String? ?? 'Cash',
    );
  }

  @override
  void write(BinaryWriter writer, Sale obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.customerName)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.dateTime)
      ..writeByte(4)
      ..write(obj.phoneNumber)
      ..writeByte(5)
      ..write(obj.totalAmount)
      ..writeByte(6)
      ..write(obj.paymentHistory)
      ..writeByte(7)
      ..write(obj.deliveryStatus)
      ..writeByte(8)
      ..write(obj.deliveryLink)
      ..writeByte(9)
      ..write(obj.paymentMode);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
