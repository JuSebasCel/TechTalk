from machine import Pin
from time import ticks_ms, sleep_ms

# Pines de botones
boton_encendido = Pin(6, Pin.IN, Pin.PULL_UP)
boton_perfil = Pin(7, Pin.IN, Pin.PULL_UP)

# Pines de los dedos
dedo_indice = Pin(2, Pin.IN, Pin.PULL_UP)
dedo_medio = Pin(3, Pin.IN, Pin.PULL_UP)
dedo_anular = Pin(4, Pin.IN, Pin.PULL_UP)
dedo_menique = Pin(5, Pin.IN, Pin.PULL_UP)

sistema_activo = True
perfil_actual = 1

ultimo_cambio_encendido = 0
ultimo_cambio_perfil = 0

def leer_dedos():
    i = not dedo_indice.value()
    m = not dedo_medio.value()
    a = not dedo_anular.value()
    me = not dedo_menique.value()
    return i, m, a, me

while True:
    ahora = ticks_ms()

    # --- Botón de encendido/apagado ---
    if not boton_encendido.value() and ahora - ultimo_cambio_encendido > 500:
        sistema_activo = not sistema_activo
        ultimo_cambio_encendido = ahora
        print("Sistema", "Activado" if sistema_activo else "Desactivado")

    # --- Botón de cambio de perfil ---
    if not boton_perfil.value() and ahora - ultimo_cambio_perfil > 500:
        perfil_actual += 1
        if perfil_actual > 4:
            perfil_actual = 1
        ultimo_cambio_perfil = ahora
        print("Perfil actual:", perfil_actual)

    if not sistema_activo:
        sleep_ms(200)
        continue

    # Lectura de dedos
    i, m, a, me = leer_dedos()

    # Combinaciones
    comb1000 = i and not m and not a and not me
    comb0100 = not i and m and not a and not me
    comb0010 = not i and not m and a and not me
    comb0001 = not i and not m and not a and me

    comb1100 = i and m and not a and not me
    comb1010 = i and not m and a and not me
    comb1001 = i and not m and not a and me
    comb0110 = not i and m and a and not me
    comb0101 = not i and m and not a and me
    comb0011 = not i and not m and a and me

    comb1110 = i and m and a and not me
    comb1101 = i and m and not a and me
    comb1011 = i and not m and a and me
    comb0111 = not i and m and a and me
    comb1111 = i and m and a and me

    # Perfil 1
    if perfil_actual == 1:
        if comb1000: print("Hola")
        if comb0100: print("Gracias")
        if comb0010: print("Por favor")
        if comb0001: print("Sí")
        if comb1100: print("No")
        if comb1010: print("Ayuda")
        if comb1001: print("Me duele")
        if comb0110: print("Llama a alguien")
        if comb0101: print("Tengo hambre")
        if comb0011: print("Tengo sed")
        if comb1110: print("Vamos")
        if comb1101: print("Espera")
        if comb1011: print("Allí")
        if comb0111: print("Estoy perdido")
        if comb1111: print("Saludos a todos")

    # Perfil 2
    elif perfil_actual == 2:
        if comb1000: print("¿Cuál es la tarea?")
        if comb0100: print("Soy TechTalk")
        if comb0010: print("Repite por favor")
        if comb0001: print("¿Qué página?")
        if comb1100: print("Estoy en clase")
        if comb1010: print("Necesito ayuda con esto")
        if comb1001: print("Profe, tengo una duda")
        if comb0110: print("¿A qué hora salimos?")
        if comb0101: print("¿Hay examen?")
        if comb0011: print("¿Es obligatorio?")
        if comb1110: print("Silencio, por favor")
        if comb1101: print("¿Hay tarea?")
        if comb1011: print("Ya terminé")
        if comb0111: print("No he acabado")
        if comb1111: print("Hola Soy Mariana Mahecha Villanueva")

    # Perfil 3
    elif perfil_actual == 3:
        if comb1000: print("Enciende la luz")
        if comb0100: print("Apaga el televisor")
        if comb0010: print("Tengo frío")
        if comb0001: print("Tengo calor")
        if comb1100: print("Sube el volumen")
        if comb1010: print("Baja el volumen")
        if comb1001: print("Abre la ventana")
        if comb0110: print("Cierra la puerta")
        if comb0101: print("Quiero ver una película")
        if comb0011: print("Pon música")
        if comb1110: print("Haz silencio")
        if comb1101: print("No me molesten")
        if comb1011: print("Estoy ocupado")
        if comb0111: print("Estoy disponible")
        if comb1111: print("Hora de dormir")

    # Perfil 4
    elif perfil_actual == 4:
        if comb1000: print("Estoy feliz")
        if comb0100: print("Estoy triste")
        if comb0010: print("Tengo miedo")
        if comb0001: print("Estoy cansado")
        if comb1100: print("Estoy aburrido")
        if comb1010: print("Estoy emocionado")
        if comb1001: print("Estoy nervioso")
        if comb0110: print("Estoy tranquilo")
        if comb0101: print("Estoy enojado")
        if comb0011: print("Estoy confundido")
        if comb1110: print("Me siento bien")
        if comb1101: print("No me siento bien")
        if comb1011: print("Estoy solo")
        if comb0111: print("Estoy acompañado")
        if comb1111: print("Quiero hablar")

    sleep_ms(200)
