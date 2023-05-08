import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:args/args.dart';
import 'package:mass_alg_generator/generator/code_generator.dart';
import 'package:mass_alg_generator/generator/variable_parser.dart';
import 'package:path/path.dart' as path;

const algOutputDir = './libs/algorithm';
const apiOutputDir = './libs';
const ffiOutputDir = './lib/utils/algorithm_utils';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('zipfile', abbr: 'z', help: 'Path to the input ZIP file');

  final results = parser.parse(arguments);

  if (results['zipfile'] == null) {
    print('Please provide the path to the input ZIP file using the -z option.');
    exit(1);
  }

  // Get the package path
  // final packagePath = await getPackagePath();
  // Unzip and move the files
  await unzipAndMoveFiles(results['zipfile'] as String);

  // Generate FFIBridge
  await generateFFIBridge(ffiOutputDir);
}

Future<void> unzipAndMoveFiles(String zipfile) async {
  // final outputDir = path.join(packageDir, 'libs/algorithm');

  // Unzip the input file into the output directory
  final bytes = File(zipfile).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  Directory(algOutputDir).createSync();

  for (final file in archive) {
    final filename = path.join(algOutputDir, file.name);
    if (file.isFile) {
      File(filename)
        ..createSync(recursive: true)
        ..writeAsBytesSync(file.content as List<int>);
    } else {
      Directory(filename)..createSync(recursive: true);
    }
  }

  // Flatten all subdirectories recursively
  final files = Directory(algOutputDir)
      .listSync(recursive: true, followLinks: false)
      .where((entity) => entity is File)
      .toList();

  for (final file in files) {
    final newPath = path.join(algOutputDir, path.basename(file.path));
    file.renameSync(newPath);
  }

  // Remove unwanted file types
  final extensionsToRemove = [
    '.png',
    '.html',
    '.js',
    '.gif',
    '.mat',
    '.css',
    '.svg',
    '.rights',
    '.exe',
    '.woff',
    '.cur',
  ];

  final filesToRemove = Directory(algOutputDir)
      .listSync(recursive: false, followLinks: false)
      .where((entity) =>
          entity is File &&
          (extensionsToRemove.contains(path.extension(entity.path)) ||
              !entity.path.contains('.')));

  for (final file in filesToRemove) {
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  // Remove remaining subdirectories
  final directoriesToRemove =
      Directory(algOutputDir).listSync().where((entity) => entity is Directory);

  for (final dir in directoriesToRemove) {
    dir.deleteSync(recursive: true);
  }
}

Future<void> generateFFIBridge(String ffiOutputDir) async {
  final String algorithmFile = path.join(algOutputDir, 'Mass_Algorithm_App.c');
  final variables = await parseVariablesFromFile(algorithmFile);
  final functions = _generateApiFunctions(variables);

  final apiC = generateApiC(functions);
  await File(path.join(apiOutputDir, 'api.c')).writeAsString(apiC);

  final dartFfiBridge = generateDartFfiBridgeCode(variables);
  await File(path.join(ffiOutputDir, 'ffibridge.dart'))
      .writeAsString(dartFfiBridge);
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
      parameters: [
        variable.type + ' value'
      ], // Add 'value' to the parameter type
    ));
  }

  return functions;
}

Future<String> getPackagePath() async {
  final packageUri = Uri.parse('package:mass_alg_generator/');
  final packagePath =
      (await Isolate.resolvePackageUri(packageUri))!.toFilePath();
  return packagePath;
}
