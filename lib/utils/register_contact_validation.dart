/// Валидация email и телефона при регистрации (одно поле «email или телефон»).
abstract final class RegisterContactValidation {
  RegisterContactValidation._();

  static bool looksLikeEmail(String value) {
    final v = value.trim();
    return v.contains('@') || RegExp(r'[A-Za-z]').hasMatch(v);
  }

  static String? validateEmail(String rawValue) {
    final email = rawValue.trim();
    if (email.isEmpty) return 'Введите email';

    if (email.length > 254) {
      return 'Длина email больше 254 символов';
    }

    if (email.contains(RegExp(r'\s'))) {
      return 'Пробелы в email недопустимы';
    }

    final atCount = '@'.allMatches(email).length;
    if (atCount != 1) {
      return 'В адресе должна быть ровно одна @';
    }

    final parts = email.split('@');
    final local = parts[0];
    final domain = parts[1];

    if (local.isEmpty) return 'Локальная часть email пустая';
    if (local.length > 64) return 'Локальная часть длиннее 64 символов';
    if (RegExp(r'[А-Яа-яЁё]').hasMatch(local)) {
      return 'Кириллица в локальной части недопустима';
    }
    if (local.startsWith('.') || local.endsWith('.')) {
      return 'Точка в начале или конце локальной части';
    }
    if (local.contains('..')) return 'Две точки подряд в локальной части';
    if (!RegExp(r'^[A-Za-z0-9._+\-]+$').hasMatch(local)) {
      return 'Недопустимые символы в локальной части';
    }

    if (domain.isEmpty) return 'Отсутствует домен';
    if (RegExp(r'[А-Яа-яЁё]').hasMatch(domain)) {
      return 'Кириллица в домене недопустима';
    }
    if (domain.startsWith('.') || domain.endsWith('.')) {
      return 'Точка в начале или конце домена';
    }
    if (domain.contains('..')) return 'Две точки подряд в домене';
    if (!RegExp(r'^[A-Za-z0-9.\-]+$').hasMatch(domain)) {
      return 'Недопустимые символы в домене';
    }
    if (!domain.contains('.')) {
      return 'В домене нет зоны (например .com, .ru)';
    }

    final tld = domain.split('.').last;
    if (tld.length < 2) return 'Доменная зона слишком короткая';

    const forbiddenDomains = {'example.com', 'test.com', 'localhost'};
    if (forbiddenDomains.contains(domain.toLowerCase())) {
      return 'Служебный домен недопустим';
    }

    return null;
  }

  static String? validatePhone(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) return 'Введите номер телефона';

    if (raw.contains('+') && !raw.startsWith('+')) {
      return 'Символ + допустим только в начале';
    }
    if (raw.startsWith('00')) return 'Используйте + вместо 00';
    if (RegExp(r'[A-Za-zА-Яа-яЁё]').hasMatch(raw)) {
      return 'Номер не должен содержать буквы';
    }
    if (RegExp(r"[^0-9+()\s\-]").hasMatch(raw)) {
      return 'Недопустимые символы в номере';
    }

    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Номер содержит менее 10 цифр';
    if (digits.length > 11) {
      return 'Неверная длина: нужно 10 или 11 цифр';
    }

    if (digits.length == 11) {
      final first = digits[0];
      if (first != '7' && first != '8') {
        return 'Номер должен начинаться с 7 или 8';
      }
      final normalized = (first == '8') ? '7${digits.substring(1)}' : digits;
      final code = normalized.substring(1, 4);
      if (!code.startsWith('9')) {
        return 'Код оператора должен начинаться с 9';
      }
      return null;
    }

    if (digits.length == 10) {
      if (!digits.startsWith('9')) {
        return 'Код оператора должен начинаться с 9';
      }
      return null;
    }

    return 'Неверная длина: нужно 10 или 11 цифр';
  }

  static String? validateContact(String rawValue) {
    final v = rawValue.trim();
    if (v.isEmpty) return 'Введите email или телефон';
    if (looksLikeEmail(v)) return validateEmail(v);
    return validatePhone(v);
  }

  /// Разбор контакта для API: email обязателен на бэке, для телефона — служебный email.
  static ({String email, String? phone}) parseForApi(String rawValue) {
    final v = rawValue.trim();
    if (looksLikeEmail(v)) {
      return (email: v, phone: null);
    }
    final digits = v.replaceAll(RegExp(r'\D'), '');
    final normalized = digits.length == 11 && digits.startsWith('8')
        ? '7${digits.substring(1)}'
        : digits;
    return (
      email: '$normalized@phone.arthouse.local',
      phone: v,
    );
  }
}
