import 'dart:io';

class Variable {
  Variable({required this.name, required this.type});

  final String name;
  final String type;

  @override
  String toString() => '$type $name';
}

Future<List<Variable>> parseVariablesFromFile(String filePath) async {
  final file = File(filePath);
  final lines = await file.readAsLines();
  return _parseVariablesFromLines(lines);
}

List<Variable> _parseVariablesFromLines(List<String> lines) {
  final List<Variable> variables = [];
  bool inExportedBlockSignals = false;

  for (final line in lines) {
    if (line.contains('/* Exported block signals */')) {
      inExportedBlockSignals = true;
    } else if (line.contains('/* Block signals and states (default storage) */')) {
      break;
    }

    if (inExportedBlockSignals) {
      final variable = _parseVariableFromLine(line);
      if (variable != null) {
        variables.add(variable);
      }
    }
  }

  return variables;
}

Variable? _parseVariableFromLine(String line) {
  final regex = RegExp(r'^(real_T|boolean_T)\s+([\w]+);');
  final match = regex.firstMatch(line);

  if (match != null && match.groupCount == 2) {
    return Variable(name: match.group(2)!, type: match.group(1)!);
  }

  return null;
}
