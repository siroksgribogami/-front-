/// Уровень «надёжности» пароля для подсказки пользователю (не криптостойкость).
/// Правила согласованы с минимальной схемой бэкенда (`min_length=6`) и усиливают политику на клиенте.
enum PasswordStrength {
  weak,
  medium,
  strong,
}

class PasswordRequirement {
  final String id;
  final String label;
  final bool satisfied;

  const PasswordRequirement({
    required this.id,
    required this.label,
    required this.satisfied,
  });
}

abstract final class PasswordValidation {
  PasswordValidation._();

  /// Как на бэкенде `UserCreate.password`: `Field(..., min_length=6)`.
  static const int minLength = 6;

  static List<PasswordRequirement> analyze(String password) {
    return [
      PasswordRequirement(
        id: 'len',
        label: 'Не менее $minLength символов',
        satisfied: password.length >= minLength,
      ),
      PasswordRequirement(
        id: 'latin',
        label: 'Буквы латиницы (A–z)',
        satisfied: RegExp(r'[A-Za-z]').hasMatch(password),
      ),
      PasswordRequirement(
        id: 'digit',
        label: 'Хотя бы одна цифра',
        satisfied: RegExp(r'[0-9]').hasMatch(password),
      ),
      PasswordRequirement(
        id: 'special',
        label: 'Спецсимвол (например ! @ # \$ %)',
        satisfied: RegExp(r'[^A-Za-z0-9]').hasMatch(password),
      ),
    ];
  }

  /// Для сообщения об ошибке при отправке формы (одна строка через запятую).
  static String unsatisfiedSummary(String password) {
    final pending = analyze(password).where((r) => !r.satisfied).map((r) => r.label).toList();
    return pending.join(', ');
  }

  static PasswordStrength strength(String password) {
    final reqs = analyze(password);
    final ok = reqs.where((r) => r.satisfied).length;
    if (password.length < minLength || ok <= 2) {
      return PasswordStrength.weak;
    }
    if (ok == reqs.length) {
      return PasswordStrength.strong;
    }
    return PasswordStrength.medium;
  }

  static bool isAcceptable(String password) {
    return analyze(password).every((r) => r.satisfied);
  }
}
