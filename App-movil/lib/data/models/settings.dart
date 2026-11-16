import '../../core/format.dart';

const kDefaultAgentAddress = '127.0.0.1:8443';

final _irohIdFormat = RegExp(r'^[0-9a-fA-F]{64}$');

bool isValidIrohId(String value) => _irohIdFormat.hasMatch(value);

const kInvalidIrohIdMessage = 'El identificador iroh no es válido: son 64 caracteres hexadecimales';

enum TempUnit {
  celsius,
  fahrenheit;

  double fromCelsius(double celsius) => this == fahrenheit ? celsius * 9 / 5 + 32 : celsius;
}

enum ConnectionMode { local, iroh }

enum StorageUnit {
  gb('GB', 1),
  gib('GiB', 0.9313);

  const StorageUnit(this.label, this.factor);
  final String label;
  final double factor;

  String format(double gb, {int decimals = 1}) => formatNumber(gb * factor, decimals);
}
