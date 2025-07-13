import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guante_comunicador_app/models/perfil.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

final ValueNotifier<String> fraseRecibidaNotifier = ValueNotifier<String>("");

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  static BluetoothConnection? _persistentConnection;
  static BluetoothDevice? _persistentDevice;

  List<BluetoothDevice> _devices = [];
  bool _isDiscovering = false;
  BluetoothDevice? _selectedDevice;
  BluetoothConnection? _connection;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    await _requestPermissions();

    // Restaurar conexión si ya estaba conectada (solo deja el estado, NO poppea)
    if (_persistentConnection != null && _persistentConnection!.isConnected) {
      setState(() {
        _connection = _persistentConnection;
        _selectedDevice = _persistentDevice;
        _isConnected = true;
      });
    } else {
      _startDiscovery();
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
    await Permission.storage.request();
  }

  void _startDiscovery() async {
    setState(() {
      _isDiscovering = true;
      _devices.clear();
    });

    FlutterBluetoothSerial.instance
        .startDiscovery()
        .listen((r) {
          if (!_devices.contains(r.device)) {
            setState(() => _devices.add(r.device));
          }
        })
        .onDone(() {
          setState(() => _isDiscovering = false);
        });
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      setState(() => _selectedDevice = device);

      BluetoothConnection connection = await BluetoothConnection.toAddress(
        device.address,
      );
      setState(() {
        _connection = connection;
        _isConnected = true;
        _persistentConnection = connection;
        _persistentDevice = device;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conectado a ${device.name ?? device.address}')),
      );

      // Devuelve el estado de conexión al HomeScreen
      Navigator.pop(context, {
        'conectado': true,
        'nombre': device.name ?? device.address,
      });

      connection.input!
          .listen((Uint8List data) {
            final mensaje = utf8.decode(data).trim();
            print("📨 Mensaje recibido: $mensaje");
            fraseRecibidaNotifier.value = mensaje;
          })
          .onDone(() {
            print("❌ Conexión terminada");
            _disconnect();
          });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connection = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al conectar con el dispositivo')),
      );
    }
  }

  void _disconnect() {
    _connection?.dispose();
    setState(() {
      _isConnected = false;
      _selectedDevice = null;
      _connection = null;
      _persistentConnection = null;
      _persistentDevice = null;
    });

    // Devuelve el estado de desconexión
    Navigator.pop(context, {'conectado': false, 'nombre': ''});
  }

  String _dedosACodigo(List<String> dedos, String posicion) {
    List<String> orden = ['Índice', 'Medio', 'Anular', 'Meñique'];
    return orden.map((dedo) => dedos.contains(dedo) ? '1' : '0').join() +
        posicion;
  }

  Future<void> _enviarJsonAlDispositivo() async {
    try {
      final box = await Hive.openBox<Perfil>('perfilesBox');
      Map<String, Map<String, String>> jsonMap = {};
      for (int i = 0; i < box.length; i++) {
        final perfil = box.getAt(i);
        final nombre = 'perfil${i + 1}';
        final combinaciones = perfil?.combinaciones ?? [];
        Map<String, String> combinacionesMap = {};
        for (var comb in combinaciones) {
          final codigo = _dedosACodigo(comb.dedos, comb.posicion);
          combinacionesMap[codigo] = comb.frase;
        }
        jsonMap[nombre] = combinacionesMap;
      }

      final jsonString = jsonEncode(jsonMap);
      if (_connection != null && _connection!.isConnected) {
        _connection!.output.add(utf8.encode('$jsonString\n'));
        await _connection!.output.allSent;

        final dir = await getExternalStorageDirectory();
        final file = File('${dir!.path}/perfiles.json');
        await file.writeAsString(jsonString);
        print('💾 JSON guardado en: ${file.path}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ JSON enviado con ${jsonMap.length} perfiles'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay conexión Bluetooth activa')),
        );
      }
    } catch (e) {
      print('❌ Error general en _enviarJsonAlDispositivo: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error enviando JSON: $e')));
    }
  }

  Future<void> _enviarJsonDePrueba() async {
    final mensaje = '{"perfil1":{"1000S":"Hola mundo"}}\n';
    if (_connection != null && _connection!.isConnected) {
      _connection!.output.add(utf8.encode(mensaje));
      await _connection!.output.allSent;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mensaje de prueba enviado.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay conexión Bluetooth activa.")),
      );
    }
  }

  Widget _buildDeviceTile(BluetoothDevice device) {
    return ListTile(
      title: Text(
        device.name ?? "Dispositivo sin nombre",
        style: GoogleFonts.poppins(fontSize: 16),
      ),
      subtitle: Text(device.address),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _connectToDevice(device),
        child: Text(
          "Conectar",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildConnectedContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Conectado a ${_selectedDevice?.name ?? "ESP32"}",
            style: GoogleFonts.poppins(fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _enviarJsonAlDispositivo,
            icon: const Icon(Icons.send),
            label: Text("Enviar JSON", style: GoogleFonts.poppins()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _enviarJsonDePrueba,
            icon: const Icon(Icons.bolt),
            label: Text("Prueba: Indice Sup", style: GoogleFonts.poppins()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _disconnect,
            icon: const Icon(Icons.bluetooth_disabled),
            label: Text("Desconectar", style: GoogleFonts.poppins()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Conexión Bluetooth",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 20, 17, 24),
      ),
      body: Column(
        children: [
          if (_isDiscovering && !_isConnected)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(
                    "Buscando dispositivos...",
                    style: GoogleFonts.poppins(),
                  ),
                ],
              ),
            )
          else if (!_isConnected)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _startDiscovery,
                icon: const Icon(Icons.refresh),
                label: Text("Buscar de nuevo", style: GoogleFonts.poppins()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 29, 27, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          Expanded(
            child: _isConnected
                ? _buildConnectedContent()
                : _devices.isEmpty
                ? Center(
                    child: Text(
                      "No se encontraron dispositivos.",
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) =>
                        _buildDeviceTile(_devices[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
