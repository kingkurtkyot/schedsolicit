import 'package:flutter/material.dart';

class UndoSnackBar {
  UndoSnackBar._();

  static void show({
    required BuildContext context,
    required String message,
    required VoidCallback onUndo,
    VoidCallback? onDismissed,
    Duration duration = const Duration(seconds: 5),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.amberAccent,
          onPressed: onUndo,
        ),
      ),
    ).closed.then((reason) {
      if (reason != SnackBarClosedReason.action) {
        onDismissed?.call();
      }
    });
  }
}
