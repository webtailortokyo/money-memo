import 'dart:io';

void main() async {
  final file = File('analyze.txt');
  final bytes = await file.readAsBytes();
  // Decode UTF-16 LE if needed
  String content;
  // Since Dart doesn't have Utf16 built-in without package, let's just strip null bytes manually since it's ascii text mostly.
  content = String.fromCharCodes(bytes.where((b) => b != 0));
  
  // Since Dart doesn't have Utf16 built-in without package, let's just strip null bytes manually since it's ascii text mostly.
  content = String.fromCharCodes(bytes.where((b) => b != 0));

  final lines = content.split('\n');
  final errors = <String, List<int>>{};
  
  for (final line in lines) {
    if (line.contains('INVALID_CONSTANT')) {
      final parts = line.split('|');
      if (parts.length >= 5) {
        final filePath = parts[3];
        final lineNum = int.tryParse(parts[4]);
        if (lineNum != null) {
          errors.putIfAbsent(filePath, () => []).add(lineNum);
        }
      }
    }
  }

  for (final entry in errors.entries) {
    final filePath = entry.key;
    final file = File(filePath);
    if (!await file.exists()) continue;
    
    final fileLines = await file.readAsLines();
    final lineNums = entry.value.toSet().toList()..sort((a, b) => b.compareTo(a));
    
    for (final lineNum in lineNums) {
      if (lineNum <= fileLines.length && lineNum > 0) {
        final idx = lineNum - 1;
        // Search back for 'const ' up to 5 lines if it's a multi-line const
        for (int i = 0; i < 5 && (idx - i) >= 0; i++) {
           if (fileLines[idx - i].contains('const ')) {
              fileLines[idx - i] = fileLines[idx - i].replaceFirst('const ', '');
              break;
           }
        }
      }
    }
    
    await file.writeAsString(fileLines.join('\n'));
    print('Fixed $filePath - ${lineNums.length} issues');
  }
}
