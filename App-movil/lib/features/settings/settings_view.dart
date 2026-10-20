import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_icon.dart';
import '../../core/widgets/app_segmented.dart';
import '../../core/widgets/app_stepper.dart';
import '../../core/widgets/app_switch.dart';
import '../../core/widgets/confirm_card.dart';
import '../shell/shell_viewmodel.dart';
import 'settings_viewmodel.dart';
import 'widgets/accent_sheet.dart';
import 'widgets/connection_fields.dart';
import 'widgets/settings_group.dart';
import 'widgets/terminal_preview.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsViewModel>();
    final shell = context.watch<ShellViewModel>();
    final t = context.tokens;
    final fahrenheit = s.tempUnit == TempUnit.fahrenheit;
    final limit = fahrenheit
        ? '${formatNumber(s.tempLimit * 9 / 5 + 32, 0)} °F'
        : '${s.tempLimit} °C';
    final accentIndex = kAccentColors.indexOf(s.accent);

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 40 + MediaQuery.paddingOf(context).bottom),
      children: [
        SettingsGroup(
          title: 'Unidades',
          children: [
            SettingsRow(
              label: 'Temperatura',
              trailing: AppSegmented<TempUnit>(
                label: 'Unidad de temperatura',
                value: s.tempUnit,
                onChanged: s.setTempUnit,
                options: const [(TempUnit.celsius, '°C'), (TempUnit.fahrenheit, '°F')],
              ),
            ),
            SettingsRow(
              label: 'Almacenamiento',
              sublabel: 'GB (base 10) o GiB (base 2)',
              trailing: AppSegmented<StorageUnit>(
                label: 'Unidad de almacenamiento',
                value: s.storageUnit,
                onChanged: s.setStorageUnit,
                options: const [(StorageUnit.gb, 'GB'), (StorageUnit.gib, 'GiB')],
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Métricas',
          children: [
            SettingsRow(
              label: 'Alerta de temperatura',
              sublabel: 'Resalta la temperatura si pasa del límite',
              trailing: AppSwitch(
                label: 'Alerta de temperatura',
                value: s.tempAlert,
                onChanged: s.setTempAlert,
              ),
            ),
            if (s.tempAlert)
              SettingsRow(
                label: 'Límite',
                trailing: AppStepper(
                  valueLabel: limit,
                  valueMinWidth: 64,
                  decreaseLabel: 'Bajar límite',
                  increaseLabel: 'Subir límite',
                  onDecrease: () => s.setTempLimit(s.tempLimit - 5),
                  onIncrease: () => s.setTempLimit(s.tempLimit + 5),
                ),
              ),
          ],
        ),
        SettingsGroup(
          title: 'Terminal',
          children: [
            SettingsRow(
              label: 'Tamaño de fuente',
              trailing: AppStepper(
                valueLabel: '${s.termFont} px',
                valueMinWidth: 56,
                decreaseLabel: 'Reducir fuente',
                increaseLabel: 'Aumentar fuente',
                onDecrease: () => s.setTermFont(s.termFont - 1),
                onIncrease: () => s.setTermFont(s.termFont + 1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TerminalPreview(fontSize: s.termFont),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Apariencia',
          children: [
            SettingsRow(
              label: 'Tema',
              trailing: AppSegmented<bool>(
                label: 'Tema',
                value: s.dark,
                onChanged: s.setDark,
                options: const [(false, 'Claro'), (true, 'Oscuro')],
              ),
            ),
            SettingsRow(
              label: 'Color de acento',
              trailing: _AccentButton(
                color: s.accent,
                name: accentIndex >= 0 ? kAccentNames[accentIndex] : 'Personalizado',
                onTap: () => showAccentSheet(
                  context,
                  current: s.accent,
                  onPick: s.setAccent,
                ),
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Dispositivo',
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  const ConnectionFields(),
                  Divider(height: 1, color: t.border),
                  Text(
                    shell.isPaired
                        ? 'Este móvil está emparejado con el PC.'
                        : 'Este móvil no está emparejado con ningún PC.',
                    style: TextStyle(fontSize: 13, color: t.muted),
                  ),
                  AppButton(
                    label: shell.isPaired ? 'Desemparejar' : 'Emparejar',
                    fill: shell.isPaired ? kRed : t.accent,
                    onPressed: shell.isPaired
                        ? () => _confirmUnpair(context, shell)
                        : shell.pair,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmUnpair(BuildContext context, ShellViewModel shell) {
    return showConfirmCard(
      context,
      title: '¿Desemparejar este móvil?',
      body: 'Dejarás de controlar el PC desde la app hasta que vuelvas a emparejarlos.',
      confirmLabel: 'Desemparejar',
      semanticsLabel: 'Desemparejar',
      onConfirm: shell.unpair,
    );
  }
}

class _AccentButton extends StatelessWidget {
  const _AccentButton({required this.color, required this.name, required this.onTap});

  final Color color;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: 'Cambiar color de acento',
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 8, 0),
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                  Text(
                    name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.ink),
                  ),
                  AppIconView(AppIcon.chevronRight, color: t.ink, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
