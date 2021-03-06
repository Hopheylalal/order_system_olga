import 'package:ordersystem/common/platform_alert_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

class PlatformExceptionAlertDialog extends PlatformAlertDialog {
  PlatformExceptionAlertDialog({
    @required String title,
    @required PlatformException exception,
  }) : super(
            title: title,
            content: _message(exception),
            defaultActionText: 'OK');

  static String _message(PlatformException exception) {
    return _errors[exception.code] ?? exception.message;
  }

  static Map<String, String> _errors = {
    'ERROR_INVALID_VERIFICATION_CODE' : 'Неверный смс код.',
    'ERROR_WEAK_PASSWORD': 'Увеличьте длину пароля.',
    'ERROR_INVALID_EMAIL' : 'Некорректный email адрес',
    'ERROR_INVALID_CREDENTIAL': 'If the email address is malformed.',
    'ERROR_EMAIL_ALREADY_IN_USE':
        'Этот почтовый ящик уже используется другим пользователем',
    'ERROR_WRONG_PASSWORD': 'Неверный пароль',
    'ERROR_USER_NOT_FOUND':
        'Такой почтовый ящик не найден.',
    'ERROR_USER_DISABLED':
        'If the user has been disabled (for example, in the Firebase console)',
    'ERROR_TOO_MANY_REQUESTS':
        'If there was too many attempts to sign in as this user.',
    'ERROR_OPERATION_NOT_ALLOWED':
        'Indicates that Email & Password accounts are not enabled.'
  };
}
