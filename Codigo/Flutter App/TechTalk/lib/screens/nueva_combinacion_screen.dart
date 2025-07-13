import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/perfil.dart';

class NuevaCombinacionScreen extends StatefulWidget {
  final List<Combinacion> existentes;

  const NuevaCombinacionScreen({super.key, required this.existentes});

  @override
  State<NuevaCombinacionScreen> createState() => _NuevaCombinacionScreenState();
}

class _NuevaCombinacionScreenState extends State<NuevaCombinacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _dedosSeleccionados = [];
  String _frase = '';
  final List<String> _opciones = ["S", "N", "I"];
  String? _opcionSeleccionada;

  bool _esDuplicado(List<String> nuevosDedos, String nuevaPosicion) {
    for (var comb in widget.existentes) {
      final existentesSet = comb.dedos.toSet();
      final nuevosSet = nuevosDedos.toSet();
      if (comb.posicion == nuevaPosicion &&
          existentesSet.length == nuevosSet.length &&
          existentesSet.containsAll(nuevosSet)) {
        return true;
      }
    }
    return false;
  }

  void _guardarCombinacion() {
    if (_dedosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un dedo')),
      );
      return;
    }

    if (_opcionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una posición (S, N o I)')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_esDuplicado(_dedosSeleccionados, _opcionSeleccionada!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esa combinación ya existe')),
      );
      return;
    }

    _formKey.currentState!.save();

    final nuevaCombinacion = Combinacion(
      dedos: List.from(_dedosSeleccionados),
      frase: _frase,
      posicion: _opcionSeleccionada!,
    );
    Navigator.pop(context, nuevaCombinacion);
  }

  Widget dedoButton(String nombreDedo) {
    final isSelected = _dedosSeleccionados.contains(nombreDedo);
    final Color darkBackground = const Color(0xFF15101C);
    final Color activePurple = const Color.fromARGB(255, 172, 162, 202);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _dedosSeleccionados.remove(nombreDedo);
          } else {
            _dedosSeleccionados.add(nombreDedo);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        height: 48,
        width: isSelected ? 160 : 110,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? activePurple : darkBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: activePurple, width: 1.8),
        ),
        child: Center(
          child: Text(
            nombreDedo,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? darkBackground : activePurple,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF15101C);
    const Color purple = Color(0xFFB18CFF);
    const Color inputFill = Color(0xFF1E1B26);
    const Color textGrey = Color(0xFFCCCCCC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text(
          'Nueva Combinación',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Simulación del guante (el pulgar es fijo)',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textGrey,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  dedoButton('Meñique'),
                  dedoButton('Anular'),
                  dedoButton('Medio'),
                  dedoButton('Índice'),
                  _buildDropdownDedo(),
                ],
              ),
              const SizedBox(height: 30),
              TextFormField(
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Frase asociada',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  filled: true,
                  fillColor: inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: purple),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey[700]!,
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Por favor ingresa una frase'
                    : null,
                onSaved: (value) => _frase = value!,
              ),

              // VALIDADOR INVISIBLE para posición
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    'Guardar combinación',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: _guardarCombinacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 29, 27, 31),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: const Color.fromARGB(255, 29, 27, 31),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownDedo() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      height: 48,
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF15101C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color.fromARGB(255, 172, 162, 202),
          width: 1.8,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _opcionSeleccionada,
          dropdownColor: const Color(0xFF1F1B2E),
          iconEnabledColor: const Color.fromARGB(255, 172, 162, 202),
          isExpanded: true,
          hint: Text(
            'Pos',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color.fromARGB(255, 172, 162, 202),
            ),
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          items: _opciones.map((String val) {
            return DropdownMenuItem<String>(value: val, child: Text(val));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _opcionSeleccionada = value;
            });
          },
        ),
      ),
    );
  }
}
