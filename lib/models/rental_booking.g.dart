// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rental_booking.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RentalBookingAdapter extends TypeAdapter<RentalBooking> {
  @override
  final int typeId = 6;

  @override
  RentalBooking read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RentalBooking(
      itemName: fields[0] as String,
      from: fields[1] as DateTime,
      to: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RentalBooking obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.itemName)
      ..writeByte(1)
      ..write(obj.from)
      ..writeByte(2)
      ..write(obj.to);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RentalBookingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
