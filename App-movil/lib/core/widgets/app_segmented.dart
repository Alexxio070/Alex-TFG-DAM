// Control segmentado compartido (Ajustes y conexión con el PC).

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Elige un valor entre varias opciones `(valor, texto)`; [label] es su nombre para el lector de
/// pantalla.
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: label,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: t.line,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            for (final (option, text) in options)
              Semantics(
                button: true,
                selected: option == value,
                label: text,
                excludeSemantics: true,
                onTap: () => onChanged(option),
                child: GestureDetector(
                  onTap: () => onChanged(option),
                  child: Container(
                    height: 36,
                    constraints: const BoxConstraints(minWidth: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: option == value ? t.segOn : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: option == value
                          ? [
                              BoxShadow(
                                color: kShadowColor.withValues(alpha: 0.15),
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: option == value ? t.ink : t.muted2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
