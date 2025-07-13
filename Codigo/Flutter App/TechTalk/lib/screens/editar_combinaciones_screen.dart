import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/perfil.dart';
import 'nueva_combinacion_screen.dart';

class EditarCombinacionesScreen extends StatefulWidget {
  final Perfil perfil;
  final int hiveIndex;

  const EditarCombinacionesScreen({
    Key? key,
    required this.perfil,
    required this.hiveIndex,
  }) : super(key: key);

  @override
  _EditarCombinacionesScreenState createState() =>
      _EditarCombinacionesScreenState();
}

class _EditarCombinacionesScreenState extends State<EditarCombinacionesScreen> {
  late Box<Perfil> _box;
  String textoGuante = "Esperando combinación...";
  final Set<int> _indicesSeleccionados = {};

  @override
  void initState() {
    super.initState();
    _box = Hive.box<Perfil>('perfilesBox');
  }

  Future<void> _anadirCombinacion() async {
    final nueva = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NuevaCombinacionScreen(existentes: widget.perfil.combinaciones),
      ),
    );
    if (nueva != null && nueva is Combinacion) {
      setState(() {
        widget.perfil.combinaciones.add(nueva);
        textoGuante = nueva.frase;
      });
      await _box.putAt(widget.hiveIndex, widget.perfil);
    }
  }

  Future<void> _eliminarSeleccionadas() async {
    setState(() {
      final ordenados = _indicesSeleccionados.toList()..sort((a, b) => b - a);
      for (var idx in ordenados) {
        widget.perfil.combinaciones.removeAt(idx);
      }
      _indicesSeleccionados.clear();
      textoGuante = widget.perfil.combinaciones.isNotEmpty
          ? widget.perfil.combinaciones.last.frase
          : "Esperando combinación...";
    });
    await _box.putAt(widget.hiveIndex, widget.perfil);
  }

  void _onTapItem(int index) {
    if (_indicesSeleccionados.isNotEmpty) {
      _onSelectItem(index);
    } else {
      setState(() {
        textoGuante = widget.perfil.combinaciones[index].frase;
      });
    }
  }

  void _onSelectItem(int index) {
    setState(() {
      if (!_indicesSeleccionados.add(index)) {
        _indicesSeleccionados.remove(index);
      }
    });
  }

  bool get _modoSeleccion => _indicesSeleccionados.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 3,
        centerTitle: true,
        title: Text(
          _modoSeleccion
              ? '${_indicesSeleccionados.length} seleccionadas'
              : 'Editar - ${widget.perfil.nombre}',
          style: GoogleFonts.poppins(fontSize: 20),
        ),
        actions: _modoSeleccion
            ? [
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: _eliminarSeleccionadas,
                ),
              ]
            : [],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            if (!_modoSeleccion)
              ElevatedButton.icon(
                icon: Icon(Icons.add, size: 20),
                label: Text("Añadir nueva combinación"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 29, 27, 32),
                  foregroundColor: Colors.white,
                  textStyle: GoogleFonts.poppins(fontSize: 16),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _anadirCombinacion,
              ),

            SizedBox(height: 20),

            // Lista de combinaciones
            Expanded(
              child: ListView.builder(
                itemCount: widget.perfil.combinaciones.length,
                itemBuilder: (_, i) {
                  final comb = widget.perfil.combinaciones[i];
                  final seleccionado = _indicesSeleccionados.contains(i);

                  return AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: seleccionado
                          ? Colors.blue.withOpacity(0.25)
                          : Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: seleccionado
                            ? Colors.white
                            : Colors.grey.shade800,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      onTap: () => _onTapItem(i),
                      onLongPress: () => _onSelectItem(i),
                      leading: Icon(
                        Icons.touch_app,
                        color: Colors.lightBlueAccent,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comb.dedos.join(', '),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Posición: ${comb.posicion}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        comb.frase,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      trailing: seleccionado
                          ? Icon(Icons.check_circle, color: Colors.greenAccent)
                          : null,
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
