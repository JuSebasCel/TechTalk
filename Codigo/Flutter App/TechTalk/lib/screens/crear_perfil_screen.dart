import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/perfil.dart';

class CrearPerfilScreen extends StatefulWidget {
  @override
  _CrearPerfilScreenState createState() => _CrearPerfilScreenState();
}

class _CrearPerfilScreenState extends State<CrearPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  String _nombrePerfil = '';
  late int _numeroPerfil;

  @override
  void initState() {
    super.initState();
    _numeroPerfil = Hive.box<Perfil>('perfilesBox').length + 1;
  }

  Future<void> _guardarPerfil() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final box = Hive.box<Perfil>('perfilesBox');
      final nuevoPerfil = Perfil(nombre: _nombrePerfil);
      await box.add(nuevoPerfil);
      Navigator.pop(context, nuevoPerfil);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: GestureDetector(
            onTap: () {}, // Evita cerrar al tocar dentro
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400, // Puedes ajustar este valor a tu gusto (ej. 280)
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 29, 27, 32),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Crear Perfil $_numeroPerfil',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Nombre del perfil',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa un nombre';
                          }
                          return null;
                        },
                        onSaved: (value) => _nombrePerfil = value!,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _guardarPerfil,
                        icon: Icon(Icons.save),
                        label: Text('Guardar Perfil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 20, 17, 24),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: GoogleFonts.poppins(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
