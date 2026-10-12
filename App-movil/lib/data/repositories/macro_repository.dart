import '../models/home_item.dart';

abstract class MacroRepository {
  Future<List<HomeItem>> loadItems();
  Future<void> saveItems(List<HomeItem> items);
  Future<void> run(Macro macro);
}
