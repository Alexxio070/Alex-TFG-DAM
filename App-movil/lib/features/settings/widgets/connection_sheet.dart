import 'package:flutter/material.dart';

import '../../../core/widgets/modal_card.dart';
import 'connection_fields.dart';

Future<void> showConnectionSheet(BuildContext context) {
  return showBottomCard(
    context,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: SingleChildScrollView(
        child: const BottomSheetCard(bottomPadding: 24, children: [ConnectionFields()]),
      ),
    ),
  );
}
