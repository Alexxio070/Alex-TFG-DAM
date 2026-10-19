import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/models/home_item.dart';
import 'home_viewmodel.dart';
import 'widgets/confirm_dialog.dart';

void runMacro(BuildContext context, Macro macro) {
  final vm = context.read<HomeViewModel>();
  void execute() {
    HapticFeedback.lightImpact();
    vm.execute(macro);
  }

  if (macro.confirm) {
    showConfirmDialog(context, macro: macro, onConfirm: execute);
  } else {
    execute();
  }
}
