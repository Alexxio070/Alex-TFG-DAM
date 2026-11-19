// Valores de Ajustes: unidades, modo de conexión y validación de los datos del agente.

import '../../core/format.dart';

/// Dirección del agente por defecto (por USB con `adb reverse`).
const kDefaultAgentAddress = '127.0.0.1:8443';

final _hex64Format = RegExp(r'^[0-9a-fA-F]{64}$');

/// Un identificador iroh válido son 64 caracteres hexadecimales.
bool isValidIrohId(String value) => _hex64Format.hasMatch(value);

const kInvalidIrohIdMessage = 'El identificador iroh no es válido: son 64 caracteres hexadecimales';

/// Una huella válida son 64 caracteres hexadecimales (SHA-256).
bool isValidFingerprint(String value) => _hex64Format.hasMatch(value);

const kInvalidFingerprintMessage = 'La huella no es válida: son 64 caracteres hexadecimales';

/// Unidad en la que se muestra la temperatura.
enum TempUnit {
  celsius,
  fahrenheit;

  /// Convierte [celsius] a esta unidad.
  double fromCelsius(double celsius) => this == fahrenheit ? celsius * 9 / 5 + 32 : celsius;
}

/// Cómo se llega al agente: red local/USB por HTTPS, o túnel iroh.
enum ConnectionMode { local, iroh }

/// Unidad de los tamaños: GB (base 10) o GiB (base 2).
enum StorageUnit {
  gb('GB', 1),
  gib('GiB', 0.9313);

  const StorageUnit(this.label, this.factor);
  final String label;
  final double factor;

  /// Formatea [gb] gigabytes en esta unidad, sin el nombre de la unidad.
  String format(double gb, {int decimals = 1}) => formatNumber(gb * factor, decimals);
}
