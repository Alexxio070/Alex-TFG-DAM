import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/modal_card.dart';

Future<void> showAccentSheet(
  BuildContext context, {
  required Color current,
  required ValueChanged<Color> onPick,
}) {
  return showBottomCard(
    context,
    builder: (sheetContext) => Semantics(
      label: 'Color de acento',
      child: BottomSheetCard(
        bottomPadding: 32,
        children: [
          Text(
            'Color de acento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: sheetContext.tokens.ink,
            ),
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 96,
            children: [
              for (var i = 0; i < kAccentColors.length; i++)
                _AccentCard(
                  color: kAccentColors[i],
                  name: kAccentNames[i],
                  selected: kAccentColors[i] == current,
                  onTap: () {
                    onPick(kAccentColors[i]);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _AccentCard extends StatelessWidget {
  const _AccentCard({
    required this.color,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? color : t.border, width: selected ? 2 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: selected
                      ? [
                          BoxShadow(color: t.surface, spreadRadius: 3),
                          BoxShadow(color: color, spreadRadius: 5),
                        ]
                      : null,
                ),
              ),
              Text(
                name,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
