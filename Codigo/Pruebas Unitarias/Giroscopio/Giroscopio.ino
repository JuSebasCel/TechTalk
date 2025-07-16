#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>

Adafruit_MPU6050 mpu;

void setup() {
  Serial.begin(9600);
  
  // Inicia el bus I2C (puedes especificar pines aquí si los predeterminados no sirven)
  Wire.begin(21, 22); // SDA = GPIO 21, SCL = GPIO 22

  // Espera a que el MPU6050 se conecte
  if (!mpu.begin()) {
    Serial.println("No se encontró el MPU6050. Verifica cableado.");
    while (1) {
      delay(10);
    }
  }

  Serial.println("MPU6050 encontrado");
  
  // Opcional: configura rangos
  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

  delay(100);
}

void loop() {
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  Serial.print("Aceleración [m/s^2]: X=");
  Serial.print(a.acceleration.x);
  Serial.print(" Y=");
  Serial.print(a.acceleration.y);
  Serial.print(" Z=");
  Serial.println(a.acceleration.z);

  Serial.print("Giroscopio [rad/s]: X=");
  Serial.print(g.gyro.x);
  Serial.print(" Y=");
  Serial.print(g.gyro.y);
  Serial.print(" Z=");
  Serial.println(g.gyro.z);

  Serial.print("Temperatura [°C]: ");
  Serial.println(temp.temperature);

  Serial.println("------");
  delay(500);
}
