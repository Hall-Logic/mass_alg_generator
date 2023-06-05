import 'dart:async';

import 'package:flutter_sensors/flutter_sensors.dart';

class Accelerometer {
  StreamSubscription? _streamSubscription;
  final Function(double, double, double) onData;

  Accelerometer(this.onData);

  Future<void> startListening() async {
    final stream = await SensorManager().sensorUpdates(
      sensorId: Sensors.ACCELEROMETER,
      interval: Sensors.SENSOR_DELAY_GAME,
    );
    _streamSubscription = stream.listen((sensorEvent) {
      final accelX = -sensorEvent.data[0] / 9.8;
      final accelY = -sensorEvent.data[1] / 9.8;
      final accelZ = -sensorEvent.data[2] / 9.8;
      onData(accelX, accelY, accelZ);
    });
  }

  void stopListening() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }
}
