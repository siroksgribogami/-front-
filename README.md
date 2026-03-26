# ARTHOUSE Frontend

Flutter-клиент для ARTHOUSE: авторизация, onboarding, карта, задачи, чат, профиль и поиск специалистов.

## Что есть в проекте

- адаптивный UI (mobile/web)
- auth flow (register/login/welcome/survey)
- профиль и настройки внешнего вида
- экран задач и создание задачи
- карта/редактор помещения
- чат и поиск специалистов

## Технологии

- Flutter 3.x
- Dart 3.x
- Provider (state management)
- HTTP API (FastAPI backend)

---

## Требования

- Flutter SDK `>= 3.0.0`
- Dart SDK `>= 3.0.0`
- Запущенный backend из `art_back` (см. `art_back/README.md`)

---

## Установка и запуск

### 1) Установить зависимости

```bash
flutter pub get
```

### 2) Запустить backend

```bash
cd ../art_back
python run.py
```

### 3) Запустить frontend

Из папки `art_front`:

```bash
flutter run
```

---

## Настройка API URL

По умолчанию:

- Web/Desktop: `http://127.0.0.1:8000`
- Android emulator: `http://10.0.2.2:8000`

Для реального Android-устройства используйте `dart-define`:

```bash
flutter run -d <device_id> --dart-define=API_BASE_URL=http://192.168.1.100:8000
```

Где `192.168.1.100` — IP вашего ПК в той же Wi-Fi сети.

---

## Доступные платформы

- Web: `flutter run -d chrome`
- Android: `flutter run -d android`
- iOS: `flutter run -d ios`
- Windows: `flutter run -d windows`

---

## Структура проекта

```text
art_front/
├── lib/
│   ├── config/           # API + тема
│   ├── core/             # общие виджеты/утилиты
│   ├── models/           # модели данных
│   ├── providers/        # состояние приложения
│   ├── services/         # API сервисы
│   ├── screens/          # экраны
│   └── main.dart
├── android/
├── ios/
├── web/
├── pubspec.yaml
└── README.md
```

---

## API, которые использует клиент

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/users/me`
- `PUT /api/v1/users/me`
- `GET /api/v1/apartments/my`
- `POST /api/v1/apartments/my`
- `GET /api/v1/apartments/my/{id}`
- `PUT /api/v1/apartments/my/{id}`
- `DELETE /api/v1/apartments/my/{id}`

Примечание: задачи на фронте уже подготовлены к API, но на бэкенде роут `tasks` должен быть включен и поддержан моделью.

---

## Частые проблемы

### `SocketException` / сервер недоступен

- backend не запущен
- неверный `API_BASE_URL`
- телефон и ПК не в одной сети
- firewall блокирует порт `8000`

### Android-устройство не подключается к API

- используйте IP ПК, не `127.0.0.1` и не `10.0.2.2`
- запускайте с:
  - `--dart-define=API_BASE_URL=http://<IP_ПК>:8000`

### Ошибка сборки Flutter

```bash
flutter clean
flutter pub get
flutter run
```

---

## Рекомендации по развитию

- включить и стабилизировать backend `tasks` API
- связать задачи карты (`room_id`) с backend
- добавить e2e smoke-flow: register -> login -> create apartment -> create task
