import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastUtil {
  static void showSuccessToast(BuildContext context, String message) {
    _showToast(
      context: context,
      message: message,
      type: ToastificationType.success,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  static void showErrorToast(BuildContext context, String message) {
    _showToast(
      context: context,
      message: message,
      type: ToastificationType.error,
      backgroundColor: Colors.red,
      icon: Icons.error,
    );
  }

  static void showWarningToast(BuildContext context, String message) {
    _showToast(
      context: context,
      message: message,
      type: ToastificationType.warning,
      backgroundColor: Colors.orange,
      icon: Icons.crisis_alert_outlined,
    );
  }

  static void showCustomToast(
    BuildContext context,
    String title,
    String message,
    Color backgroundColor,
  ) {
    _showCustomToast(
      context: context,
      title: title,
      message: message,
      backgroundColor: backgroundColor,
    );
  }

  static void _showToast({
    required BuildContext context,
    required String message,
    required ToastificationType type,
    required Color backgroundColor,
    required IconData icon,
  }) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 5),
      title: Text(
        type == ToastificationType.success
            ? 'Success'
            : type == ToastificationType.warning
            ? 'Warning'
            : 'Error',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      description: RichText(
        text: TextSpan(
          text: message,
          style: const TextStyle(color: Colors.black),
        ),
      ),
      alignment: Alignment.bottomRight,
      primaryColor: backgroundColor,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      icon: Icon(icon, color: backgroundColor),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x07000000),
          blurRadius: 16,
          offset: Offset(0, 16),
          spreadRadius: 0,
        ),
      ],
      showProgressBar: true,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
      applyBlurEffect: true,
      callbacks: const ToastificationCallbacks(
        //onTap: (toastItem) => print('Toast ${toastItem.id} tapped'),
        // onCloseButtonTap: (toastItem) =>
        //     print('Toast ${toastItem.id} close button tapped'),
        // onAutoCompleteCompleted: (toastItem) =>
        //     print('Toast ${toastItem.id} auto complete completed'),
        // onDismissed: (toastItem) => print('Toast ${toastItem.id} dismissed'),
      ),
    );
  }

  static void _showCustomToast({
    required BuildContext context,
    required String title,
    required String message,
    required Color backgroundColor,
  }) {
    toastification.showCustom(
      context: context,
      autoCloseDuration: const Duration(seconds: 15),
      alignment: Alignment.topRight,
      builder: (BuildContext context, ToastificationItem holder) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: backgroundColor,
          ),
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(message, style: const TextStyle(color: Colors.white)),
            ],
          ),
        );
      },
    );
  }
}
