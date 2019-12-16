/* This example shows how to get single-shot range
 measurements from the VL53L0X. The sensor can optionally be
 configured with different ranging profiles, as described in
 the VL53L0X API user manual, to get better performance for
 a certain application. This code is based on the four
 "SingleRanging" examples in the VL53L0X API.

 The range readings are in units of mm. */

#include <Wire.h>
#include <VL53L0X.h>
#include<Servo.h>

long duration;
int distance;
int servoAngle = 15;
bool servoInc = true;
long startMil;
Servo servo;

VL53L0X sensor;


// Uncomment this line to use long range mode. This
// increases the sensitivity of the sensor and extends its
// potential range, but increases the likelihood of getting
// an inaccurate reading because of reflections from objects
// other than the intended target. It works best in dark
// conditions.

//#define LONG_RANGE


// Uncomment ONE of these two lines to get
// - higher speed at the cost of lower accuracy OR
// - higher accuracy at the cost of lower speed

//#define HIGH_SPEED
//#define HIGH_ACCURACY


void setup()
{
  
  startMil = millis();
  
  pinMode(13, OUTPUT);
  digitalWrite(13, HIGH); // power for sensor
  
  Serial.begin(9600);
  while (!Serial) { } // wait for serial port to connect. Needed for Leonardo
  Wire.begin();

  sensor.init();
  sensor.setTimeout(500);
  servo.attach(9);

#if defined LONG_RANGE
  // lower the return signal rate limit (default is 0.25 MCPS)
  sensor.setSignalRateLimit(0.1);
  // increase laser pulse periods (defaults are 14 and 10 PCLKs)
  sensor.setVcselPulsePeriod(VL53L0X::VcselPeriodPreRange, 18);
  sensor.setVcselPulsePeriod(VL53L0X::VcselPeriodFinalRange, 14);
#endif

#if defined HIGH_SPEED
  // reduce timing budget to 20 ms (default is about 33 ms)
  sensor.setMeasurementTimingBudget(20000);
#elif defined HIGH_ACCURACY
  // increase timing budget to 200 ms
  sensor.setMeasurementTimingBudget(200000);
#endif
}

void loop()
{
  //Serial.print(sensor.readRangeSingleMillimeters()); // max 8190
  if (sensor.timeoutOccurred()) { Serial.print("TIMEOUT"); }

  if (servoAngle < 15 || servoAngle > 165) { servoInc = !servoInc; }
  servoAngle += servoInc ? 1 : -1;
  
  servo.write(servoAngle);
  distance=sensor.readRangeSingleMillimeters();
  Serial.print(servoAngle);
  Serial.print(",");
  Serial.print(distance);
  Serial.print(".");
  delayAtLeast(50);
}
void delayAtLeast(int mil) {
  int diff = constrain(millis()-startMil, 0, mil);
  delay(mil - diff);
  startMil = millis();
}

