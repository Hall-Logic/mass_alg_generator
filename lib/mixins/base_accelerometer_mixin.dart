// base_accelerometer_monitoring_mixin.dart
import 'package:flutter/material.dart';
import 'package:mass_alg_generator/mixins/accelerometer.dart';
import 'package:wakelock/wakelock.dart';

mixin BaseAccelerometerMixin<T extends StatefulWidget> on State<T> {
  Accelerometer _accelerometer = Accelerometer((x, y, z) => null);
  bool _isListening = false;

  void startAccelerometer() {
    _isListening = true;
    _accelerometer = Accelerometer(_processAccelerometerData);

    onStartAccelerometer();

    _accelerometer.startListening();
    Wakelock.enable();
  }

  void stopAccelerometer() {
    _isListening = false;
    _accelerometer.stopListening();
    Wakelock.disable();

    onStopAccelerometer();
  }

  void _processAccelerometerData(double x, double y, double z) async {
    if (_isListening) {
      onProcessAccelerometerData(x, y, z);
      onMassAlgStep(); // Optional method to override
    }
  }

  @protected
  @optionalTypeArgs
  void onStartAccelerometer() {}

  @protected
  @optionalTypeArgs
  void onStopAccelerometer() {}

  @protected
  @optionalTypeArgs
  void onProcessAccelerometerData(double x, double y, double z) {}

  @protected
  @optionalTypeArgs
  void phoneMoved() {}

  @protected
  @optionalTypeArgs
  void onMassAlgStep() {}
}
