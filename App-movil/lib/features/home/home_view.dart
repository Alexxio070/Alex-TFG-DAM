import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_icon.dart';
import '../../data/models/home_item.dart';
import 'home_viewmodel.dart';
import 'run_macro.dart';
import 'widgets/folder_dialog.dart';
import 'widgets/folder_edit_sheet.dart';
import 'widgets/folder_trash_dialog.dart';
import 'widgets/macro_grid.dart';
import 'widgets/new_macro_dialog.dart';
import 'widgets/run_toast.dart';

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
            child: _AddButton(
              onTap: () => vm.isFull ? vm.showFullToast() : showNewMacroDialog(context),
            ),
          ),
        if (toast != null && !vm.dragging)
          Positioned(
            left: 20,
            right: 96,
            bottom: 28 + bottomInset,
            child: RunToast(data: toast),
          ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Añadir macro',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: context.tokens.accent,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(22, 24, 29, 0.25),
                offset: Offset(0, 10),
                blurRadius: 24,
              ),
            ],
          ),
          child: const Center(
            child: AppIconView(
              AppIcon.plus,
              color: Colors.white,
              size: 26,
              strokeWidth: 2.2,
            ),
          ),
        ),
      ),
    );
  }
}
