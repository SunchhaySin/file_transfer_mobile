import 'dart:io' show Platform;
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceName() async {
  final deviceInfo = DeviceInfoPlugin();
  String baseName;

  if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    baseName = iosInfo.name;
  } else {
    final androidInfo = await deviceInfo.androidInfo;
    baseName = androidInfo.model;
  }

  final uniqueSuffix = Random().nextInt(9999).toString().padLeft(4, '0');
  return '$baseName-$uniqueSuffix'; 
}