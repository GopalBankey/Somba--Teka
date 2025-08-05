// ignore_for_file: file_names

import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class ErrorFilter {
  final dynamic error;

  // static BuildContext? _context;
  ErrorFilter(this.error);


  static final Map<String, String> _errorKeyMap = {
    "network-request-failed": "networkRequestFailed",
    "app-not-authorized": "appNotAuthorized",
    "no-internet": "checkNetwork",
    "email-already-in-use": "emailAlreadyInUse",
    "wrong-password": "wrongPassword",
    "user-not-found": "emailNotRegistered",
    "invalid-email": "invalidEmail",
    "invalid-phone-number": "invalidPhoneNumber",
    "invalid-verification-code": "invalidVerificationCode",
    "session-expired": "sessionExpired",
    "too-many-requests": "tooManyRequests",
    "user-disabled": "userDisabled",
    "operation-not-allowed": "operationNotAllowed",
  };

  /// Returns the translated message based on FirebaseAuthException
  static String getTranslatedFirebaseAuthException(
    BuildContext context, {
    required FirebaseAuthException error,
  }) {
    final errorKey = getErrorKeyFromFirebaseAuthException(error);
    return errorKey.translate(context);
  }

  /// Returns just the error key (e.g., "userNotFound") for internal use or logging
  static String getErrorKeyFromFirebaseAuthException(
    FirebaseAuthException error,
  ) {
    return _errorKeyMap[error.code] ?? error.message ?? error.code;
  }
}
