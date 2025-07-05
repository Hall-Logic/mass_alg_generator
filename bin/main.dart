import 'dart:io';

import 'package:mass_alg_generator/generator/code_generator.dart';
import 'package:mass_alg_generator/generator/variable_parser.dart';

void main() async {
  final variables = await parseVariablesFromFile('./libs/algorithm/Mass_Algorithm_App.c');
  final functions = _generateApiFunctions(variables);

  final apiC = generateApiC(functions);
  await File('api.c').writeAsString(apiC);

  final dartFfiBridge = generateDartFfiBridgeCode(variables);
  await File('ffibridge.dart').writeAsString(dartFfiBridge);
}

List<ApiFunction> _generateApiFunctions(List<Variable> variables) {
  final List<ApiFunction> functions = [];

  // Add non-getter/setter functions
  functions.add(ApiFunction(
    name: 'mass_alg_init',
    returnType: 'void',
  ));

  functions.add(ApiFunction(
    name: 'mass_alg_step',
    returnType: 'void',
  ));

  functions.add(ApiFunction(
    name: 'mass_alg_accel_step',
    returnType: 'void',
    parameters: ['float ax', 'float ay', 'float az'],
  ));

  // Add getter and setter functions for each variable
  for (final variable in variables) {
    functions.add(ApiFunction(
      name: 'get_${variable.name.toLowerCase()}',
      returnType: variable.type,
      variableName: variable.name,
      isGetter: true,
    ));

    functions.add(ApiFunction(
      name: 'set_${variable.name.toLowerCase()}',
      returnType: 'void',
      variableName: variable.name,
      isSetter: true,
      parameters: [variable.type + ' value'], // Add 'value' to the parameter type
    ));
  }

  return functions;
}
