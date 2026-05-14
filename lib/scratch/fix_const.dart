import 'dart:io';

void processFile(File file) {
  String content = file.readAsStringSync();
  String original = content;

  // Remove `` before widgets that contain Theme.of
  // This is a naive but effective approach: just remove `` if the line has `Theme.of(context)`
  // Actually, better: remove `` from the line and previous line if it contains `Theme.of`
  
  List<String> lines = content.split('\n');
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('Theme.of(context)')) {
      lines[i] = lines[i].replaceAll('const ', '');
      // Check a few lines up to remove const if it was multi-line
      for (int j = i; j >= 0 && j > i - 5; j--) {
        if (lines[j].contains('const ')) {
          lines[j] = lines[j].replaceAll('const ', '');
        }
        if (lines[j].contains('return') || lines[j].contains('child:') || lines[j].contains('builder:')) {
          break;
        }
      }
    }
  }
  
  // Fix undefined context
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('Theme.of(context)') && lines[i].contains('undefined_identifier')) {
      // This is a manual fix comment, we just need to pass context or use Colors.white
    }
  }

  content = lines.join('\n');
  
  if (original != content) {
    file.writeAsStringSync(content);
  }
}

void main() {
  final dir = Directory('lib');
  final List<FileSystemEntity> entities = dir.listSync(recursive: true);
  for (var entity in entities) {
    if (entity is File && entity.path.endsWith('.dart')) {
      processFile(entity);
    }
  }
}
