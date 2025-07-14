import serial

try:
    ser = serial.Serial('/dev/rfcomm0', baudrate=9600, timeout=1)
    print("🟢 Escuchando en /dev/rfcomm0...")
    while True:
        if ser.in_waiting:
            msg = ser.readline().decode('utf-8').strip()
            print(f"📥 Recibido: {msg}")
except serial.SerialException as e:
    print("❌ Error:", e)

