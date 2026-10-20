import 'package:flutter_test/flutter_test.dart';
import 'package:tfg/data/fake/fake_macro_repository.dart';
import 'package:tfg/data/models/home_item.dart';
import 'package:tfg/features/home/home_viewmodel.dart';

void main() {
  Future<HomeViewModel> openHome() async {
    final vm = HomeViewModel(FakeMacroRepository());
    await Future<void>.delayed(Duration.zero);
    return vm;
  }

  test('moveItem cambia el orden de los elementos', () async {
    final vm = await openHome();
    final ids = vm.items.map((i) => i.id).toList();

    vm.moveItem(ids[0], 2);

    expect(vm.items.map((i) => i.id).toList(), [ids[1], ids[2], ids[0], ids[3]]);
  });

  test('mergeInto dos macros crea una carpeta con ambas dentro', () async {
    final vm = await openHome();
    final first = vm.items[0] as Macro;
    final second = vm.items[1] as Macro;

    vm.mergeInto(first.id, 1);

    expect(vm.items, hasLength(3));
    final folder = vm.items.firstWhere((i) => i is Folder) as Folder;
    expect(folder.children.map((m) => m.id), containsAll([first.id, second.id]));
    expect(vm.items.any((i) => i.id == first.id), isFalse);
  });

  test('mergeInto una macro con una carpeta existente la añade dentro', () async {
    final vm = await openHome();
    final first = vm.items[0] as Macro;
    final second = vm.items[1] as Macro;
    final third = vm.items[2] as Macro;
    vm.mergeInto(first.id, 1);
    final folderIndex = vm.items.indexWhere((i) => i is Folder);

    vm.mergeInto(third.id, folderIndex);

    final folder = vm.items.firstWhere((i) => i is Folder) as Folder;
    expect(folder.children.map((m) => m.id), containsAll([first.id, second.id, third.id]));
    expect(vm.items.any((i) => i.id == third.id), isFalse);
  });

  test('ungroupFolder deshace la carpeta y deja las macros sueltas', () async {
    final vm = await openHome();
    final first = vm.items[0] as Macro;
    final second = vm.items[1] as Macro;
    vm.mergeInto(first.id, 1);
    final folder = vm.items.firstWhere((i) => i is Folder) as Folder;

    vm.ungroupFolder(folder.id);

    expect(vm.items.any((i) => i is Folder), isFalse);
    expect(vm.items.map((i) => i.id), containsAll([first.id, second.id]));
  });
}
