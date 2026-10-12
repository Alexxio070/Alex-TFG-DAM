import 'package:flutter/painting.dart';

enum MacroKind { volume, lock, moon, bolt }

sealed class HomeItem {
  const HomeItem({required this.id});

  final String id;
}

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
