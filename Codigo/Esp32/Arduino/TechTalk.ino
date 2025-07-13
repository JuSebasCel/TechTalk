#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <ArduinoJson.h>
#include "FS.h"
#include "SPIFFS.h"
#include "BluetoothSerial.h"

// -------------------- OLED -------------------- //
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1

TwoWire WireOLED = TwoWire(0);  // Bus I2C para OLED (18, 19)
TwoWire WireMPU = TwoWire(1);   // Bus I2C para MPU6050 (21, 22)

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &WireOLED, OLED_RESET);
Adafruit_MPU6050 mpu;

bool oledActiva = false;
bool mpuActivo = false;

// -------------------- COMPONENTES -------------------- //
BluetoothSerial SerialBT;

const int dedos[4] = {14, 27, 26, 25};
const int botonEncendido = 4;
const int botonPerfil = 5;
const int led = 23;

bool sistemaActivo = true;
int perfilActual = 1;

unsigned long ultimoCambioEncendido = 0;
unsigned long ultimoCambioPerfil = 0;

DynamicJsonDocument frases(8192);
int zManual = 0;

String ultimaFraseMostrada = "";
unsigned long tiempoUltimaFrase = 0;
bool mostrandoFrase = false;

bool modoGuia = false;
unsigned long tiempoPresionadoGuia = 0;
bool esperandoModoGuia = false;

// -------------------- FUNCIONES -------------------- //
void mostrarPerfilEnPantalla(int perfil) {
  if (!oledActiva) return;
  display.clearDisplay();
  display.setTextSize(2);
  display.setTextColor(SSD1306_WHITE);
  display.setTextWrap(false);
  display.setCursor(10, 25);
  display.print("Perfil ");
  display.print(perfil);
  display.display();
}

void cargarFrases() {
  File file = SPIFFS.open("/frases_extendido.json", "r");
  if (!file) {
    Serial.println("Error al abrir frases_extendido.json");
    return;
  }
  DeserializationError err = deserializeJson(frases, file);
  file.close();
  if (err) {
    Serial.println("Error al leer JSON:");
    Serial.println(err.c_str());
    return;
  }
}

String obtenerCodigo() {
  String codigo = "";
  for (int i = 0; i < 4; i++) {
    bool presionado = digitalRead(dedos[i]) == LOW;
    codigo += presionado ? '1' : '0';
  }

  if (zManual <= -7) {
    codigo += 'I';
  } else if (zManual >= 7) {
    codigo += 'S';
  } else {
    codigo += 'N';
  }
  return codigo;
}

void guardarNuevoJSON(String nuevoContenido) {
  delay(200);
  File file = SPIFFS.open("/frases_extendido.json", "w");
  if (!file) {
    Serial.println("No se pudo abrir frases_extendido.json para escritura.");
    return;
  }
  file.print(nuevoContenido);
  file.close();
  cargarFrases();
}

void mostrarFraseEnPantalla(String frase) {
  if (!oledActiva) return;
  if (frase == ultimaFraseMostrada) return;

  ultimaFraseMostrada = frase;
  mostrandoFrase = true;
  tiempoUltimaFrase = millis();

  int textWidth = frase.length() * 12; // Estimación en pixeles
  int yFrase = 20;   // Línea superior
  int yPerfil = 50;  // Línea inferior para “Perfil X”

  String textoPerfil = "Perfil " + String(perfilActual);

  if (textWidth <= SCREEN_WIDTH) {
    int x = (SCREEN_WIDTH - textWidth) / 2;
    display.clearDisplay();
    display.setTextSize(2);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(x, yFrase);
    display.print(frase);

    display.setTextSize(1);
    display.setCursor((SCREEN_WIDTH - textoPerfil.length() * 6) / 2, yPerfil);
    display.print(textoPerfil);

    display.display();
  } else {
    for (int rep = 0; rep < 3; rep++) {
      for (int x = SCREEN_WIDTH; x >= -textWidth; x--) {
        display.clearDisplay();

        // Frase grande con scroll
        display.setTextSize(2);
        display.setCursor(x, yFrase);
        display.print(frase);

        // Texto de perfil pequeño debajo
        display.setTextSize(1);
        display.setCursor((SCREEN_WIDTH - textoPerfil.length() * 6) / 2, yPerfil);
        display.print(textoPerfil);

        display.display();
        delay(10);
      }
    }

    // Mostrar estática la última parte visible
    display.clearDisplay();
    display.setTextSize(2);
    display.setCursor(max(-textWidth + SCREEN_WIDTH, 0), yFrase);
    display.print(frase);

    display.setTextSize(1);
    display.setCursor((SCREEN_WIDTH - textoPerfil.length() * 6) / 2, yPerfil);
    display.print(textoPerfil);

    display.display();
  }
}



