// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'perfil.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CombinacionAdapter extends TypeAdapter<Combinacion> {
  @override
  final int typeId = 0;

  @override
  Combinacion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Combinacion(
      dedos: (fields[0] as List).cast<String>(),
      frase: fields[1] as String,
      posicion: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Combinacion obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.dedos)
      ..writeByte(1)
      ..write(obj.frase)
      ..writeByte(2)
      ..write(obj.posicion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CombinacionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PerfilAdapter extends TypeAdapter<Perfil> {
  @override
  final int typeId = 1;

  @override
  Perfil read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Perfil(
      nombre: fields[0] as String,
      combinaciones: (fields[1] as List?)?.cast<Combinacion>(),
    );
  }

  @override
  void write(BinaryWriter writer, Perfil obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.nombre)
      ..writeByte(1)
      ..write(obj.combinaciones);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerfilAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
