<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

This package is a code generator for the FFIBridge needed to access the simulink Mass_Algorithm_App.c variables and step functions

## Features

### FFIBridge Generator

Generate FFIBridge and unpack a new simulink .zip 

Usage:
``` sh
dart run mass_alg_generator:update_simulink_files -z $ZIPFILE
```
See mass_alg_generator.dart and /generator

You can unpack the simulink zip and create the FFIBridge.dart files by hand which was what I did originally.
This tool makes it easy to adapt to changes in the simulink code by automatically generating the flutter access points to any new variables.

The process is as follows:

1. grab all the .c files in all directories when the folder is unzipped
2. moves them to the /libs/algorithm/ folder within the project
3. parses the external global variables provided by simulink
4. generates the api.c file which the flutter FFIBridge uses as the access point. Setters and getters declared here
5. generates the FFIBridge.dart file (in utils/ffibridge.dart) which flutter uses to interact with native c functions - creates dart functions that look up the native function, sets types

### Accelerometer mixins

Because accelerometer logic had to be written for each page that sent accelerometer data to the mass algorithm, a mixin was created to unify this code so the mixin is declared on a page and the logic stays uniform.
#### Usage
An accelerometer page is declared with the mixin like so:
```dart
class _PumpDataPageState extends AccelerometerState<PumpDataPage>
    with AccelerometerMixin {
        ...
```

This gives the page the following methods:
```
startAccelerometer() - accelerometer starts and Wakelock.enable() keeps the screen on
stopAccelerometer()

    @protected
  void onStartAccelerometer() {}

  @protected
  void onStopAccelerometer() {}

  @protected
  void onProcessAccelerometerData(double x, double y, double z) {}

  @protected
  void phoneMoved() {}

  @protected
  void onMassAlgStep() {}

```

In each project, an AccelerometerMixin is created *on* the base mixin to override the functions and calls the mass_alg_step functions during an "onProcessAccelerometerData()" event

(example from flutter-wdtool):
```dart
// extended_accelerometer_monitoring_mixin.dart
// accelerometer_state.dart
import 'package:flutter/material.dart';
import 'package:mass_alg_generator/mixins/base_accelerometer_mixin.dart';
import 'package:wdtool/utils/algorithm_utils/algorithm_utils.dart';
import 'package:wdtool/utils/algorithm_utils/ffibridge.dart';

export 'package:mass_alg_generator/mixins/base_accelerometer_mixin.dart'; //export to use AccelerometerState whenever we use AccelerometerMixin

mixin AccelerometerMixin<T extends StatefulWidget> on AccelerometerState<T> {
  @override
  void onStartAccelerometer() {
    FFIBridge.set_phonemovedflag(0);
    FFIBridge.mass_alg_step();
  }

  @override
  void onProcessAccelerometerData(double x, double y, double z) async {
    if (FFIBridge.get_phonemovedflag() == 1) {
      phoneMoved(); // Call the overridden phoneMoved method
      FFIBridge.set_phonemovedflag(0);
      return;
    }
    await mass_alg_step_accel_log(x, y, z);
  }
}

```

the accelerometer class uses our forked sensors_plus package:
```yml
sensors_plus:
    git:
      url: https://github.com/Hall-Logic/plus_plugins.git
      path: packages/sensors_plus/sensors_plus
      ref: main
```
which only change is the accelerometer mode to GAME_MODE which pulls accelerometer data at ~20ms on Android similar to iOS at ~10ms. (The default package uses NORMAL_MODE)
The AccelerometerMixin uses this class

## Making changes
Note changes will affect apps using like wdtool and GVWR.

When making a change, push to main. To update to the latest package in the app, you may have to ```flutter clean``` and clear the flutter package cache

If you're unsure if the app is using the latest an easy way to check is to Right click -> "Go To Definition" which will bring you to the file in cache that's being referenced and you can see if your changes are there