// -------------------- SETUP -------------------- //
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

  // Iniciar buses I2C
  WireOLED.begin(18, 19);  // OLED
  WireMPU.begin(21, 22);   // MPU6050

  // Inicializar OLED
  if (display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    oledActiva = true;
    display.clearDisplay();
    display.setTextSize(2);
    display.setTextColor(SSD1306_WHITE);
    display.setTextWrap(false);
    mostrarPerfilEnPantalla(perfilActual);
  } else {
    Serial.println("Pantalla OLED no detectada");
    oledActiva = false;
  }

  // Montar SPIFFS
  if (!SPIFFS.begin(true)) {
    Serial.println("Error montando SPIFFS");
    return;
  }
  cargarFrases();

  // Inicializar MPU6050 en el bus personalizado
  if (mpu.begin(0x68, &WireMPU)) {
    mpuActivo = true;
    mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
    mpu.setGyroRange(MPU6050_RANGE_500_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
    delay(100);
  } else {
    Serial.println("No se encontró el MPU6050 en el bus secundario");
    mpuActivo = false;
  }
}

// -------------------- LOOP -------------------- //
void loop() {
  unsigned long ahora = millis();

  if (mpuActivo) {
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);
    zManual = a.acceleration.z;
  } else {
    zManual = 0;
  }

  bool botonEncendidoActual = digitalRead(botonEncendido) == LOW;

if (botonEncendidoActual && !esperandoModoGuia) {
  // Primer momento que se detecta presionado
  tiempoPresionadoGuia = ahora;
  esperandoModoGuia = true;
}

if (!botonEncendidoActual && esperandoModoGuia) {
  unsigned long duracion = ahora - tiempoPresionadoGuia;
  esperandoModoGuia = false;

  if (duracion >= 5000) {
    // Pulsación larga: activar/desactivar modo guía
    modoGuia = !modoGuia;
    Serial.println(modoGuia ? "🟢 Modo Guía ACTIVADO" : "🔴 Modo Guía DESACTIVADO");

    if (oledActiva) {
      display.clearDisplay();
      display.setTextSize(2);
      display.setTextColor(SSD1306_WHITE);
      display.setCursor(10, 25);
      display.print(modoGuia ? "Modo Guia ON" : "Modo Guia OFF");
      display.display();
      delay(1000);  // Mostrar estado y volver al perfil
    }

    mostrarPerfilEnPantalla(perfilActual);

  } else if (duracion >= 100 && duracion < 1500) {
    // Pulsación corta: encender/apagar sistema
    sistemaActivo = !sistemaActivo;
    digitalWrite(led, sistemaActivo ? HIGH : LOW);
    Serial.println(sistemaActivo ? "Sistema Activado" : "Sistema Desactivado");
    mostrarPerfilEnPantalla(perfilActual);
  }

  // Ignora pulsaciones entre 1.5 y 5 segundos (zona muerta)
}


  // Botón perfil
  if (digitalRead(botonPerfil) == LOW && ahora - ultimoCambioPerfil > 250) {
    perfilActual++;
    String claveNueva = "perfil" + String(perfilActual);
    if (!frases.containsKey(claveNueva)) {
      perfilActual = 1;
    }

    ultimoCambioPerfil = ahora;
    mostrarPerfilEnPantalla(perfilActual);
    Serial.print("Perfil actual: ");
    Serial.println(perfilActual);
  }

  if (!sistemaActivo) return;

  String codigo = obtenerCodigo();

  if (!codigo.startsWith("0000")) {
    if (codigo.endsWith("I") || codigo.endsWith("N") || codigo.endsWith("S")) {
      String clavePerfil = "perfil" + String(perfilActual);
      Serial.print("Código detectado: ");
      Serial.println(codigo);

      if (frases[clavePerfil][codigo].is<String>()) {
        String frase = frases[clavePerfil][codigo].as<String>();
        SerialBT.println(frase);
        Serial.println(frase);
        if (modoGuia) {
        mostrarFraseEnPantalla(frase);
        }

      } else {
        Serial.println("Código no encontrado en este perfil.");
      }

      delay(500);
    }
  }

  if (SerialBT.available()) {
    String jsonRecibido = SerialBT.readStringUntil('\n');
    guardarNuevoJSON(jsonRecibido);
  }

  if (mostrandoFrase && millis() - tiempoUltimaFrase > 3000) {
    mostrarPerfilEnPantalla(perfilActual);
    mostrandoFrase = false;
  }
}
