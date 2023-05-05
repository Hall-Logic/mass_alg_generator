import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:args/args.dart';
import 'package:mass_alg_generator/generator/code_generator.dart';
import 'package:mass_alg_generator/generator/variable_parser.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('zipfile', abbr: 'z', help: 'Path to the input ZIP file');

  final results = parser.parse(arguments);

  if (results['zipfile'] == null) {
    print('Please provide the path to the input ZIP file using the -z option.');
    exit(1);
  }

  // Get the package path
  final packagePath = await getPackagePath();
  // Unzip and move the files
  await unzipAndMoveFiles(results['zipfile'] as String, packagePath);

  // Generate FFIBridge
  await generateFFIBridge(packagePath);
}

Future<void> unzipAndMoveFiles(String zipfile, String packageDir) async {
  final outputDir = path.join(packageDir, 'libs', 'algorithm');

  final bytes = File(zipfile).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  Directory(outputDir).createSync();

  for (final file in archive) {
    final filename = path.join(outputDir, file.name);
    if (file.isFile) {
      File(filename)
        ..createSync(recursive: true)
        ..writeAsBytesSync(file.content as List<int>);
    } else {
      Directory(filename)..createSync(recursive: true);
    }
  }

  // Flatten all subdirectories recursively
  final files = Directory(outputDir)
      .listSync(recursive: true, followLinks: false)
      .where((entity) => entity is File)
      .toList();

  for (final file in files) {
    final newPath = path.join(outputDir, path.basename(file.path));
    file.renameSync(newPath);
  }

  // Remove unwanted file types and files with no extension
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

  for (final file in files) {
    if (extensionsToRemove.contains(path.extension(file.path)) ||
        !file.path.contains('.')) {
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }

  // Remove remaining subdirectories
  final directoriesToRemove =
      Directory(outputDir).listSync().where((entity) => entity is Directory);

  for (final dir in directoriesToRemove) {
    dir.deleteSync(recursive: true);
  }
}

Future<void> generateFFIBridge(String packageDir) async {
  final outputDir = path.join(packageDir, 'libs', 'algorithm');
  final String algorithmFile = path.join(outputDir, 'Mass_Algorithm_App.c');
  final variables = await parseVariablesFromFile(algorithmFile);
  final functions = _generateApiFunctions(variables);

  final apiC = generateApiC(functions);
  await File(path.join(packageDir, 'generated', 'api.c')).writeAsString(apiC);

  final dartFfiBridge = generateDartFfiBridgeCode(variables);
  await File(path.join(packageDir, 'generated', 'ffibridge.dart'))
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
