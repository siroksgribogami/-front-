# ARThouse Frontend

Flutter приложение для управления квартирами.

## Требования

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0

## Установка

1. Установите зависимости:
```bash
flutter pub get
```

2. Запустите бэкенд сервер (см. `art_back/README.md`)

3. При необходимости, отредактируйте URL API в `lib/config/api_config.dart`:
```dart
static const String baseUrl = 'http://127.0.0.1:8000';
```

## Запуск

### Web
```bash
flutter run -d chrome
```

### Android
```bash
flutter run -d android
```

### iOS
```bash
flutter run -d ios
```

### Windows
```bash
flutter run -d windows
```

## Структура проекта

```
lib/
├── config/              # Конфигурация (API, тема)
│   ├── api_config.dart
│   └── app_theme.dart
├── models/              # Модели данных
│   ├── user.dart
│   └── apartment.dart
├── services/            # API сервисы
│   ├── api_service.dart
│   ├── auth_service.dart
│   └── apartment_service.dart
├── providers/           # State management (Provider)
│   ├── auth_provider.dart
│   └── apartment_provider.dart
├── screens/             # UI экраны
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── apartments/
│   │   ├── apartments_list_screen.dart
│   │   ├── apartment_form_screen.dart
│   │   └── apartment_detail_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   └── profile/
│       └── profile_screen.dart
└── main.dart            # Точка входа
```

## Функциональность

### Аутентификация
- Регистрация нового пользователя
- Вход в систему
- Автоматическое сохранение токена
- Выход из аккаунта

### Квартиры
- Просмотр списка квартир
- Создание новой квартиры
- Редактирование квартиры
- Удаление квартиры
- Просмотр детальной информации

### Профиль
- Просмотр информации о пользователе
- Выход из аккаунта

## API Endpoints

Приложение работает с бэкендом по следующим эндпоинтам:

- `POST /api/v1/auth/register` - Регистрация
- `POST /api/v1/auth/login` - Вход
- `GET /api/v1/users/me` - Текущий пользователь
- `GET /api/v1/apartments/my` - Список квартир
- `POST /api/v1/apartments/my` - Создание квартиры
- `GET /api/v1/apartments/my/{id}` - Получение квартиры
- `PUT /api/v1/apartments/my/{id}` - Обновление квартиры
- `DELETE /api/v1/apartments/my/{id}` - Удаление квартиры

## Suggestions for a good README

Every project is different, so consider which of these sections apply to yours. The sections used in the template are suggestions for most open source projects. Also keep in mind that while a README can be too long and detailed, too long is better than too short. If you think your README is too long, consider utilizing another form of documentation rather than cutting out information.

## Name
Choose a self-explaining name for your project.

## Description
Let people know what your project can do specifically. Provide context and add a link to any reference visitors might be unfamiliar with. A list of Features or a Background subsection can also be added here. If there are alternatives to your project, this is a good place to list differentiating factors.

## Badges
On some READMEs, you may see small images that convey metadata, such as whether or not all the tests are passing for the project. You can use Shields to add some to your README. Many services also have instructions for adding a badge.

## Visuals
Depending on what you are making, it can be a good idea to include screenshots or even a video (you'll frequently see GIFs rather than actual videos). Tools like ttygif can help, but check out Asciinema for a more sophisticated method.

## Installation
Within a particular ecosystem, there may be a common way of installing things, such as using Yarn, NuGet, or Homebrew. However, consider the possibility that whoever is reading your README is a novice and would like more guidance. Listing specific steps helps remove ambiguity and gets people to using your project as quickly as possible. If it only runs in a specific context like a particular programming language version or operating system or has dependencies that have to be installed manually, also add a Requirements subsection.

## Usage
Use examples liberally, and show the expected output if you can. It's helpful to have inline the smallest example of usage that you can demonstrate, while providing links to more sophisticated examples if they are too long to reasonably include in the README.

## Support
Tell people where they can go to for help. It can be any combination of an issue tracker, a chat room, an email address, etc.

## Roadmap
If you have ideas for releases in the future, it is a good idea to list them in the README.

## Contributing
State if you are open to contributions and what your requirements are for accepting them.

For people who want to make changes to your project, it's helpful to have some documentation on how to get started. Perhaps there is a script that they should run or some environment variables that they need to set. Make these steps explicit. These instructions could also be useful to your future self.

You can also document commands to lint the code or run tests. These steps help to ensure high code quality and reduce the likelihood that the changes inadvertently break something. Having instructions for running tests is especially helpful if it requires external setup, such as starting a Selenium server for testing in a browser.

## Authors and acknowledgment
Show your appreciation to those who have contributed to the project.

## License
For open source projects, say how it is licensed.

## Project status
If you have run out of energy or time for your project, put a note at the top of the README saying that development has slowed down or stopped completely. Someone may choose to fork your project or volunteer to step in as a maintainer or owner, allowing your project to keep going. You can also make an explicit request for maintainers.
