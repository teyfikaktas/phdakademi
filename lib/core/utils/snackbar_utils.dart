// lib/core/utils/snackbar_utils.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SnackBarUtils {
  // Responsive helper
  static bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  // Coming Soon SnackBar
  static void showComingSoon(BuildContext context, String feature) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
              size: _isMobile(context) ? 18 : 20,
            ),
            SizedBox(width: _isMobile(context) ? 8 : 12),
            Expanded(
              child: Text(
                '$feature modülü yakında geliyor!',
                style: TextStyle(
                  fontSize: _isMobile(context) ? 14 : 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(_isMobile(context) ? 12 : 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Success SnackBar
  static void showSuccess(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: _isMobile(context) ? 18 : 20,
            ),
            SizedBox(width: _isMobile(context) ? 8 : 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: _isMobile(context) ? 14 : 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(_isMobile(context) ? 12 : 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Error SnackBar
  static void showError(BuildContext context, String message) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_rounded,
              color: Colors.white,
              size: _isMobile(context) ? 18 : 20,
            ),
            SizedBox(width: _isMobile(context) ? 8 : 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: _isMobile(context) ? 14 : 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(_isMobile(context) ? 12 : 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Warning SnackBar
  static void showWarning(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: _isMobile(context) ? 18 : 20,
            ),
            SizedBox(width: _isMobile(context) ? 8 : 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: _isMobile(context) ? 14 : 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(_isMobile(context) ? 12 : 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Custom SnackBar
  static void showCustom(
      BuildContext context,
      String message, {
        IconData? icon,
        Color? backgroundColor,
        Duration? duration,
        VoidCallback? onAction,
        String? actionLabel,
      }) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: Colors.white,
                size: _isMobile(context) ? 18 : 20,
              ),
              SizedBox(width: _isMobile(context) ? 8 : 12),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: _isMobile(context) ? 14 : 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(_isMobile(context) ? 12 : 16),
        duration: duration ?? const Duration(seconds: 2),
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: onAction,
        )
            : null,
      ),
    );
  }
}

// Extension olarak da kullanabilirsin (opsiyonel)
extension SnackBarExtension on BuildContext {
  void showComingSoon(String feature) =>
      SnackBarUtils.showComingSoon(this, feature);

  void showSuccess(String message) =>
      SnackBarUtils.showSuccess(this, message);

  void showError(String message) =>
      SnackBarUtils.showError(this, message);

  void showWarning(String message) =>
      SnackBarUtils.showWarning(this, message);
}