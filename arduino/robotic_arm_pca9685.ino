#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>
#include <SoftwareSerial.h>

Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver(0x40);
SoftwareSerial bluetooth(10, 11);

#define SERVO_MIN 150
#define SERVO_MAX 600

struct Joint {
  uint8_t minAngle;
  uint8_t maxAngle;
  uint8_t defaultAngle;
};

const Joint joints[6] = {
  {0, 180, 90},
  {100, 150, 100},
  {0, 90, 0},
  {0, 180, 0},
  {0, 180, 0},
  {0, 90, 0}
};

void setServo(uint8_t ch, int angle) {
  angle = constrain(angle, 0, 180);
  int pulse = map(angle, 0, 180, SERVO_MIN, SERVO_MAX);
  pwm.setPWM(ch, 0, pulse);
}

void processCommand(String cmd) {
  cmd.trim();
  if (cmd.length() == 0) return;

  if (cmd.startsWith("STOP")) {
    for (uint8_t i = 0; i < 6; i++) {
      pwm.setPin(i, 0, false);
    }
    Serial.println(F("ALL SERVOS STOPPED"));
    return;
  }

  if (cmd.length() >= 4 && (cmd[0] == 'J' || cmd[0] == 'j') && cmd[2] == ':') {
    int idx = cmd[1] - '1';
    if (idx >= 0 && idx < 6) {
      int val = constrain(cmd.substring(3).toInt(), joints[idx].minAngle, joints[idx].maxAngle);
      setServo(idx, val);
      Serial.print(F("J")); Serial.print(idx + 1); Serial.print(F(": ")); Serial.println(val);
    }
  }
}

void setup() {
  Serial.begin(9600);
  bluetooth.begin(9600);

  pwm.begin();
  pwm.setPWMFreq(50);

  for (uint8_t i = 0; i < 6; i++) {
    setServo(i, joints[i].defaultAngle);
  }

  Serial.println(F("Robotic Arm Ready"));
  bluetooth.println(F("ROBOT_READY"));
}

void loop() {
  if (bluetooth.available()) {
    processCommand(bluetooth.readStringUntil('\n'));
  }

  if (Serial.available()) {
    processCommand(Serial.readStringUntil('\n'));
  }
}
