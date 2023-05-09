import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';
import 'package:mass_alg_generator/mixins/accelerometer.dart';
import 'package:mass_alg_generator/utils/algorithm_utils.dart';
// import project ffibridge.dart?

mixin AccelerometerMonitoringMixin<T extends StatefulWidget> on State<T> {
  Accelerometer _accelerometer = Accelerometer((x, y, z) => null);
  bool _isListening = false;
  AlgorithmUtils _algorithmUtils = AlgorithmUtils();

  void startAccelerometer() {
    _isListening = true;
    _accelerometer = Accelerometer(_processAccelerometerData);
    FFIBridge.set_phonemovedflag(0);

    _accelerometer.startListening();
    Wakelock.enable();
  }

  void stopAccelerometer() {
    _isListening = false;
    _accelerometer.stopListening();
    Wakelock.disable();
  }

  void _processAccelerometerData(double x, double y, double z) async {
    if (_isListening) {
      if (FFIBridge.get_phonemovedflag() == 1) {
        phoneMoved(); // Call the overridden phoneMoved method
        FFIBridge.set_phonemovedflag(0);
        return;
      }
      await _algorithmUtils.mass_alg_step_accel_log(x, y, z);
      onMassAlgStep(); //optional method to override
    }
  }

  // This method should be overridden in the classes using the mixin
  @protected
  void phoneMoved();

  // This method can be overridden in the classes using the mixin
  @protected
  void onMassAlgStep() {}
}
