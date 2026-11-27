// Popup de aviso de la bienvenida y del registro.

import 'package:flutter/material.dart';

/// Diálogo nativo en mitad de la pantalla con [message] y el botón «Aceptar».
Future<void> showInfoDialog(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Aceptar')),
      ],
    ),
  );
}
