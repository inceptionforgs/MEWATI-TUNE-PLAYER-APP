import 'package:flutter/material.dart';
import '../constants/app_strings.dart';

class ErrorHandler {
  static String getMessage(dynamic error) {
    if (error == null) {
      return AppStrings.somethingWentWrong;
    }

    if (error is String) {
      return error;
    }

    if (error is Exception) {
      String errorString = error.toString();
      if (errorString.startsWith('Exception: ')) {
        errorString = errorString.substring('Exception: '.length);
      }
      return errorString;
    }

    String errorString = error.toString();

    if (errorString.isEmpty) {
      return AppStrings.somethingWentWrong;
    }

    if (errorString.contains('SocketException') ||
        errorString.contains('Failed host lookup') ||
        errorString.contains('Network is unreachable')) {
      return AppStrings.noInternet;
    }

    return errorString;
  }

  static void showSnackBar(BuildContext context, dynamic error) {
    final message = getMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}