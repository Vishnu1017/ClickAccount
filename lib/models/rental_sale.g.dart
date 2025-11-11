// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rental_sale.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RentalSaleAdapter extends TypeAdapter<RentalSale> {
  @override
  final int typeId = 6;

  @override
  RentalSale read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RentalSale(
      customerName: fields[0] as String,
      customerPhone: fields[1] as String,
      itemName: fields[2] as String,
      rentalPrice: fields[3] as double,
      startDate: fields[4] as DateTime,
      endDate: fields[5] as DateTime,
      imageUrl: fields[6] as String,
      pdfFilePath: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RentalSale obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.customerName)
      ..writeByte(1)
      ..write(obj.customerPhone)
      ..writeByte(2)
      ..write(obj.itemName)
      ..writeByte(3)
      ..write(obj.rentalPrice)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.endDate)
      ..writeByte(6)
      ..write(obj.imageUrl)
      ..writeByte(7)
      ..write(obj.pdfFilePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RentalSaleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
