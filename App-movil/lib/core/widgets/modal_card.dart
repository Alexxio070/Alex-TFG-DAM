import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

const _scrim = Color.fromRGBO(22, 24, 29, 0.45);

Future<void> showTopCard(
  BuildContext context, {
  required double top,
  required double side,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: _scrim,
    transitionDuration: Duration.zero,
    pageBuilder: (context, _, _) => Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.fromLTRB(side, top, side, 0),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: double.infinity, child: builder(context)),
        ),
      ),
    ),
  );
}

Future<void> showBottomCard(BuildContext context, {required WidgetBuilder builder}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: _scrim,
    transitionDuration: Duration.zero,
    pageBuilder: (context, _, _) => Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(width: double.infinity, child: builder(context)),
      ),
    ),
  );
}

class ModalCard extends StatelessWidget {
  const ModalCard({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(20, 22, 20, 20),
    required this.child,
  });

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(22, 24, 29, 0.25), offset: Offset(0, 16), blurRadius: 40),
        ],
      ),
      child: child,
    );
  }
}

class BottomSheetCard extends StatelessWidget {
  const BottomSheetCard({super.key, required this.bottomPadding, required this.children});

  final double bottomPadding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        bottomPadding + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(22, 24, 29, 0.18), offset: Offset(0, -12), blurRadius: 32),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 18,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: t.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
