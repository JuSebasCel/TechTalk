# main.py

import machine, ujson, time
from machine import Pin, I2C
from ssd1306 import SSD1306_I2C
from mpu6050 import MPU6050
import bluetooth
from ble_simple_peripheral import BLESimplePeripheral

# Pines
dedos = [Pin(pin, Pin.IN, Pin.PULL_UP) for pin in [14, 27, 26, 25]]
botonEncendido = Pin(4, Pin.IN, Pin.PULL_UP)
botonPerfil = Pin(5, Pin.IN, Pin.PULL_UP)
led = Pin(23, Pin.OUT)

# Variables de sistema
sistemaActivo = True
modoGuia = False
perfilActual = 1
esperandoModoGuia = False
tiempoPresionadoGuia = 0

# OLED
oledActiva = False
try:
    i2c_oled = I2C(0, scl=Pin(19), sda=Pin(18))
    oled = SSD1306_I2C(128, 64, i2c_oled)
    oled.fill(0)
    oled.show()
    oledActiva = True
except:
    print("OLED no detectada")

# MPU6050
zManual = 0
mpuActivo = False
try:
    i2c_mpu = I2C(1, scl=Pin(22), sda=Pin(21))
    mpu = MPU6050(i2c_mpu)
    mpuActivo = True
except:
    print("MPU6050 no detectado")

# BLE
ble = bluetooth.BLE()
sp = BLESimplePeripheral(ble)

# JSON
try:
    with open("/frases_extendido.json") as f:
        frases = ujson.load(f)
except:
    frases = {}

ultimaFrase = ""
tiempoUltimaFrase = 0
mostrandoFrase = False

def mostrarPerfil(perfil):
    if not oledActiva:
        return
    oled.fill(0)
    oled.text("Perfil " + str(perfil), 30, 25)
    oled.show()

def obtenerCodigo():
    global zManual
    codigo = ""
    for dedo in dedos:
        codigo += "1" if dedo.value() == 0 else "0"

    if zManual <= -7:
        codigo += "I"
    elif zManual >= 7:
        codigo += "S"
    else:
        codigo += "N"
    return codigo

def guardarNuevoJSON(texto):
    global frases
    try:
        with open("/frases_extendido.json", "w") as f:
            f.write(texto)
        frases = ujson.loads(texto)
        print("Nuevo JSON guardado")
    except Exception as e:
        print("Error guardando JSON:", e)

def mostrarFrase(frase):
    global ultimaFrase, mostrandoFrase, tiempoUltimaFrase
    if not oledActiva or frase == ultimaFrase:
        return

    ultimaFrase = frase
    mostrandoFrase = True
    tiempoUltimaFrase = time.ticks_ms()

    oled.fill(0)
    if len(frase) * 8 <= 128:
        x = (128 - len(frase) * 8) // 2
        oled.text(frase, x, 20)
        oled.text("Perfil " + str(perfilActual), 25, 50)
        oled.show()
    else:
        for _ in range(2):
            for x in range(128, -len(frase)*8, -2):
                oled.fill(0)
                oled.text(frase, x, 20)
                oled.text("Perfil " + str(perfilActual), 25, 50)
                oled.show()
                time.sleep(0.01)

# Setup inicial
led.value(1)
mostrarPerfil(perfilActual)
ultimoCambioPerfil = time.ticks_ms()

while True:
    ahora = time.ticks_ms()

    # Leer acelerómetro
    if mpuActivo:
        zManual = round(mpu.get_values()['AcZ'])

    # Pulsación botón encendido
    if botonEncendido.value() == 0 and not esperandoModoGuia:
        esperandoModoGuia = True
        tiempoPresionadoGuia = ahora

    if botonEncendido.value() == 1 and esperandoModoGuia:
        duracion = time.ticks_diff(ahora, tiempoPresionadoGuia)
        esperandoModoGuia = False

        if duracion >= 5000:
            modoGuia = not modoGuia
            print("Modo Guía:", "ON" if modoGuia else "OFF")
            if oledActiva:
                oled.fill(0)
                oled.text("Guia ON" if modoGuia else "Guia OFF", 10, 25)
                oled.show()
                time.sleep(1)
                mostrarPerfil(perfilActual)
        elif duracion >= 100 and duracion < 1500:
            sistemaActivo = not sistemaActivo
            led.value(1 if sistemaActivo else 0)
            print("Sistema:", "Activo" if sistemaActivo else "Inactivo")
            mostrarPerfil(perfilActual)

    # Cambiar perfil
    if botonPerfil.value() == 0 and time.ticks_diff(ahora, ultimoCambioPerfil) > 300:
        perfilActual += 1
        if not ("perfil" + str(perfilActual) in frases):
            perfilActual = 1
        mostrarPerfil(perfilActual)
        print("Perfil actual:", perfilActual)
        ultimoCambioPerfil = ahora

    if not sistemaActivo:
        continue

    codigo = obtenerCodigo()
    if not codigo.startswith("0000") and codigo[-1] in "INS":
        clave = "perfil" + str(perfilActual)
        if clave in frases and codigo in frases[clave]:
            frase = frases[clave][codigo]
            print("Frase:", frase)
            sp.send(frase + "\n")
            if modoGuia:
                mostrarFrase(frase)
        else:
            print("Código no encontrado")

        time.sleep(0.5)

    # Leer BLE
    if sp.is_connected():
        if sp.rx_available():
            entrada = sp.read().decode("utf-8")
            guardarNuevoJSON(entrada)

    # Ocultar frase si ha pasado tiempo
    if mostrandoFrase and time.ticks_diff(time.ticks_ms(), tiempoUltimaFrase) > 3000:
        mostrarPerfil(perfilActual)
        mostrandoFrase = False
