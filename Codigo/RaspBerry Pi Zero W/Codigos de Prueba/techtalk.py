import RPi.GPIO as GPIO
import pyttsx3
import json
import time

# ------------------ Pines GPIO ------------------ #
dedos = [14, 27, 26, 25]      # Pines de los dedos
boton_encendido = 4           # Botón de encendido
boton_perfil = 5              # Botón de cambio de perfil
led = 23                      # LED indicador

# ------------------ Variables de estado ------------------ #
sistema_activo = True
perfil_actual = 1
z_manual = 0  # <<<<<< Aquí defines el valor de Z manualmente: prueba con 7, 0 o -10
frases = {}

# ------------------ Inicializar voz ------------------ #
try:
    voz = pyttsx3.init()
    voz.setProperty('rate', 150)
    voz.setProperty('volume', 1)
    usar_voz = True
except Exception as e:
    print("pyttsx3 no está disponible o falló. Usando solo print().")
    usar_voz = False

# ------------------ Cargar JSON ------------------ #
def cargar_frases():
    global frases
    try:
        with open('frases_extendido.json', 'r') as f:
            frases = json.load(f)
        print("✅ Frases cargadas correctamente.")
    except Exception as e:
        print("❌ Error al cargar frases:", e)
        frases = {}

# ------------------ Obtener código ------------------ #
def obtener_codigo():
    codigo = ''
    for pin in dedos:
        presionado = GPIO.input(pin) == GPIO.LOW
        codigo += '1' if presionado else '0'

    if z_manual <= -7:
        codigo += 'I'
    elif z_manual >= 7:
        codigo += 'S'
    else:
        codigo += 'N'
    return codigo

# ------------------ Decir o imprimir frase ------------------ #
def decir(frase):
    print(f"🗣️ Frase: {frase}")
    if usar_voz:
        voz.say(frase)
        voz.runAndWait()

# ------------------ Configuración GPIO ------------------ #
GPIO.setmode(GPIO.BCM)

for pin in dedos:
    GPIO.setup(pin, GPIO.IN, pull_up_down=GPIO.PUD_UP)

GPIO.setup(boton_encendido, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.setup(boton_perfil, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.setup(led, GPIO.OUT)

GPIO.output(led, GPIO.HIGH)

# ------------------ Cargar datos iniciales ------------------ #
cargar_frases()
print("🔁 Sistema iniciado. Presiona botón de encendido para pausar/activar.")

ultimo_encendido = 0
ultimo_perfil = 0

try:
    while True:
        ahora = time.time()

        # --------- Botón de encendido --------- #
        if GPIO.input(boton_encendido) == GPIO.LOW and ahora - ultimo_encendido > 0.5:
            sistema_activo = not sistema_activo
            GPIO.output(led, GPIO.HIGH if sistema_activo else GPIO.LOW)
            print("✅ Sistema Activado" if sistema_activo else "⛔ Sistema Desactivado")
            ultimo_encendido = ahora

        if not sistema_activo:
            time.sleep(0.1)
            continue

        # --------- Botón de perfil --------- #
        if GPIO.input(boton_perfil) == GPIO.LOW and ahora - ultimo_perfil > 0.5:
            perfil_actual += 1
            clave = f"perfil{perfil_actual}"
            if clave not in frases:
                perfil_actual = 1
            print(f"🎚️ Perfil actual: {perfil_actual}")
            ultimo_perfil = ahora

        # --------- Leer combinación de dedos --------- #
        codigo = obtener_codigo()
        if not codigo.startswith("0000") and codigo[-1] in ['S', 'N', 'I']:
            clave = f"perfil{perfil_actual}"
            if codigo in frases.get(clave, {}):
                decir(frases[clave][codigo])
                time.sleep(0.5)
            else:
                print(f"❓ Código no encontrado: {codigo}")
                time.sleep(0.3)

except KeyboardInterrupt:
    print("⏹️ Programa interrumpido.")
    GPIO.cleanup()

