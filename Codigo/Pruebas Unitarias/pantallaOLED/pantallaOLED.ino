#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

#define SDA_PIN 18
#define SCL_PIN 19

String mensaje = "   Este es un mensaje largo que se desplaza   ";
int desplazamiento = 0;

void setup() {
  Serial.begin(9600);
  Wire.begin(SDA_PIN, SCL_PIN);

  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("Pantalla no detectada"));
    while (true);
  }

  display.setTextSize(2); // Tamaño grande
  display.setTextColor(SSD1306_WHITE);
  display.setTextWrap(false); // 🔒 evita saltos de línea
}

void loop() {
  display.clearDisplay();

  int char_width = 12; // Tamaño de cada carácter en tamaño 2
  int max_chars = SCREEN_WIDTH / char_width;

  int char_offset = desplazamiento / char_width;
  int pixel_offset = desplazamiento % char_width;

  String visible = mensaje.substring(char_offset);
  if (visible.length() > max_chars + 1) {
    visible = visible.substring(0, max_chars + 1);
  }

  int y = (SCREEN_HEIGHT - 16) / 2; // 16px alto para tamaño 2
  display.setCursor(-pixel_offset, y);

  // Usamos write() para evitar saltos de línea automáticos
  for (int i = 0; i < visible.length(); i++) {
    display.write(visible[i]);
  }

  display.display();

  delay(10); // ⏩ velocidad ajustada, más rápida pero fluida
  desplazamiento++;

  int total_pixels = mensaje.length() * char_width;
  if (desplazamiento > total_pixels) {
    desplazamiento = 0;
  }
}
