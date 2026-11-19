// Interfaz de las macros de Inicio.

import '../models/home_item.dart';

/// Carga y guarda la cuadrícula de Inicio y ejecuta macros en el PC.
abstract class MacroRepository {
  Future<List<HomeItem>> loadItems();
  Future<void> saveItems(List<HomeItem> items);
  Future<void> run(Macro macro);
}
