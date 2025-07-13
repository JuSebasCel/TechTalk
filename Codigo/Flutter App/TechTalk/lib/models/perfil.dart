// lib/models/perfil.dart

import 'package:hive/hive.dart';

part 'perfil.g.dart'; // Archivo generado

@HiveType(typeId: 0)
class Combinacion {
  @HiveField(0)
  final List<String> dedos;

  @HiveField(1)
  final String frase;

  @HiveField(2)
  final String posicion; // Nueva propiedad agregada

  Combinacion({
    required this.dedos,
    required this.frase,
    required this.posicion,
  });
}

@HiveType(typeId: 1)
class Perfil {
  @HiveField(0)
  final String nombre;

  @HiveField(1)
  final List<Combinacion> combinaciones;

  Perfil({required this.nombre, List<Combinacion>? combinaciones})
    : this.combinaciones = combinaciones ?? [];
}
