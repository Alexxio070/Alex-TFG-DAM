import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/models/home_item.dart';
import 'home_viewmodel.dart';
import 'widgets/confirm_dialog.dart';

void runMacro(BuildContext context, Macro macro) {
  final vm = context.read<HomeViewModel>();
  if (macro.confirm) {
    showConfirmDialog(context, macro: macro, onConfirm: () => vm.execute(macro));
  } else {
    vm.execute(macro);
  }
}
