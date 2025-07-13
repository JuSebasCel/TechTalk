//Paquetes que usaremos.
  //Librerias del giroscopio
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <ArduinoJson.h> //Libreria para interpreatr archivos JSON (BaseDatos), permite parsear y crear.
#include "FS.h" //File System, permite abrir, leer, escribir... archivos.
#include "SPIFFS.h" //Permite almacenar datos en una especie de "memoria" de la ESP32.
#include "BluetoothSerial.h" // Comunicación Bluetooth

BluetoothSerial SerialBT; //Crea un objeto llamada SerialBT (Serial Bluetooth) para manejar la comunicación.
Adafruit_MPU6050 mpu; //Objeto del sensor

//Componentes asignados en constante para evitar cambios inintencionados.
const int dedos[4] = {14, 27, 26, 25}; //Array de numero de pin claramente en entero.
const int botonEncendido = 4; //Boton de encendido (Activar desactivar el sistema, cambiando el estado de un led).
const int led = 23; //Led que cambia de estado mencionado anteriormente.
const int botonPerfil = 5; //Boton que permite cambiar los perfiles cargados.

//Variables "base" para modificar comportamientos.
bool sistemaActivo = true; //Bool que enciende o no en base al estado del sistema.
int perfilActual = 1; //Variable que iteramos para cambiar entre los perfiles.

//Variables encargadas de cuantificar el tiempo que ha pasado desde que se pulso determinado boton.
unsigned long ultimoCambioEncendido = 0;
unsigned long ultimoCambioPerfil = 0;

//Crea un documento JSON con capacidad de 8192 bytes, aqui se almacenan las frases cuando las cargamos de manera manual.
DynamicJsonDocument frases(8192);

//"DEBUG" Variable manual para eje Z (temporal en lugar de giroscopio).
  //Rangos: S [7,inf) N (-7,7) I [-7,-inf)
int zManual = 0;


// -------------------- Función para Cargar JSON -------------------- //
void cargarFrases() {
  //Abre el archivo y en caso de que no poder hacerlo (!file), manda un mensaje de error.
  File file = SPIFFS.open("/frases_extendido.json", "r");
  if (!file) {
    Serial.println("Error al abrir frases_extendido.json");
    return;
  }

  //Intenta deserializarlo y en caso de tener error también envia mensaje de alerta
  DeserializationError err = deserializeJson(frases, file);
  file.close();
  if (err) {
    Serial.println("Error al leer JSON:");
    Serial.println(err.c_str());
    return;
  }

  //En caso de no haber ningun problema, envia un aviso de exito.
  //Serial.println("Frases cargadas correctamente.");
}

// -------------------- Obtener código de 4 bits + sufijo eje Z -------------------- // 
//Función String que transcribe la actual combinación de pines digitales y el sufijo en base al intervalo del eje Z que tenga el giroscopio.
String obtenerCodigo() {
  //Variable base donde se escribira el codigo.
  String codigo = "";

  //Recorre el array donde estan los pines analizando si esta "activo" o no, en este caso, ser activo es estar en LOW.
  for (int i = 0; i < 4; i++) {
    bool presionado = digitalRead(dedos[i]) == LOW;
    codigo += presionado ? '1' : '0';
  }
  
  //Sufijo según el intervalo que tenga el eje Z, actualmente manual.
  if (zManual <= -7) {
    codigo += 'I';
  } else if (zManual >= 7) {
    codigo += 'S';
  } else {
    codigo += 'N';
  }
  return codigo;
}

// -------------------- Guardar nuevo JSON desde Bluetooth -------------------- //
void guardarNuevoJSON(String nuevoContenido) {

  delay(200);
  //En caso de no poder cargar correctamente el archivo en forma de escritura, da un mensaje de error.
  File file = SPIFFS.open("/frases_extendido.json", "w");
  if (!file) {
    Serial.println("No se pudo abrir frases_extendido.json para escritura.");
    return;
  }

  //Aviso de que se ha realizado correctamente
  file.print(nuevoContenido); //DEBUG Muestra el contenido del JSON de entrada por SerialBluetooth.
  file.close(); //Cerramos el archivo pues ya se escribio en el la nueva información.
  //Serial.println("Nuevo JSON guardado desde Bluetooth."); //Mensaje de aviso.

  cargarFrases();
}

