import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class AppStepper extends StatelessWidget {
  const AppStepper({
    super.key,
    required this.valueLabel,
    required this.valueMinWidth,
    required this.onDecrease,
    required this.onIncrease,
    required this.decreaseLabel,
    required this.increaseLabel,
  });

  final String valueLabel;
  final double valueMinWidth;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final String decreaseLabel;
  final String increaseLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        _StepButton(symbol: '−', label: decreaseLabel, onTap: onDecrease),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: valueMinWidth),
          child: Text(
            valueLabel,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.ink),
          ),
        ),
        _StepButton(symbol: '+', label: increaseLabel, onTap: onIncrease),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.symbol, required this.label, required this.onTap});

  final String symbol;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: t.borderStrong),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Text(symbol, style: TextStyle(fontSize: 20, color: t.ink)),
            ),
          ),
        ),
      ),
    );
  }
}
