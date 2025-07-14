import os
import time
import asyncio
import edge_tts
from playsound import playsound

# --------------------------------------
# MODO DE PRUEBA MANUAL: Escribes frases por consola (input)
# Cuando conectes el guante real, comenta esta sección
modo_prueba = True
# --------------------------------------

# --------------------------------------
# MODO SERIAL (descomenta esto si ya tienes el guante)
"""
modo_prueba = False
import serial
ser = serial.Serial('COM6', 9600, timeout=1)
print("✅ Esperando indicación del guante...")
"""
# --------------------------------------

# Carpeta donde se guardarán los audios generados
carpeta_audios = "audiosEdge"
os.makedirs(carpeta_audios, exist_ok=True)

ultima_frase = ""

async def generar_audio_edge_tts(frase, ruta_audio):
    communicate = edge_tts.Communicate(text=frase, voice="es-MX-DaliaNeural")  # Puedes probar también "es-CO-GonzaloNeural"
    await communicate.save(ruta_audio)

def limpiar_nombre_archivo(frase):
    nombre = frase.replace(" ", "_").replace("¿", "").replace("?", "").replace("¡", "").replace("!", "")
    nombre = ''.join(c for c in nombre if c.isalnum() or c == '_')
    return nombre + ".mp3"

def generar_y_reproducir_audio(frase):
    nombre_archivo = limpiar_nombre_archivo(frase)
    ruta_audio = os.path.join(carpeta_audios, nombre_archivo)

    if not os.path.exists(ruta_audio):
        print(f"🎙️ Generando nuevo audio para: {frase}")
        asyncio.run(generar_audio_edge_tts(frase, ruta_audio))
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
