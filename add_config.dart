import 'dart:io';

void main() {
  final file = File('pubspec.yaml');
  var content = file.readAsStringSync();
  content += '''

flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/images/logo.png"
  min_sdk_size: 21 # android min sdk min:16, default 21
  windows:
    generate: true
    image_path: "assets/images/logo.png"
    icon_size: 48 # min:48, max:256, default 48
''';
  file.writeAsStringSync(content);
}
