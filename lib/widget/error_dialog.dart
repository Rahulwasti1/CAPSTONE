import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ErrorDialog extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? actionCallback;

  const ErrorDialog({
    Key? key,
    required this.errorMessage,
    required this.onDismiss,
    this.actionLabel,
    this.actionCallback,
  }) : super(key: key);

  // Show the error dialog or snackbar depending on severity
  static void show(BuildContext context, String errorMessage,
      {String? actionLabel, VoidCallback? actionCallback}) {
    // For validation errors, show a specific red snackbar
    if (errorMessage.startsWith("Error:") &&
        (errorMessage.contains("cannot be empty") ||
            errorMessage.contains("must be") ||
            errorMessage.contains("at least"))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage.replaceAll("Error: ", "")),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
        ),
      );
      return;
    }

    // For general messages (not errors), use orange snackbar
    if (!errorMessage.contains("Error")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
        ),
      );
      return;
    }

    // For other errors, show a dialog with more information
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Action Required"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorMessage.replaceAll("Error: ", "")),
            SizedBox(height: 8),
            Text(
              "Please check your inputs and try again.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (actionCallback != null) actionCallback();
              },
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This is a simpler dialog with fewer elements
    return AlertDialog(
      title: Text("Action Required"),
      content: Text(errorMessage),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: Text("CONTINUE"),
        ),
        if (actionLabel != null && actionCallback != null)
          TextButton(
            onPressed: actionCallback,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
