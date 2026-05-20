/// Отображение контакта пользователя: телефон vs email.
/// При регистрации по телефону на бэке хранится служебный email
/// `7XXXXXXXXXX@phone.arthouse.app` — в UI показываем только номер.
abstract final class UserContactDisplay {
  UserContactDisplay._();

  static const String phoneEmailDomain = '@phone.arthouse.app';

  static bool isSyntheticPhoneEmail(String email) {
    return email.trim().toLowerCase().endsWith(phoneEmailDomain);
  }

  /// Нормализация для API: `+79XXXXXXXXX`.
  static String normalizePhoneForApi(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    var n = digits;
    if (n.length == 11 && n.startsWith('8')) {
      n = '7${n.substring(1)}';
    } else if (n.length == 10) {
      n = '7$n';
    }
    return '+$n';
  }

  /// Красивый формат: +7 (999) 123-45-67.
  static String formatPhoneRu(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('8')) {
      digits = '7${digits.substring(1)}';
    } else if (digits.length == 10) {
      digits = '7$digits';
    }
    if (digits.length != 11 || !digits.startsWith('7')) {
      return raw.trim();
    }
    return '+7 (${digits.substring(1, 4)}) '
        '${digits.substring(4, 7)}-'
        '${digits.substring(7, 9)}-'
        '${digits.substring(9, 11)}';
  }

  static String? phoneFromSyntheticEmail(String email) {
    if (!isSyntheticPhoneEmail(email)) return null;
    final local = email.split('@').first.trim();
    if (local.isEmpty) return null;
    return formatPhoneRu(local);
  }

  /// Для входа: если введён телефон — подставляем служебный email бэкенда.
  static String resolveLoginEmail(String raw) {
    final v = raw.trim();
    if (v.contains('@')) return v;
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return v;
    var n = digits;
    if (n.length == 11 && n.startsWith('8')) {
      n = '7${n.substring(1)}';
    } else if (n.length == 10) {
      n = '7$n';
    }
    return '$n$phoneEmailDomain';
  }
}
