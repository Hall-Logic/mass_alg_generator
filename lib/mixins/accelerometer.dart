import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

class Accelerometer {
  StreamSubscription? _streamSubscription;
  final Function(double, double, double) onData;

  Accelerometer(this.onData);

  void startListening() {
    _streamSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      final accelX = -event.x / 9.8;
      final accelY = -event.y / 9.8;
      final accelZ = -event.z / 9.8;
      onData(accelX, accelY, accelZ);
    });
  }

  void stopListening() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }
}
