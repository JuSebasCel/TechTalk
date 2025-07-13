// Reemplaza tu archivo home_screen.dart con este
import 'package:flutter/material.dart';
import 'package:guante_comunicador_app/screens/bluetooth_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/perfil.dart';
import 'crear_perfil_screen.dart';
import 'editar_combinaciones_screen.dart';
import 'credits_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Box<Perfil> _box;
  String _ultimaFrase = "";
  bool conectado = false;
  String nombreDispositivo = "";
  final List<String> frases = [
    "¡Hoy es un gran día para sonreír!",
    "La constancia es la clave del éxito.",
    "Hazlo con pasión o no lo hagas.",
    "Cada día es una nueva oportunidad.",
    "Cree en ti y todo será posible.",
  ];
  String fraseActual = "";
  final StreamController<String> _guanteStreamController =
      StreamController<String>();
  void _cambiarFrase() {
    final nuevaFrase = (frases.toList()..remove(fraseActual))..shuffle();
    setState(() {
      fraseActual = nuevaFrase.first;
    });
  }

  @override
  void initState() {
    super.initState();
    _cambiarFrase();
    _box = Hive.box<Perfil>('perfilesBox');

    _guanteStreamController.stream.listen((mensaje) {
      if (fraseRecibidaNotifier.value != mensaje) {
        fraseRecibidaNotifier.value = mensaje;
      }
    });

    Future.delayed(Duration(seconds: 5), () {
      _guanteStreamController.add("¡Hola desde el guante!");
    });
  }

  @override
  void dispose() {
    _guanteStreamController.close();
    super.dispose();
  }

  void actualizarConexion(bool estado, String nombre) {
    setState(() {
      conectado = estado;
      nombreDispositivo = nombre;
    });
  }

  Future<void> _crearPerfil() async {
    final nuevoPerfil = await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Crear Perfil",
      barrierColor: Colors.black.withOpacity(0.3), // fondo más suave
      transitionDuration: Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return CrearPerfilScreen();
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );

    if (nuevoPerfil != null) {
      setState(() {});
    }
  }

  void _administrarCombinaciones(int index, Perfil perfil) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditarCombinacionesScreen(perfil: perfil, hiveIndex: index),
      ),
    );
  }

  Future<void> _eliminarPerfil(int index, Perfil perfil) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿Eliminar perfil?'),
        content: Text(
          '¿Estás seguro de que deseas eliminar el perfil "${perfil.nombre}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _box.deleteAt(index);
      Navigator.pop(context);

      setState(() {});
    }
  }

  void _mostrarAyuda() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final PageController controller = PageController();
        final List<Map<String, String>> tutorialPages = [
          {
            'title': 'Bienvenido a TechTalk',
            'desc':
                'Esta app te ayuda a comunicarte usando un guante con sensores. A continuación te mostraremos cómo usarla.',
          },
          {
            'title': 'Crear Perfil',
            'desc':
                'Pulsa "Crear Perfil" para registrar una nueva configuración personalizada con combinaciones.',
          },
          {
            'title': 'Administrar',
            'desc':
                'Desde "Administrar", puedes editar o eliminar perfiles existentes fácilmente.',
          },
          {
            'title': 'Frases del Guante',
            'desc':
                'Las frases que el guante detecta aparecerán en tiempo real en el recuadro central.',
          },
          {
            'title': 'Bluetooth',
            'desc':
                'Pulsa el botón de Bluetooth para emparejar el guante con la app. Necesitas estar conectado para recibir frases.',
          },
          {
            'title': 'Créditos',
            'desc':
                'Consulta la sección de Créditos para conocer a los desarrolladores y colaboradores del proyecto.',
          },
        ];

        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  itemCount: tutorialPages.length,
                  itemBuilder: (context, index) {
                    final page = tutorialPages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          page['title']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          page['desc']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(tutorialPages.length, (index) {
                  return AnimatedBuilder(
                    animation: controller,
                    builder: (context, child) {
                      double selected = 0;
                      try {
                        selected = controller.page ?? 0;
                      } catch (_) {}
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: selected.round() == index ? 12 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: selected.round() == index
                              ? Colors.blueAccent
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TechTalk',
          style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.only(top: 20, left: 24.0, right: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: conectado ? Colors.green : Colors.red,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      conectado
                          ? 'Conectado a: $nombreDispositivo'
                          : 'No conectado',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Image.asset('assets/images/unal_logo.png', height: 250),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.add,
                      label: 'Crear Perfil',
                      onPressed: _crearPerfil,
                    ),
                    _buildActionButton(
                      icon: Icons.settings,
                      label: 'Administrar',
                      onPressed: () {
                        final perfiles = _box.values.toList();
                        if (perfiles.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No hay perfiles creados')),
                          );
                          return;
                        }
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          builder: (_) {
                            int? _sel;
                            return StatefulBuilder(
                              builder: (context, setModal) {
                                return Container(
                                  height: constraints.maxHeight * 0.5,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 12,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[600],
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'Selecciona un perfil',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Expanded(
                                        child: ListView.builder(
                                          itemCount: perfiles.length,
                                          itemBuilder: (context, i) {
                                            final p = perfiles[i];
                                            final selected = _sel == i;
                                            return GestureDetector(
                                              onTap: () {
                                                setModal(() => _sel = i);
                                                Future.delayed(
                                                  Duration(milliseconds: 200),
                                                  () =>
                                                      _administrarCombinaciones(
                                                        i,
                                                        p,
                                                      ),
                                                );
                                              },
                                              child: AnimatedContainer(
                                                duration: Duration(
                                                  milliseconds: 200,
                                                ),
                                                margin: EdgeInsets.symmetric(
                                                  vertical: 6,
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 12,
                                                  horizontal: 16,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: selected
                                                      ? Colors.blueAccent
                                                            .withOpacity(0.3)
                                                      : Colors.grey[850],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black26,
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.person,
                                                      color: selected
                                                          ? Colors.blueAccent
                                                          : Colors.white70,
                                                    ),
                                                    SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        '${i + 1}. ${p.nombre}',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 16,
                                                          color: selected
                                                              ? Colors
                                                                    .blueAccent
                                                              : Colors.white70,
                                                          fontWeight: selected
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                    .normal,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.delete,
                                                        color: Colors.redAccent,
                                                      ),
                                                      onPressed: () =>
                                                          _eliminarPerfil(i, p),
                                                    ),
                                                    if (selected)
                                                      Icon(
                                                        Icons.check_circle,
                                                        color:
                                                            Colors.blueAccent,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  height: constraints.maxHeight * 0.25,
                  width: double.infinity,
                  child: ValueListenableBuilder<String>(
                    valueListenable: fraseRecibidaNotifier,
                    builder: (context, frase, _) {
                      return Center(
                        child: Builder(
                          builder: (context) {
                            if (frase.isNotEmpty) {
                              _ultimaFrase = frase;
                            }
                            return Text(
                              _ultimaFrase.isNotEmpty
                                  ? _ultimaFrase
                                  : "Aquí aparecerán los mensajes del guante en tiempo real.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.info,
                      label: 'Créditos',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CreditsScreen()),
                        );
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.bluetooth,
                      label: 'Bluetooth',
                      onPressed: () async {
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BluetoothScreen(),
                          ),
                        );
                        if (resultado != null &&
                            resultado is Map<String, dynamic>) {
                          actualizarConexion(
                            resultado['conectado'],
                            resultado['nombre'],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarAyuda,
        child: Icon(Icons.help_outline),
        backgroundColor: Colors.grey[850],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 24),
      label: Text(label, style: GoogleFonts.poppins()),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontSize: 16),
      ),
      onPressed: onPressed,
    );
  }
}
