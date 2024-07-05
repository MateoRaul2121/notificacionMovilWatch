#include <SoftwareSerial.h>

SoftwareSerial BTSerial(2, 3); // RX, TX

const int ledPin = 9;
float currentIntensity = 1.0;

void setup() {
  pinMode(ledPin, OUTPUT);
  BTSerial.begin(9600);
  Serial.begin(9600); // Para depuración

  // Apagar el LED al inicio
  analogWrite(ledPin, 0);
}

void loop() {
  if (BTSerial.available() > 0) {
    String receivedString = BTSerial.readStringUntil('\n');
    Serial.println(receivedString); // Para depuración

    if (receivedString.startsWith("I")) {
      float intensityValue = receivedString.substring(1).toFloat() / 100.0;
      setIntensity(intensityValue);
      Serial.println("Intensidad ajustada");
    } else if (receivedString == "ON") {
      setIntensity(1.0); // Encender el LED con máxima intensidad
      Serial.println("LED Encendido");
    } else if (receivedString == "OFF") {
      setIntensity(0.0); // Apagar el LED
      Serial.println("LED Apagado");
    }
  }
}

void setIntensity(float intensity) {
  currentIntensity = intensity;
  applyIntensity();
}

void applyIntensity() {
  analogWrite(ledPin, 255 * currentIntensity);
}
