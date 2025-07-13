import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreditsScreen extends StatelessWidget {
  final List<_Integrante> listaIntegrantes = [
    _Integrante('Laura Ropero', 'Documentación', Icons.description),
    _Integrante('Danna Bernal', 'Documentación', Icons.description),
    _Integrante('Sebastian Caicedo', 'Diseño físico y circuitaje',
        Icons.design_services),
    _Integrante(
        'Santiago Castellanos', 'Diseño físico y circuitaje', Icons.memory),
    _Integrante('Nicolas Prieto', 'Programación', Icons.code),
    _Integrante('Sebastian Celis', 'Programación', Icons.code),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Créditos',
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            SizedBox(height: 10),
            Text(
              'Universidad Nacional de Colombia',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Facultad de Ingeniería',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white54,
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Equipo de desarrollo',
              style: GoogleFonts.poppins(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: listaIntegrantes.length,
                separatorBuilder: (_, __) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final miembro = listaIntegrantes[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueGrey.shade800,
                        child: Icon(
                          miembro.icono,
                          color: Colors.lightBlueAccent,
                        ),
                      ),
                      title: Text(
                        miembro.nombre,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        miembro.rol,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Integrante {
  final String nombre;
  final String rol;
  final IconData icono;

  _Integrante(this.nombre, this.rol, this.icono);
}
