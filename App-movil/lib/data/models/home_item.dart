// Modelos de la cuadrícula de Inicio: macros y carpetas.

import 'package:flutter/painting.dart';

/// Icono de una macro.
enum MacroKind { volume, lock, moon, bolt }

/// Elemento de la cuadrícula: una [Macro] o una [Folder].
sealed class HomeItem {
  const HomeItem({required this.id});

  final String id;
}

/// Comando con nombre que se ejecuta en el PC; [confirm] indica si pide confirmación antes.
class Macro extends HomeItem {
  const Macro({
    required super.id,
    required this.label,
    required this.command,
    this.kind = MacroKind.bolt,
    this.confirm = false,
  });

  final String label;
  final String command;
  final MacroKind kind;
  final bool confirm;
}

/// Carpeta de color con macros dentro.
class Folder extends HomeItem {
  const Folder({
    required super.id,
    required this.name,
    required this.color,
    required this.children,
  });

  final String name;
  final Color color;
  final List<Macro> children;

  Folder copyWith({String? name, Color? color, List<Macro>? children}) => Folder(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        children: children ?? this.children,
      );
}
