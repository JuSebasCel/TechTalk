const int botonEncendido = 6;
const int botonPerfil = 7;

bool sistemaActivo = true;
int perfilActual = 1;

unsigned long ultimoCambioEncendido = 0;
unsigned long ultimoCambioPerfil = 0;

void setup() {
  pinMode(2, INPUT_PULLUP); // Índice
  pinMode(3, INPUT_PULLUP); // Medio
  pinMode(4, INPUT_PULLUP); // Anular
  pinMode(5, INPUT_PULLUP); // Meñique

  pinMode(botonEncendido, INPUT_PULLUP);
  pinMode(botonPerfil, INPUT_PULLUP);

  Serial.begin(9600);
}

void loop() {
  unsigned long ahora = millis();

  // --- Botón de encendido/apagado ---
  if (digitalRead(botonEncendido) == LOW && ahora - ultimoCambioEncendido > 500) {
    sistemaActivo = !sistemaActivo;
    ultimoCambioEncendido = ahora;
    Serial.print("Sistema ");
    Serial.println(sistemaActivo ? "Activado" : "Desactivado");
  }

  // --- Botón de cambio de perfil ---
  if (digitalRead(botonPerfil) == LOW && ahora - ultimoCambioPerfil > 500) {
    perfilActual++;
    if (perfilActual > 4) perfilActual = 1;
    ultimoCambioPerfil = ahora;
    Serial.print("Perfil actual: ");
    Serial.println(perfilActual);
  }

  if (!sistemaActivo) return;

  // Detección de dedos
  bool i = !digitalRead(2); // índice
  bool m = !digitalRead(3); // medio
  bool a = !digitalRead(4); // anular
  bool me = !digitalRead(5); // meñique

  // Combinaciones
  bool comb1000 = i && !m && !a && !me;
  bool comb0100 = !i && m && !a && !me;
  bool comb0010 = !i && !m && a && !me;
  bool comb0001 = !i && !m && !a && me;

  bool comb1100 = i && m && !a && !me;
  bool comb1010 = i && !m && a && !me;
  bool comb1001 = i && !m && !a && me;
  bool comb0110 = !i && m && a && !me;
  bool comb0101 = !i && m && !a && me;
  bool comb0011 = !i && !m && a && me;

  bool comb1110 = i && m && a && !me;
  bool comb1101 = i && m && !a && me;
  bool comb1011 = i && !m && a && me;
  bool comb0111 = !i && m && a && me;
  bool comb1111 = i && m && a && me;

  // Selección de perfil
  if (perfilActual == 1) {
    if (comb1000) Serial.println("Hola");
    if (comb0100) Serial.println("Gracias");
    if (comb0010) Serial.println("Por favor");
    if (comb0001) Serial.println("Sí");
    if (comb1100) Serial.println("No");
    if (comb1010) Serial.println("Ayuda");
    if (comb1001) Serial.println("Me duele");
    if (comb0110) Serial.println("Llama a alguien");
    if (comb0101) Serial.println("Tengo hambre");
    if (comb0011) Serial.println("Tengo sed");
    if (comb1110) Serial.println("Vamos");
    if (comb1101) Serial.println("Espera");
    if (comb1011) Serial.println("Allí");
    if (comb0111) Serial.println("Estoy perdido");
    if (comb1111) Serial.println("Saludos a todos");
  }

  else if (perfilActual == 2) {
    if (comb1000) Serial.println("¿Cuál es la tarea?");
    if (comb0100) Serial.println("Soy TechTalk");
    if (comb0010) Serial.println("Repite por favor");
    if (comb0001) Serial.println("¿Qué página?");
    if (comb1100) Serial.println("Estoy en clase");
    if (comb1010) Serial.println("Necesito ayuda con esto");
    if (comb1001) Serial.println("Profe, tengo una duda");
    if (comb0110) Serial.println("¿A qué hora salimos?");
    if (comb0101) Serial.println("¿Hay examen?");
    if (comb0011) Serial.println("¿Es obligatorio?");
    if (comb1110) Serial.println("Silencio, por favor");
    if (comb1101) Serial.println("¿Hay tarea?");
    if (comb1011) Serial.println("Ya terminé");
    if (comb0111) Serial.println("No he acabado");
    if (comb1111) Serial.println("Hola Soy Mariana Mahecha Villanueva");
  }

  else if (perfilActual == 3) {
    if (comb1000) Serial.println("Enciende la luz");
    if (comb0100) Serial.println("Apaga el televisor");
    if (comb0010) Serial.println("Tengo frío");
    if (comb0001) Serial.println("Tengo calor");
    if (comb1100) Serial.println("Sube el volumen");
    if (comb1010) Serial.println("Baja el volumen");
    if (comb1001) Serial.println("Abre la ventana");
    if (comb0110) Serial.println("Cierra la puerta");
    if (comb0101) Serial.println("Quiero ver una película");
    if (comb0011) Serial.println("Pon música");
    if (comb1110) Serial.println("Haz silencio");
    if (comb1101) Serial.println("No me molesten");
    if (comb1011) Serial.println("Estoy ocupado");
    if (comb0111) Serial.println("Estoy disponible");
    if (comb1111) Serial.println("Hora de dormir");
  }

  else if (perfilActual == 4) {
    if (comb1000) Serial.println("Estoy feliz");
    if (comb0100) Serial.println("Estoy triste");
    if (comb0010) Serial.println("Tengo miedo");
    if (comb0001) Serial.println("Estoy cansado");
    if (comb1100) Serial.println("Estoy aburrido");
    if (comb1010) Serial.println("Estoy emocionado");
    if (comb1001) Serial.println("Estoy nervioso");
    if (comb0110) Serial.println("Estoy tranquilo");
    if (comb0101) Serial.println("Estoy enojado");
    if (comb0011) Serial.println("Estoy confundido");
    if (comb1110) Serial.println("Me siento bien");
    if (comb1101) Serial.println("No me siento bien");
    if (comb1011) Serial.println("Estoy solo");
    if (comb0111) Serial.println("Estoy acompañado");
    if (comb1111) Serial.println("Quiero hablar");
  }

  delay(200);
}

