from gtts import gTTS
import os

frase = "Hola, esta es una voz generada con Google Text to Speech"

tts = gTTS(text=frase, lang='es')
tts.save("frase.mp3")
os.system("mpg123 frase.mp3")

