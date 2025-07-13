from machine import Pin
from time import ticks_ms, sleep_ms
import ujson as json
import os
from bluetooth import BLE
import bluetooth

from micropython import const

# -------------------- Configuración de Pines --------------------
dedos = [Pin(14, Pin.IN, Pin.PULL_UP),
         Pin(27, Pin.IN, Pin.PULL_UP),
         Pin(26, Pin.IN, Pin.PULL_UP),
         Pin(25, Pin.IN, Pin.PULL_UP)]

boton_encendido = Pin(4, Pin.IN, Pin.PULL_UP)
boton_perfil = Pin(5, Pin.IN, Pin.PULL_UP)
led = Pin(23, Pin.OUT)

sistema_activo = True
perfil_actual = 1

ultimo_cambio_encendido = 0
ultimo_cambio_perfil = 0

actualizando = False
tiempo_anterior_parpadeo = 0
estado_led_parpadeo = False

frases = {}

# -------------------- Bluetooth Serial (MicroPython) --------------------
from ble_simple_peripheral import BLESimplePeripheral
ble = bluetooth.BLE()
ble.active(True)
bt = BLESimplePeripheral(ble)

# -------------------- Función para cargar JSON --------------------
def cargar_frases():
    global frases
    try:
        with open("/frases.json", "r") as f:
            frases = json.load(f)
        print("Frases cargadas correctamente.")
    except Exception as e:
        print("Error al cargar frases.json:", e)
        frases = {}

# -------------------- Obtener código de 4 bits --------------------
def obtener_codigo():
    return ''.join(['1' if not dedo.value() else '0' for dedo in dedos])

# -------------------- Guardar nuevo JSON desde Bluetooth --------------------
def guardar_nuevo_json(contenido):
    global actualizando
    actualizando = True
    sleep_ms(200)

    try:
        with open("/data/frases.json", "w") as f:
            f.write(contenido)
        print("Nuevo JSON guardado desde Bluetooth.")
        cargar_frases()
    except Exception as e:
        print("Error al guardar JSON:", e)

    actualizando = False
    led.value(1 if sistema_activo else 0)

# -------------------- SETUP --------------------
led.value(1)

# Montar sistema de archivos (ya está montado en MicroPython normalmente)
cargar_frases()

# -------------------- LOOP --------------------
while True:
    ahora = ticks_ms()

    # --- Botón de encendido ---
    if not boton_encendido.value() and ahora - ultimo_cambio_encendido > 500:
        sistema_activo = not sistema_activo
        ultimo_cambio_encendido = ahora
        led.value(1 if sistema_activo else 0)
        print("Sistema", "Activado" if sistema_activo else "Desactivado")

    # --- Botón de perfil ---
    if not boton_perfil.value() and ahora - ultimo_cambio_perfil > 500:
        perfil_actual += 1
        clave_nueva = f"perfil{perfil_actual}"
        if clave_nueva not in frases:
            perfil_actual = 1
        ultimo_cambio_perfil = ahora
        print("Perfil actual:", perfil_actual)

    if not sistema_activo:
        sleep_ms(100)
        continue

    # --- Lectura de código ---
    codigo = obtener_codigo()
    if codigo != "0000":
        clave_perfil = f"perfil{perfil_actual}"
        print("Código detectado:", codigo)

        if clave_perfil in frases and codigo in frases[clave_perfil]:
            frase = frases[clave_perfil][codigo]
            print("Frase:", frase)
            bt.send(frase + "\n")
        else:
            print("Código no encontrado.")
            # bt.send("Código no encontrado.\n")  # opcional

        sleep_ms(500)

    # --- Lectura de datos por Bluetooth ---
    if bt.is_connected():
        data = bt.read()
        if data:
            try:
                json_recibido = data.decode("utf-8").strip()
                print("JSON recibido por Bluetooth:")
                print(json_recibido)
                guardar_nuevo_json(json_recibido)
            except Exception as e:
                print("Error procesando JSON recibido:", e)

    # --- Parpadeo del LED durante actualización ---
    if actualizando:
        if ticks_ms() - tiempo_anterior_parpadeo > 200:
            tiempo_anterior_parpadeo = ticks_ms()
            estado_led_parpadeo = not estado_led_parpadeo
            led.value(estado_led_parpadeo)

    sleep_ms(50)
