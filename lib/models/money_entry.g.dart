// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'money_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MoneyEntryAdapter extends TypeAdapter<MoneyEntry> {
  @override
  final int typeId = 0;

  @override
  MoneyEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoneyEntry(
      amount: fields[0] as num,
      memo: fields[1] as String,
      type: fields[2] as String,
      date: fields[3] as DateTime,
      createdAt: fields[4] as DateTime?,
      currency: fields[5] as String?,
      decimalDigits: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, MoneyEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.amount)
      ..writeByte(1)
      ..write(obj.memo)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.decimalDigits);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoneyEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
