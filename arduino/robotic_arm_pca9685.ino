#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>
#include <SoftwareSerial.h>

Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver(0x40);

SoftwareSerial bluetooth(10, 11);

#define SERVO_MIN 150
#define SERVO_MAX 600

#define CH_J1 0
#define CH_J2 1
#define CH_J3 2
#define CH_J4 3
#define CH_J5 4
#define CH_J6 5

void setServo(int channel, int angle) {
  angle = constrain(angle, 0, 180);
  int pulse = map(angle, 0, 180, SERVO_MIN, SERVO_MAX);
  pwm.setPWM(channel, 0, pulse);
}

void processCommand(String command) {
  command.trim();
  if (command.length() == 0) return;

  Serial.print("Received: ");
  Serial.println(command);

  int separator = command.indexOf(':');
  if (separator == -1) return;

  String joint = command.substring(0, separator);
  int value = command.substring(separator + 1).toInt();
  joint.toUpperCase();

  if (joint == "J1") {
    value = constrain(value, 0, 180);
    setServo(CH_J1, value);
    Serial.print("J1: ");
    Serial.println(value);
  } else if (joint == "J2") {
    value = constrain(value, 100, 150);
    setServo(CH_J2, value);
    Serial.print("J2: ");
    Serial.println(value);
  } else if (joint == "J3") {
    value = constrain(value, 0, 90);
    setServo(CH_J3, value);
    Serial.print("J3: ");
    Serial.println(value);
  } else if (joint == "J4") {
    value = constrain(value, 0, 180);
    setServo(CH_J4, value);
    Serial.print("J4: ");
    Serial.println(value);
  } else if (joint == "J5") {
    value = constrain(value, 0, 180);
    setServo(CH_J5, value);
    Serial.print("J5: ");
    Serial.println(value);
  } else if (joint == "J6") {
    value = constrain(value, 0, 90);
    setServo(CH_J6, value);
    Serial.print("J6: ");
    Serial.println(value);
  } else if (joint == "STOP") {
    for (int i = 0; i < 6; i++) {
      pwm.setPin(i, 0, false);
    }
    Serial.println("ALL SERVOS STOPPED");
  }
}

void setup() {
  Serial.begin(9600);
  bluetooth.begin(9600);

  pwm.begin();
  pwm.setPWMFreq(50);

  setServo(CH_J1, 90);
  setServo(CH_J2, 100);
  setServo(CH_J3, 0);
  setServo(CH_J4, 0);
  setServo(CH_J5, 0);
  setServo(CH_J6, 0);

  Serial.println("Robotic Arm Ready");
  bluetooth.println("ROBOT_READY");
}

void loop() {
  if (bluetooth.available()) {
    String command = bluetooth.readStringUntil('\n');
    processCommand(command);
  }

  if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    processCommand(command);
  }
}
