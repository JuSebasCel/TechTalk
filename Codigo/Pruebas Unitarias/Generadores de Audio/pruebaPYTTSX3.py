import os
import time
import pyttsx3

# --------------------------------------
# MODO DE PRUEBA MANUAL: Escribes frases por consola (input)
modo_prueba = True  # Cámbialo a False cuando uses el guante
# --------------------------------------

# --------------------------------------
# MODO SERIAL (si tienes el guante conectado)
"""
modo_prueba = False
import serial
ser = serial.Serial('COM6', 9600, timeout=1)
print("✅ Esperando indicación del guante...")
"""
# --------------------------------------

# Carpeta donde se guardarán los audios generados
carpeta_audios = "audiosPY"
os.makedirs(carpeta_audios, exist_ok=True)

# Configura el motor de voz
voz = pyttsx3.init()
voz.setProperty('rate', 150)
voz.setProperty('volume', 1.0)

# Si quieres cambiar la voz (opcional)
# for v in voz.getProperty('voices'):
#     print(v.id)  # Para ver las opciones
# voz.setProperty('voice', alguna_voz.id)

ultima_frase = ""

def limpiar_nombre_archivo(frase):
    nombre = frase.replace(" ", "_").replace("¿", "").replace("?", "").replace("¡", "").replace("!", "")
    nombre = ''.join(c for c in nombre if c.isalnum() or c == '_')
    return nombre + ".wav"

def generar_y_reproducir_audio(frase):
    nombre_archivo = limpiar_nombre_archivo(frase)
    ruta_audio = os.path.join(carpeta_audios, nombre_archivo)

    if not os.path.exists(ruta_audio):
        print(f"🎙️ Generando nuevo audio con pyttsx3 para: {frase}")
        voz.save_to_file(frase, ruta_audio)
        voz.runAndWait()
    else:
        print(f"🔁 Reproduciendo audio ya existente: {frase}")

    # Reproducir el archivo generado
    try:
        import playsound
        playsound.playsound(ruta_audio)
    except:
        os.system(f'start "" "{ruta_audio}"')  # Alternativa si playsound falla

# Bucle principal
while True:
    if modo_prueba:
        frase = input("✍️ Ingresa la frase (o escribe 'salir' para terminar): ").strip()
        if frase.lower() == "salir":
            print("🚪 Saliendo del modo prueba.")
            break
    else:
        if ser.in_waiting > 0:
            try:
                frase = ser.readline().decode('utf-8').strip()
            except UnicodeDecodeError:
                continue
        else:
            time.sleep(0.1)
            continue

    if frase and frase != ultima_frase:
        generar_y_reproducir_audio(frase)
        ultima_frase = frase
