import json
import os
from gtts import gTTS
import re

with open("frases_extendido.json", "r", encoding="utf-8") as f:
    frases = json.load(f)

carpeta = "audio_cache"
os.makedirs(carpeta, exist_ok=True)

def nombre_mp3(frase):
    return os.path.join(carpeta, re.sub(r'\W+', '_', frase.strip().lower()) + ".mp3")

for perfil in frases:
    for codigo in frases[perfil]:
        frase = frases[perfil][codigo]
        ruta = nombre_mp3(frase)
        if not os.path.exists(ruta):
            print(f"🎤 Generando: {frase}")
            tts = gTTS(text=frase, lang='es')
            tts.save(ruta)

print("✅ Todos los audios fueron generados.")
