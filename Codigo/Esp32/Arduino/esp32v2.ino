#include <ArduinoJson.h> //Libreria para interpreatr archivos JSON (BaseDatos), permite parsear y crear.
#include "FS.h" //File System, permite abrir, leer, escribir... arcivos
#include "SPIFFS.h" //Permite almacenar datos en una especie de "memoria" de la ESP32
#include "BluetoothSerial.h" //Enviar y recibir datos por medio de Bluetooth

BluetoothSerial SerialBT; //Crea un objeto llamada SerialBT (Serial Bluetooth) para manejar la comunicación.

const int dedos[4] = {14, 27, 26, 25}; 
const int botonEncendido = 4;
const int botonPerfil = 5;
const int led = 23;

bool sistemaActivo = true;
int perfilActual = 1;

unsigned long ultimoCambioEncendido = 0;
unsigned long ultimoCambioPerfil = 0;

DynamicJsonDocument frases(4096);

// LED parpadeo durante actualización
bool actualizando = false;
unsigned long tiempoAnteriorParpadeo = 0;
bool estadoLedParpadeo = false;

// -------------------- Función para Cargar JSON --------------------
void cargarFrases() {
  File file = SPIFFS.open("/frases.json", "r");
  if (!file) {
    Serial.println("Error al abrir frases.json");
    return;
  }

  DeserializationError err = deserializeJson(frases, file);
  file.close();

  if (err) {
    Serial.println("Error al leer JSON:");
    Serial.println(err.c_str());
    return;
  }

  Serial.println("Frases cargadas correctamente.");
}

// -------------------- Obtener código de 4 bits --------------------
String obtenerCodigo() {
  String codigo = "";
  for (int i = 0; i < 4; i++) {
    bool presionado = digitalRead(dedos[i]) == LOW;
    codigo += presionado ? "1" : "0";
  }
  return codigo;
}

// -------------------- Guardar nuevo JSON desde Bluetooth --------------------
void guardarNuevoJSON(String nuevoContenido) {
  actualizando = true;

  delay(200);
  File file = SPIFFS.open("/frases.json", "w");
  if (!file) {
    Serial.println("No se pudo abrir frases.json para escritura.");
    actualizando = false;
    return;
  }

  file.print(nuevoContenido);
  file.close();
  Serial.println("Nuevo JSON guardado desde Bluetooth.");

  cargarFrases();

  actualizando = false;
  digitalWrite(led, sistemaActivo ? HIGH : LOW);
}

// -------------------- SETUP --------------------
void setup() {
  Serial.begin(9600);
  SerialBT.begin("TechTalk");

  for (int i = 0; i < 4; i++) {
    pinMode(dedos[i], INPUT_PULLUP);
  }

  pinMode(botonEncendido, INPUT_PULLUP);
  pinMode(botonPerfil, INPUT_PULLUP);

  pinMode(led, OUTPUT);
  digitalWrite(led, HIGH);

  if (!SPIFFS.begin(true)) {
    Serial.println("Error montando SPIFFS");
    return;
  }

  cargarFrases();
}

// -------------------- LOOP --------------------
void loop() {
  unsigned long ahora = millis();

  // Botón de encendido
  if (digitalRead(botonEncendido) == LOW && ahora - ultimoCambioEncendido > 500) {
    sistemaActivo = !sistemaActivo;
    ultimoCambioEncendido = ahora;
    digitalWrite(led, sistemaActivo ? HIGH : LOW);
    Serial.println(sistemaActivo ? "Sistema Activado" : "Sistema Desactivado");
  }

  // Botón de perfil
  if (digitalRead(botonPerfil) == LOW && ahora - ultimoCambioPerfil > 500) {
    perfilActual++;
    String claveNueva = "perfil" + String(perfilActual);
    if (!frases.containsKey(claveNueva)) {
      perfilActual = 1;
    }
    ultimoCambioPerfil = ahora;
    Serial.print("Perfil actual: ");
    Serial.println(perfilActual);
  }

  if (!sistemaActivo) return;

  // Lectura de código
  String codigo = obtenerCodigo();

  if (codigo != "0000") {
    String clavePerfil = "perfil" + String(perfilActual);
    Serial.print("Código detectado: ");
    Serial.println(codigo);

    if (frases[clavePerfil][codigo].is<String>()) {
      String frase = frases[clavePerfil][codigo].as<String>();
      
      // 1) Se imprime por USB como antes
      Serial.println("Frase: " + frase);
      // 2) ¡Nuevo! Enviamos la frase también por Bluetooth:
      SerialBT.println(frase);
      
    } else {
      Serial.println("Código no encontrado.");
      // Opcional: avisar por Bluetooth si quieres
      // SerialBT.println("Código no encontrado.");
    }

    delay(500);
  }

  // Lectura Bluetooth
  if (SerialBT.available()) {
    String jsonRecibido = SerialBT.readStringUntil('\n');
    Serial.println("JSON recibido por Bluetooth:");
    Serial.println(jsonRecibido);
    guardarNuevoJSON(jsonRecibido);
  }

  // Parpadeo del LED durante actualización
  if (actualizando) {
    unsigned long tiempoActual = millis();
    if (tiempoActual - tiempoAnteriorParpadeo > 200) {
      tiempoAnteriorParpadeo = tiempoActual;
      estadoLedParpadeo = !estadoLedParpadeo;
      digitalWrite(led, estadoLedParpadeo ? HIGH : LOW);
    }
  }
}
