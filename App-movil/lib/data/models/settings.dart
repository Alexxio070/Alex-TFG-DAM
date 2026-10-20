const kDefaultAgentAddress = '127.0.0.1:8443';

enum TempUnit { celsius, fahrenheit }

enum ConnectionMode { local, iroh }

enum StorageUnit {
  gb('GB', 1),
  gib('GiB', 0.9313);

  const StorageUnit(this.label, this.factor);
  final String label;
  final double factor;
}
