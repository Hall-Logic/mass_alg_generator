//stubfile so mixin and other classes can access it. This file will be overwritten by the update simulink script

// ffibridge_stub.dart
class FFIBridge {
  static Future<void> mass_alg_step() async {
    // Stub implementation
  }

  static Future<void> mass_alg_accel_step(double x, double y, double z) async {
    // Stub implementation
  }

  static Future<void> mass_alg_step_log() async {
    // Stub implementation
  }

  static Future<void> initialize() async {
    // Stub implementation
  }

  static void mass_alg_init() {
    // Stub implementation
  }

  static void set_pitchreset(int value) {
    // Stub implementation
  }

  static void set_pitchready0(int value) {
    // Stub implementation
  }

  static void set_pitchready1(int value) {
    // Stub implementation
  }

  static int get_pitch1toosmall() {
    // Stub implementation
    return 0;
  }

  static void set_phonemovedflag(int value) {
    // Stub implementation
  }

  static int get_phonemovedflag() {
    // Stub implementation
    return 0;
  }
}
