import '../models/home_item.dart';
import '../repositories/macro_repository.dart';

class FakeMacroRepository implements MacroRepository {
  List<HomeItem> _items = const [
    Macro(
      id: 'm1',
      label: 'Silenciar',
      command: 'pactl set-sink-mute @DEFAULT_SINK@ toggle',
      kind: MacroKind.volume,
    ),
    Macro(
      id: 'm2',
      label: 'Bloquear',
      command: 'loginctl lock-session',
      kind: MacroKind.lock,
    ),
    Macro(
      id: 'm3',
      label: 'Modo noche',
      command: 'plasma-apply-colorscheme BreezeDark',
      kind: MacroKind.moon,
    ),
    Macro(id: 'm4', label: 'Abrir terminal', command: 'konsole'),
  ];

  @override
  Future<List<HomeItem>> loadItems() async => List.of(_items);

  @override
  Future<void> saveItems(List<HomeItem> items) async => _items = List.of(items);

  @override
  Future<void> run(Macro macro) async {}
}
