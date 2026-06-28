import 'dart:io';

void main() {
  final file = File('pubspec.yaml');
  var content = file.readAsStringSync();
  content = content.replaceAll('- assets/images/app_icon.ico', '- assets/images/logo.png');
  
  if (!content.contains('flutter_launcher_icons:')) {
    content += '''

flutter_launcher_icons:
  android: false
  ios: false
  image_path: "assets/images/logo.png"
  min_sdk_size: 21
  windows:
    generate: true
    image_path: "assets/images/logo.png"
    icon_size: 48
''';
  }
  file.writeAsStringSync(content);
}
