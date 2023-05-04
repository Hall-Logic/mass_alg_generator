import 'variable_parser.dart';

class ApiFunction {
  ApiFunction({
    required this.name,
    required this.returnType,
    this.parameters = const [],
    this.variableName,
    this.isGetter = false,
    this.isSetter = false,
  });

  final String name;
  final String returnType;
  final List<String> parameters;
  final String? variableName;
  final bool isGetter;
  final bool isSetter;
}

class GettersAndSetters {
  GettersAndSetters({
    required this.getters,
    required this.setters,
    required this.exportFunctions,
  });

  final String getters;
  final String setters;
  final String exportFunctions;
}

String generateApiC(List<ApiFunction> functions) {
  final gettersAndSetters = _generateGettersAndSetters(functions);

  return '''
#include "api.h"
#include "Mass_Algorithm_App.h"

#define EXPORT extern __attribute__((visibility("default"))) __attribute__((used))

${gettersAndSetters.exportFunctions}

// getters and setters:
${gettersAndSetters.getters}
${gettersAndSetters.setters}
''';
}

GettersAndSetters _generateGettersAndSetters(List<ApiFunction> functions) {
  final getters = StringBuffer();
  final setters = StringBuffer();
  final exportFunctions = StringBuffer();

  for (final function in functions) {
    if (function.isGetter) {
      getters.writeln(_generateGetter(function));
    } else if (function.isSetter) {
      setters.writeln(_generateSetter(function));
    } else {
      exportFunctions.writeln(_generateExportFunction(function));
    }
  }

  return GettersAndSetters(
    getters: getters.toString(),
    setters: setters.toString(),
    exportFunctions: exportFunctions.toString(),
  );
}

String _generateExportFunction(ApiFunction function) {
  return '''
EXPORT ${function.returnType}
${function.name}(${function.parameters.join(', ')})
{
${_generateFunctionBody(function)}
}
''';
}

String _generateGetter(ApiFunction function) {
  return '''
EXPORT ${function.returnType} ${function.name}() { return ${function.variableName}; }
''';
}

String _generateSetter(ApiFunction function) {
  return '''
EXPORT void ${function.name}(${function.returnType} value) { ${function.variableName} = value; }
''';
}

String _generateFunctionBody(ApiFunction function) {
  final parameters = function.parameters.isEmpty
      ? ''
      : function.parameters.map((param) => param.split(' ')[1]).join(', ');

  return 'return Mass_Algorithm_App_${function.name}($parameters);';
}

String generateDartFfiBridgeCode(List<Variable> variables) {
  final getters = variables.map((variable) {
    final dartType = _convertCppTypeToDartType(variable.type);
    final nativeFunctionType = _convertDartTypeToNativeFunctionType(dartType);
    return '''
    final _get_${variable.name.toLowerCase()} =
        nativeApiLib.lookup<NativeFunction<$nativeFunctionType Function()>>('get_${variable.name.toLowerCase()}');
    get_${variable.name.toLowerCase()} = _get_${variable.name.toLowerCase()}.asFunction<$dartType Function()>();''';
  }).join('\n');

  final setters = variables.map((variable) {
    final dartType = _convertCppTypeToDartType(variable.type);
    final nativeFunctionType = _convertDartTypeToNativeFunctionType(dartType);
    return '''
    final _set_${variable.name.toLowerCase()} =
        nativeApiLib.lookup<NativeFunction<Void Function($nativeFunctionType)>>('set_${variable.name.toLowerCase()}');
    set_${variable.name.toLowerCase()} = _set_${variable.name.toLowerCase()}.asFunction<void Function($dartType)>();''';
  }).join('\n');

  final getterSetterDefinitions = variables.map((variable) {
    final dartType = _convertCppTypeToDartType(variable.type);
    return '''
  static late Function get_${variable.name.toLowerCase()};
  static late Function set_${variable.name.toLowerCase()};''';
  }).join('\n');

  return '''
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';
import 'dart:io';

class FFIBridge {
  static Future<bool> initialize() async {
    nativeApiLib = Platform.isMacOS || Platform.isIOS
        ? DynamicLibrary.process() // macos and ios
        : (DynamicLibrary.open(Platform.isWindows // windows
            ? 'api.dll'
            : 'libapi.so')); // android and linux

    final _mass_alg_init =
        nativeApiLib.lookup<NativeFunction<Void Function()>>('mass_alg_init');
    mass_alg_init = _mass_alg_init.asFunction<void Function()>();

    final _mass_alg_step =
        nativeApiLib.lookup<NativeFunction<Void Function()>>('mass_alg_step');
    mass_alg_step = _mass_alg_step.asFunction<void Function()>();();
    final _mass_alg_accel_step =
    nativeApiLib.lookup<NativeFunction<Void Function(Float, Float, Float)>>(
        'mass_alg_accel_step');
mass_alg_accel_step = _mass_alg_accel_step
    .asFunction<void Function(double, double, double)>();

_loadGetters();
_loadSetters();

return true;
}

static void _loadGetters() {
$getters
}

static void _loadSetters() {
$setters
}

static late DynamicLibrary nativeApiLib;
static late Function mass_alg_init;
static late Function mass_alg_step;
static late Function mass_alg_accel_step;

$getterSetterDefinitions
}
''';
}

String _convertCppTypeToDartType(String cType) {
  switch (cType) {
    case 'real_T':
      return 'double';
    case 'boolean_T':
      return 'int';
    default:
      return 'dynamic';
  }
}

String _convertDartTypeToNativeFunctionType(String dartType) {
  switch (dartType) {
    case 'double':
      return 'Float';
    case 'int':
      return 'Int32';
    default:
      return 'Void';
  }
}
