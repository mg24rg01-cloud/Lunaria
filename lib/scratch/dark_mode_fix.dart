import 'dart:io';

void processFile(File file) {
  String content = file.readAsStringSync();
  String original = content;

  // 1. Backgrounds
  content = content.replaceAll(
    'backgroundColor: Theme.of(context).scaffoldBackgroundColor', 
    'backgroundColor: Theme.of(context).scaffoldBackgroundColor'
  );
  content = content.replaceAll(
    'backgroundColor: Theme.of(context).scaffoldBackgroundColor', 
    'backgroundColor: Theme.of(context).scaffoldBackgroundColor'
  );

  // 2. Container/Card colors
  content = content.replaceAll(
    'color: Theme.of(context).cardColor,', 
    'color: Theme.of(context).cardColor,'
  );
  content = content.replaceAll(
    'color: Theme.of(context).cardColor)', 
    'color: Theme.of(context).cardColor)'
  );

  if (original != content) {
    file.writeAsStringSync(content);
    print('Updated \${file.path}');
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