// -------------------- SETUP -------------------- //
void setup() {
  Serial.begin(9600); //Baudios funcionales para mi ESP32.
  SerialBT.begin("TechTalk"); //Nombre con el que aparecera en Bluetooth.

  //Configuramos los pines de los dedos como entrada usando pullUp a traves de un for.
  for (int i = 0; i < 4; i++) {
    pinMode(dedos[i], INPUT_PULLUP);
  }

  //Inicializamos los demas componentes.
  pinMode(botonEncendido, INPUT_PULLUP);
  pinMode(botonPerfil, INPUT_PULLUP);
  pinMode(led, OUTPUT);

  //Iniciamos el led en HIGH para que corresponda al sistema en modo activo.
  digitalWrite(led, HIGH);

  //Iniciamos el SPIFFS (El espacio de "memoria" donde estara el JSON que carguemos). 
  if (!SPIFFS.begin(true)) {
    Serial.println("Error montando SPIFFS");
    return;
  }

  cargarFrases();
    // Inicializar el MPU6050
  if (!mpu.begin()) {
    Serial.println("No se encontró el MPU6050. Verifica conexión.");
    while (1) delay(10);
  }

  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
  delay(100);

}

// -------------------- LOOP -------------------- // 
void loop() {
  //Variable base para poder despues hacer la diferencia entre el tiempo que ha pasado desde haber pulsado determinado botón.
  unsigned long ahora = millis();

  // Obtener valor del eje Z desde el acelerómetro del MPU6050
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  zManual = a.acceleration.z;
  // DEBUG opcional:
  //Serial.print("Valor Z acelerómetro: "); Serial.println(zManual);

  // Botón de encendido
    //Busca una diferencia entre la ultima vez que se pulso, evitando errores por sobrecargar el sistema.
  if (digitalRead(botonEncendido) == LOW && ahora - ultimoCambioEncendido > 500) {

    //Invierte el valor del bool que cambia el estado del sistema.
    sistemaActivo = !sistemaActivo;
    
    //Reasigna el valor del ultimo cambio.
    ultimoCambioEncendido = ahora;
    
    //Cambiamos el estado del led indicativo y también enviamos un mensaje de aviso por el Serial.
    digitalWrite(led, sistemaActivo ? HIGH : LOW);
    Serial.println(sistemaActivo ? "Sistema Activado" : "Sistema Desactivado");
  }

  // Botón de perfil
    //Busca una diferencia entre la ultima vez que se pulso, evitando errores por sobrecargar el sistema.
  if (digitalRead(botonPerfil) == LOW && ahora - ultimoCambioPerfil > 500) {
    //Cambiamos al siguiente perfil (perfilActual = perfilActual + 1;)
    perfilActual++;
    String claveNueva = "perfil" + String(perfilActual);
    if (!frases.containsKey(claveNueva)) {
      perfilActual = 1;
    }        
    
    //Reasigna el valor del ultimo cambio.
    ultimoCambioPerfil = ahora;

    //Mostramos mensaje guía por el Serial.
    Serial.print("Perfil actual: ");
    Serial.println(perfilActual);
  }

  //En caso de que el sistema este apagado, finaliza el loop, evitando que suceda cualquier cosa.
  if (!sistemaActivo) return;

  // Lectura de código + sufijo
  String codigo = obtenerCodigo();

  // Solo procesar el código si no es 0000 (pero no detener el loop)
if (!codigo.startsWith("0000")) {
  //Evita que pase por alto alguna combinación sin indicación de eje Z (previene cualquier altercado de envio por la app).
  if (codigo.endsWith("I") || codigo.endsWith("N") || codigo.endsWith("S")) {
    //Construye la indicación de primera clave para el Map general en formato como {"perfil1", "perfil2"}.
    String clavePerfil = "perfil" + String(perfilActual);
    //Muestra el código encontrado.
    Serial.print("Código detectado: ");
    Serial.println(codigo);

    //Busca dentro del diccionario de diccionarios, primero iterando el perfil para despues encontrar la frase/palabra del código.
    if (frases[clavePerfil][codigo].is<String>()) {
      //Guarda la palabra/frase encontrada como String.
      String frase = frases[clavePerfil][codigo].as<String>();
      //La muestra en el Serial para despues ser leída por el programa de pyttsx3.
      //Serial.println("Frase: " + frase);
      SerialBT.println(frase);
      Serial.println(frase);

      //En caso contrario avisara que no encontro nada con esa pareja clave-valor.
    } else {
      Serial.println("Código no encontrado en este perfil.");
    }

    delay(500);
  }
}

  // Lectura Bluetooth para actualización de JSON, siemre y cuando este habilitado el canal.
  if (SerialBT.available()) {
    //Leera el JSON hasta que encuentre un salto de linea (\n).
    String jsonRecibido = SerialBT.readStringUntil('\n');
    //Mensaje de aviso.
    //Serial.println("JSON recibido por Bluetooth:");
    //Serial.println(jsonRecibido);
    //Utiliza la función previa con la información que llego.
    guardarNuevoJSON(jsonRecibido);
  }

}
