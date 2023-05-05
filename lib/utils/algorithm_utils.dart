//algorithm_utils.dart
// ignore_for_file: non_constant_identifier_names
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mutex/mutex.dart';

import '../generated/ffibridge.dart';

class AlgorithmUtils {
  final loggingMutex = Mutex();

// const F150_TW_COEFFICIENT = 832.0;
  Future<void> mass_alg_step_log() async {
    await FFIBridge.mass_alg_step();
    // if (kDebugMode) {
    await log_vars();
    // }
  }

  Future<void> mass_alg_step_accel_log(double x, double y, double z) async {
    await FFIBridge.mass_alg_accel_step(x, y, z);
    // if (kDebugMode) {
    await log_vars();
    // }
  }

  Future<bool> algorithm_init() async {
    await FFIBridge.initialize();
    FFIBridge.mass_alg_init();
    mass_alg_step_log();
    mass_alg_step_log();
    return true;
  }

  Future<int> algorithm_pitch_ready(Future<bool> stopSignal) async {
    //level()
    // pitchready0 is for tongueweight/wd
    // pitchready1 is only for weight distribution
    bool stop = await Future.any([
      Future.delayed(Duration(seconds: 1)).then((_) => false),
      stopSignal,
    ]);
    if (stop) return -1;

    FFIBridge.set_pitchreset(1);
    await mass_alg_step_log();
    FFIBridge.set_pitchreset(0);
    await mass_alg_step_log();

    bool stop2 = await Future.any([
      Future.delayed(Duration(seconds: 4)).then((_) => false),
      stopSignal,
    ]);
    if (stop2) return -1;
    //PitchReady0 = 1, step, PitchReady0 = 0
    FFIBridge.set_pitchready0(1);
    await mass_alg_step_log();
    FFIBridge.set_pitchready0(0);
    await mass_alg_step_log();
    return 0;
  }

  Future<int> algorithm_pitch_ready1() async {
    FFIBridge.set_pitchready1(1);
    await mass_alg_step_log();
    FFIBridge.set_pitchready1(0);
    await mass_alg_step_log();
    // check pitchready1 too small
    if (FFIBridge.get_pitch1toosmall() == 1) {
      return -1;
    }
    return 0; //success
  }

  @protected
  Future<void> log_vars() async {
    //TODO: implement protected log_vars method
  }
}
