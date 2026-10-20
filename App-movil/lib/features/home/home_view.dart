import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_fab.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/models/home_item.dart';
import 'home_viewmodel.dart';
import 'run_macro.dart';
import 'widgets/folder_dialog.dart';
import 'widgets/folder_edit_sheet.dart';
import 'widgets/folder_trash_dialog.dart';
import 'widgets/macro_grid.dart';
import 'widgets/new_macro_dialog.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  void _handleDelete(BuildContext context, HomeViewModel vm, String id) {
    final item = vm.items.where((i) => i.id == id).firstOrNull;
    if (item is Folder && item.children.isNotEmpty) {
      showFolderTrashDialog(
        context,
        folder: item,
        onUngroup: () => vm.ungroupFolder(id),
        onDelete: () => vm.deleteItem(id),
      );
    } else {
      vm.deleteItem(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final toast = vm.toast;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        Positioned.fill(
          child: MacroGrid(
            items: vm.items,
            onTap: (item) => switch (item) {
              Macro() => runMacro(context, item),
              Folder() => showFolderDialog(context, item),
            },
            onEditFolder: (folder) => showFolderEditSheet(context, folder),
            onMove: vm.moveItem,
            onMerge: vm.mergeInto,
            onDelete: (id) => _handleDelete(context, vm, id),
            onDraggingChanged: vm.setDragging,
          ),
        ),
        if (!vm.dragging)
          Positioned(
            right: 20,
            bottom: 28 + bottomInset,
            child: AppFab(
              label: 'Añadir macro',
              onTap: () => vm.isFull ? vm.showFullToast() : showNewMacroDialog(context),
            ),
          ),
        if (toast != null && !vm.dragging)
          Positioned(
            left: 20,
            right: 96,
            bottom: 28 + bottomInset,
            child: AppToast(text: toast.title, subtitle: toast.command),
          ),
      ],
    );
  }
}

