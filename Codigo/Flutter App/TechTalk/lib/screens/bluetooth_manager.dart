// bluetooth_manager.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter/material.dart';

class BluetoothManager {
  BluetoothConnection? _connection;
  BluetoothDevice? _device;
  final ValueNotifier<String> fraseRecibida = ValueNotifier<String>("");

  static final BluetoothManager _instance = BluetoothManager._internal();
  factory BluetoothManager() => _instance;
  BluetoothManager._internal();

  bool get isConnected => _connection != null && _connection!.isConnected;
  BluetoothDevice? get connectedDevice => _device;

  Future<void> connectToDevice(
    BluetoothDevice device,
    BuildContext context,
  ) async {
    try {
      _device = device;
      _connection = await BluetoothConnection.toAddress(device.address);
      _connection!.input!
          .listen((Uint8List data) {
            final mensaje = utf8.decode(data).trim();
            fraseRecibida.value = mensaje;
            print("📨 Mensaje recibido: $mensaje");
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Frase recibida: $mensaje')));
          })
          .onDone(() {
            print("❌ Conexión terminada");
            disconnect();
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conectado a ${device.name ?? device.address}')),
      );
    } catch (e) {
      _connection = null;
      _device = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al conectar con el dispositivo: $e')),
      );
    }
  }

  void disconnect() {
    _connection?.dispose();
    _connection = null;
    _device = null;
  }

  void sendMessage(String message, BuildContext context) async {
    if (isConnected) {
      _connection!.output.add(utf8.encode(message));
      await _connection!.output.allSent;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Mensaje enviado")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No hay conexión activa")));
    }
  }
}
