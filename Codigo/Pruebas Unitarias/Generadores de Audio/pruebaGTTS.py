import os
import time
from gtts import gTTS
from playsound import playsound

# --------------------------------------
# MODO DE PRUEBA MANUAL: Escribes frases por consola (input)
# Cuando conectes el guante real, comenta esta sección
modo_prueba = True
# --------------------------------------

# --------------------------------------
# MODO SERIAL (solo si tienes el guante conectado)
"""
modo_prueba = False
import serial
ser = serial.Serial('COM6', 9600, timeout=1)
print("✅ Esperando indicación del guante...")
"""
# --------------------------------------

# Carpeta donde se guardarán los audios generados
carpeta_audios = "audiosGoogle"
os.makedirs(carpeta_audios, exist_ok=True)

ultima_frase = ""

def generar_y_reproducir_audio(frase):
    # Limpiar la frase para crear un nombre de archivo válido
    nombre_archivo = frase.replace(" ", "_").replace("¿", "").replace("?", "").replace("¡", "").replace("!", "")
    nombre_archivo = ''.join(c for c in nombre_archivo if c.isalnum() or c == '_')
    ruta_audio = os.path.join(carpeta_audios, f"{nombre_archivo}.mp3")

    if not os.path.exists(ruta_audio):
        print(f"🎙️ Generando nuevo audio para: {frase}")
        tts = gTTS(text=frase, lang='es', tld='com.mx')
        tts.save(ruta_audio)
    else:
        print(f"🔁 Reproduciendo audio ya existente para: {frase}")

    playsound(ruta_audio)

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
