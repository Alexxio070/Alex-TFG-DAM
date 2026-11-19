// Nombre del móvil, para proponerlo como nombre del dispositivo en el login.

import 'package:device_info_plus/device_info_plus.dart';

/// Nombre que se usa cuando el usuario deja vacío el nombre del dispositivo.
const kDefaultDeviceName = 'Móvil Android';

/// Fabricante y modelo del móvil, o `null` si no se pueden leer (fuera de Android, en los tests).
Future<String?> readDeviceName() async {
  try {
    final info = await DeviceInfoPlugin().androidInfo;
    return '${info.manufacturer} ${info.model}'.trim();
  } catch (_) {
    return null;
  }
}

/// [typed] sin espacios sobrantes, o [kDefaultDeviceName] si está vacío.
String deviceNameOrDefault(String typed) {
  final name = typed.trim();
  return name.isEmpty ? kDefaultDeviceName : name;
}
