import 'package:flutter/material.dart';

/// Reusable fancy snackbar with floating, rounded design.
///
/// Example usage:
/// ```dart
/// AppSnackBar.showError(
///   context,
///   message: 'Selected dates are not available. Please choose different dates.',
/// );
/// ```
class AppSnackBar {
  /// Core reusable method
  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.info_outline,
    Color backgroundColor = Colors.blueAccent,
    String actionLabel = 'OK',
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: onAction ?? () {},
        ),
      ),
    );
  }

  /// 🔴 Error snackbar
  static void showError(
    BuildContext context, {
    required String message,
    required Duration duration,
  }) {
    show(
      context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: Colors.redAccent.shade700,
    );
  }

  /// 🟢 Success snackbar
  static void showSuccess(BuildContext context, {required String message}) {
    show(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: Colors.green.shade600,
    );
  }

  /// 🟦 Info snackbar
  static void showInfo(BuildContext context, {required String message}) {
    show(
      context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: Colors.blueAccent,
    );
  }

  /// 🟨 Warning snackbar
  static void showWarning(BuildContext context, {required String message}) {
    show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: Colors.orangeAccent.shade700,
    );
  }

  static void showLoading(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blue.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
