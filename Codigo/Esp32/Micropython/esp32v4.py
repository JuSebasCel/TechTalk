from machine import Pin, I2C
from time import ticks_ms, sleep_ms
import ujson as json
import os
import bluetooth
from ble_simple_peripheral import BLESimplePeripheral
from mpu6050 import MPU6050

# -------------------- Pines --------------------
dedos = [Pin(14, Pin.IN, Pin.PULL_UP),
         Pin(27, Pin.IN, Pin.PULL_UP),
         Pin(26, Pin.IN, Pin.PULL_UP),
         Pin(25, Pin.IN, Pin.PULL_UP)]

boton_encendido = Pin(4, Pin.IN, Pin.PULL_UP)
boton_perfil = Pin(5, Pin.IN, Pin.PULL_UP)
led = Pin(23, Pin.OUT)

# -------------------- Estado inicial --------------------
sistema_activo = True
perfil_actual = 1
ultimo_cambio_encendido = 0
ultimo_cambio_perfil = 0
frases = {}

# -------------------- Bluetooth BLE --------------------
ble = bluetooth.BLE()
ble.active(True)
bt = BLESimplePeripheral(ble)

# -------------------- MPU6050 --------------------
i2c = I2C(0, scl=Pin(22), sda=Pin(21))  # Cambiar si usas otros pines
mpu = MPU6050(i2c)

# -------------------- Cargar JSON --------------------
def cargar_frases():
    global frases
    try:
        with open("/frases_extendido.json", "r") as f:
            frases = json.load(f)
        print("Frases cargadas correctamente.")
    except Exception as e:
        print("Error cargando JSON:", e)
        frases = {}

# -------------------- Obtener código con eje Z --------------------
def obtener_codigo():
    codigo = ''.join(['1' if not dedo.value() else '0' for dedo in dedos])
    z = mpu.get_values()["AcZ"]

    if z <= -7:
        codigo += 'I'
    elif z >= 7:
        codigo += 'S'
    else:
        codigo += 'N'
    return codigo

# -------------------- Guardar nuevo JSON --------------------
def guardar_nuevo_json(contenido):
    try:
        with open("/frases_extendido.json", "w") as f:
            f.write(contenido)
        print("Nuevo JSON guardado.")
        cargar_frases()
    except Exception as e:
        print("Error al guardar JSON:", e)

# -------------------- SETUP inicial --------------------
led.value(1)
cargar_frases()
print("Iniciando MPU6050...")
sleep_ms(100)

# -------------------- LOOP principal --------------------
while True:
    ahora = ticks_ms()

    # Botón de encendido
    if not boton_encendido.value() and ahora - ultimo_cambio_encendido > 500:
        sistema_activo = not sistema_activo
        ultimo_cambio_encendido = ahora
        led.value(1 if sistema_activo else 0)
        print("Sistema", "Activado" if sistema_activo else "Desactivado")

    # Botón de perfil
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

    # Lectura del código
    codigo = obtener_codigo()
    if not codigo.startswith("0000") and codigo[-1] in ['I', 'N', 'S']:
        clave_perfil = f"perfil{perfil_actual}"
        print("Código detectado:", codigo)
        if clave_perfil in frases and codigo in frases[clave_perfil]:
            frase = frases[clave_perfil][codigo]
            print("Frase:", frase)
            bt.send(frase + "\n")
        else:
            print("Código no encontrado en este perfil.")
        sleep_ms(500)

    # Lectura Bluetooth
    if bt.is_connected():
        data = bt.read()
        if data:
            try:
                json_recibido = data.decode("utf-8").strip()
                guardar_nuevo_json(json_recibido)
            except Exception as e:
                print("Error al procesar JSON recibido:", e)

    sleep_ms(50)
