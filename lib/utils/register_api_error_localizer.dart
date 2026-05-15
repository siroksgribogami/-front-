import '../services/api_service.dart';

/// Перевод типичных ответов FastAPI / Pydantic и текстов бэкенда на понятный русский.
abstract final class RegisterApiErrorLocalizer {
  RegisterApiErrorLocalizer._();

  static String localize(ApiException e) {
    final combined = _combinedLower(e);

    if (combined.contains("utf-8") && combined.contains("can't decode byte")) {
      return 'Ошибка кодировки на сервере регистрации (UTF-8). Это ошибка бэкенда/БД, не данных пользователя. Бэкенд нужно перезапустить с корректной UTF-8 конфигурацией.';
    }

    if (combined.contains('fe_sendauth') ||
        combined.contains('no password supplied') ||
        combined.contains('psycopg2.operationalerror')) {
      return 'Сервер регистрации не настроен: у бэкенда нет доступа к базе данных PostgreSQL (пароль не задан). Обратитесь к администратору или проверьте .env сервера.';
    }

    if (e.statusCode >= 500) {
      return 'Внутренняя ошибка сервера при регистрации. Попробуйте позже.';
    }

    final fromDetailList = _fromFastApiDetailList(e);
    if (fromDetailList != null) return fromDetailList;

    final raw = e.message.trim();
    if (raw.isNotEmpty && !_looksLikeUntranslatedPydantic(raw)) {
      return raw;
    }

    final mapped = _mapEnglishPatterns(combined);
    if (mapped != null) return mapped;

    return raw.isNotEmpty ? raw : 'Не удалось зарегистрироваться. Попробуйте ещё раз.';
  }

  static String _combinedLower(ApiException e) {
    final raw = e.message.toLowerCase();
    final details = e.details?.toString().toLowerCase() ?? '';
    return '$raw $details';
  }

  /// Разбор `detail: [{loc, msg, type, ctx}, ...]` от FastAPI 422.
  static String? _fromFastApiDetailList(ApiException e) {
    final details = e.details;
    if (details is! Map) return null;
    final d = details['detail'];
    if (d is! List || d.isEmpty) return null;

    final lines = <String>[];
    for (final item in d) {
      if (item is! Map) continue;
      final loc = item['loc'];
      final msg = item['msg']?.toString() ?? '';
      final field = _fieldLabelFromLoc(loc);
      final piece = _localizeFieldMessage(field, msg, item['ctx']);
      if (piece != null) lines.add(piece);
    }
    if (lines.isEmpty) return null;
    return lines.toSet().join('\n');
  }

  static String? _fieldLabelFromLoc(dynamic loc) {
    if (loc is! List || loc.isEmpty) return null;
    final last = loc.last?.toString().toLowerCase();
    switch (last) {
      case 'email':
        return 'Email';
      case 'username':
        return 'Имя';
      case 'password':
        return 'Пароль';
      default:
        return null;
    }
  }

  static String? _localizeFieldMessage(String? field, String msg, dynamic ctx) {
    final m = msg.toLowerCase();
    String base;

    if (m.contains('email') && m.contains('invalid')) {
      base = 'Укажите корректный адрес электронной почты';
    } else if (m.contains('string_too_short') || m.contains('at least') || m.contains('минимум')) {
      final min = _minLenFromCtx(ctx) ?? _minLenFromMessage(msg) ?? 6;
      if (field == 'Пароль') {
        base = 'Пароль: не менее $min символов';
      } else if (field == 'Имя') {
        base = 'Имя: не менее $min символов';
      } else {
        base = 'Слишком короткое значение (минимум $min символов)';
      }
    } else if (m.contains('string_too_long') || m.contains('at most')) {
      final max = _maxLenFromCtx(ctx) ?? 50;
      base = field != null ? '$field: не длиннее $max символов' : 'Слишком длинное значение (максимум $max символов)';
    } else if (m.contains('value is not a valid email')) {
      base = 'Укажите корректный email';
    } else {
      base = field != null ? '$field: $msg' : msg;
    }

    if (field != null && base.startsWith(field)) return base;
    if (field != null && !base.toLowerCase().contains(field.toLowerCase())) {
      return '$field — $base';
    }
    return base;
  }

  static int? _minLenFromCtx(dynamic ctx) {
    if (ctx is! Map) return null;
    final v = ctx['min_length'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static int? _maxLenFromCtx(dynamic ctx) {
    if (ctx is! Map) return null;
    final v = ctx['max_length'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static int? _minLenFromMessage(String msg) {
    final match = RegExp(r'(\d+)').firstMatch(msg);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }

  static bool _looksLikeUntranslatedPydantic(String s) {
    final l = s.toLowerCase();
    return l.contains('value error') ||
        l.contains('field required') ||
        l.contains('ensure this value') ||
        l.contains('string_too_short') ||
        l.contains('not a valid email');
  }

  static String? _mapEnglishPatterns(String combined) {
    if (combined.contains('already') && combined.contains('email')) {
      return 'Этот email уже зарегистрирован';
    }
    if (combined.contains('username') && combined.contains('taken')) {
      return 'Это имя пользователя уже занято';
    }
    if (combined.contains('invalid email')) {
      return 'Укажите корректный email';
    }
    return null;
  }
}
