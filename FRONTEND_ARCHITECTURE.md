# Frontend Architecture

## Назначение

Этот документ описывает реальную архитектуру фронтенда `art_front` в текущем состоянии проекта:

- точку входа приложения
- слои фронта
- управление состоянием
- shell-навигацию
- устройство экрана карты
- устройство общего 3D-вида квартиры в Chrome

Документ описывает то, что уже реализовано в коде, а не целевую идеальную архитектуру.

---

## 1. Точка входа приложения

Главная точка входа: `lib/main.dart`

Что происходит при старте:

1. Инициализируется Flutter binding.
2. Инициализируется русская локализация дат через `intl`.
3. Поднимается `ARThouseApp`.
4. Внутри `ARThouseApp` создаётся `MultiProvider`.
5. `AppRoot` решает, какой root-screen показать:
   - загрузку
   - auth flow
   - основной интерфейс приложения

Схема старта:

```text
main.dart
  -> ARThouseApp
    -> MultiProvider
      -> AppRoot
        -> HomeScreen | AuthFlow
```

---

## 2. Глобальные провайдеры

В `main.dart` поднимаются 4 глобальных `ChangeNotifierProvider`:

- `AuthProvider`
- `ApartmentProvider`
- `MapEditorProvider`
- `ThemeProvider`

Их роль:

- `AuthProvider` отвечает за авторизацию, пользователя и auth-state.
- `ApartmentProvider` отвечает за данные квартир и связанных сущностей уровня приложения.
- `MapEditorProvider` отвечает за доменные данные карты: комнаты, task list, адаптацию в map payload.
- `ThemeProvider` отвечает за тему и масштаб текста.

Это означает, что приложение построено на `provider`-архитектуре, а не на `bloc`, `riverpod` или redux-подобной схеме.

---

## 3. Корневой роутинг приложения

У приложения сейчас не полноценная URL-driven архитектура. Вместо этого используется shell-подход:

- `AppRoot` переключает между `AuthFlow` и `HomeScreen`
- `HomeScreen` держит левый sidebar и правый content-area
- контент переключается локально по `_currentIndex`

Фактически `HomeScreen` является контейнером верхнего уровня для feature-экранов.

Схема:

```text
AppRoot
  -> if loading      -> Splash/Loading UI
  -> if auth         -> HomeScreen
  -> if no auth      -> AuthFlow

HomeScreen
  -> TasksScreen
  -> MapScreen
  -> SearchScreen
  -> ChatScreen
  -> ProfileScreen
```

Плюсы такого подхода:

- простой shell
- мало навигационного шума
- быстро собирать desktop-like интерфейс

Минусы:

- слабая URL-навигация для web
- состояние вкладок сильнее привязано к дереву виджетов

---

## 4. Слои фронтенда

Фронт сейчас логически делится на 5 слоёв.

### 4.1. UI / Screens

Папка: `lib/screens/`

Задача слоя:

- рисовать интерфейс
- принимать пользовательские действия
- читать состояние из provider
- держать локальный UI-state

Примеры:

- `screens/auth/*`
- `screens/home/home_screen.dart`
- `screens/map/*`
- `screens/tasks/*`
- `screens/search/*`
- `screens/chat/*`
- `screens/profile/*`

### 4.2. Providers

Папка: `lib/providers/`

Задача слоя:

- быть источником состояния для UI
- уведомлять интерфейс через `notifyListeners()`
- связывать UI и сервисы

### 4.3. Services

Папка: `lib/services/`

Задача слоя:

- работа с backend API
- авторизация
- транспортный слой
- доступ к secure storage

Главный базовый сервис: `lib/services/api_service.dart`

### 4.4. Models

Папки:

- `lib/models/`
- `lib/screens/map/editor/scene/` для scene payload моделей

Задача слоя:

- описывать структуру данных
- быть контрактом между слоями
- уменьшать использование сырых `Map<String, dynamic>`

### 4.5. Config / Theme / Core

Папки:

- `lib/config/`
- `lib/core/theme/`

Задача слоя:

- общие константы
- тема
- типографика
- API config

---

## 5. Сервисный слой

### `ApiService`

Файл: `lib/services/api_service.dart`

Это базовый HTTP-клиент приложения.

Функции:

- хранение токена через `FlutterSecureStorage`
- подготовка заголовков
- методы `get/post/put/delete`
- преобразование ответа сервера
- выброс `ApiException` при ошибках

То есть остальные сервисы должны строиться поверх него, а не ходить в `http` напрямую.

### `AuthProvider` + `AuthService`

`AuthProvider` использует `AuthService` и даёт UI уже нормальное состояние:

- `initial`
- `loading`
- `authenticated`
- `unauthenticated`
- `error`

Это хороший паттерн для auth: экрану не нужно знать детали API, он знает только auth-state и данные пользователя.

---

## 6. Home Shell

Файл: `lib/screens/home/home_screen.dart`

`HomeScreen` это desktop-like shell приложения:

- слева sidebar
- справа активный экран

Сейчас по умолчанию открыт индекс `1`, то есть экран карты.

Это означает, что карта сейчас является центральной фичей интерфейса.

Sidebar содержит:

- задачи
- карта
- поиск
- чат
- профиль

Выбор экрана сейчас локальный и живёт в `_currentIndex`.

---

## 7. Архитектура feature-модуля карты

### 7.1. Точка входа карты

Файл: `lib/screens/map/map_screen.dart`

Сейчас `MapScreen` максимально тонкий:

```text
MapScreen -> ApartmentEditorScreen
```

То есть вся реальная логика карты находится глубже, внутри `ApartmentEditorScreen`.

### 7.2. Доменные данные карты

Файл: `lib/providers/map_editor_provider.dart`

`MapEditorProvider` хранит:

- список комнат `rooms`
- названия комнат
- иконки комнат
- task list по комнатам
- адаптацию карты в Unity payload
- применение снапшота обратно во фронт

Что важно: этот provider сейчас хранит не всё состояние редактора карты. Он хранит именно доменные данные комнат и задач.

### 7.3. Оркестратор карты

Файл: `lib/screens/map/editor/apartment_editor_screen.dart`

Это главный экран-оркестратор карты.

Он отвечает за:

- выбор активной комнаты
- локальное состояние toolbar и bottom sheet
- локальное размещение мебели по комнатам
- сборку payload для 3D-сцены
- отрисовку overlay UI поверх сцены

Локальный state внутри `ApartmentEditorScreen`:

- `_activeRoomIndex`
- `_toolbarMode`
- `_layoutChipIndex`
- `_activeTextureIndex`
- `_furnitureCategoryIndex`
- `_selectedFurnitureId`
- `_placedFurnitureByRoom`

То есть редактор карты сейчас построен по смешанной модели:

- доменные комнаты и задачи живут в `MapEditorProvider`
- editor UI-state и мебель живут локально внутри экрана

### 7.4. Каталог мебели

Файл: `lib/screens/map/editor/furniture_catalog.dart`

Каталог мебели играет роль справочника:

- id предмета
- название
- emoji
- размеры
- категория
- `glbFile`
- `modelUrl`

Этот файл является источником правды для доступной мебели на фронте.

---

## 8. Архитектура общего 3D-вида квартиры

Сейчас карта в Chrome построена как гибрид Flutter + WebGL.

Это ключевая часть архитектуры.

### 8.1. Главная идея

Flutter не рендерит саму квартиру как полноценную 3D-сцену.

Вместо этого:

- Flutter управляет приложением, UI и overlay
- реальный 3D-рендер квартиры делается в отдельной web-сцене на Three.js

Схема:

```text
ApartmentEditorScreen
  -> ApartmentScenePayload
    -> ApartmentSceneView
      -> iframe
        -> web/apartment_scene.html
          -> Three.js scene
```

### 8.2. Scene payload

Файл: `lib/screens/map/editor/scene/apartment_scene_models.dart`

Этот слой нужен как контракт между Flutter и Three.js.

Основные классы:

- `ApartmentScenePayload`
- `ApartmentSceneRoom`
- `ApartmentSceneFurniture`

В payload передаются:

- размеры сетки квартиры
- активная комната
- комнаты
- параметры мебели
- цвет
- `modelUrl`
- `rotationY`

Это очень важный слой, потому что он отделяет Flutter-часть от JS-runtime.

### 8.3. Flutter-side web bridge

Файл: `lib/screens/map/editor/scene/apartment_scene_view_web.dart`

Этот виджет:

- создаёт `iframe`
- загружает `apartment_scene.html`
- отправляет туда payload через `postMessage`
- слушает обратные события, например `roomTap`

То есть это bridge между Dart и браузерной 3D-сценой.

### 8.4. Three.js runtime

Файл: `web/apartment_scene.html`

Этот файл является отдельным runtime 3D-сцены.

Он отвечает за:

- создание `THREE.Scene`
- камеру
- свет
- тени
- управление обзором мышью
- raycasting по комнатам
- построение полов и стен
- загрузку `GLB` мебели через `GLTFLoader`
- fallback на box-геометрию, если модели нет
- отправку кликов обратно во Flutter

Это уже полноценный мини-рендерер карты внутри проекта.

---

## 9. Как идёт поток данных в карте

### Поток сверху вниз

```text
MapEditorProvider
  -> ApartmentEditorScreen
    -> ApartmentScenePayload
      -> ApartmentSceneView
        -> apartment_scene.html
          -> Three.js render
```

### Поток событий снизу вверх

```text
Three.js scene
  -> postMessage(roomTap)
    -> ApartmentSceneView
      -> ApartmentEditorScreen._selectRoom()
        -> новый payload
          -> перерендер сцены
```

### Поток мебели

```text
FurnitureCatalog
  -> пользователь выбирает предмет в bottom sheet
    -> ApartmentEditorScreen._addFurniture()
      -> _placedFurnitureByRoom
        -> ApartmentScenePayload.furniture
          -> GLB или fallback box в Three.js
```

---

## 10. Что у карты сейчас является источником правды

На данный момент источник правды разделён.

### В `MapEditorProvider`

- список комнат
- задачи комнат
- room metadata

### В `ApartmentEditorScreen`

- активная комната
- локальная расстановка мебели
- выбранный объект
- режимы нижней панели
- editor UI-state

Это рабочая архитектура, но не идеальная. При дальнейшем росте карты лучше вынести весь state карты в отдельный provider/store уровня feature.

---

## 11. Сильные стороны текущей архитектуры

### По приложению в целом

- простой и понятный старт приложения
- прозрачный `provider`-слой
- shell-подход хорошо подходит для desktop/web UI
- есть разделение между UI, provider и service

### По карте

- карта выделена как самостоятельная feature
- 3D вынесен в отдельный runtime, а не имитируется Flutter-виджетами
- Flutter overlay не смешан с 3D-геометрией
- есть явный payload между Dart и JS
- каталог мебели централизован

---

## 12. Архитектурный долг

### 12.1. Карта хранит состояние в двух местах

Сейчас состояние карты разделено между provider и экраном. Это усложнит:

- сохранение карты
- undo/redo
- синхронизацию с backend
- многократное открытие редактора

### 12.2. Нет единого `MapState`

Сейчас не хватает одного агрегирующего состояния уровня:

- комнаты
- мебель
- выделение
- материалы
- режим редактора
- сериализация карты

### 12.3. JS и Dart живут в двух разных мирах

Это нормально для web-3D, но минусы такие:

- сложнее отладка
- нет строгой типобезопасности на границе
- логика карты размазана между Flutter и HTML/JS

---

## 13. Рекомендуемое направление развития

Если развивать архитектуру дальше без слома проекта, логичный следующий шаг такой:

### Шаг 1. Вынести state карты в отдельный provider

Нужен отдельный store уровня feature, например:

`ApartmentMapProvider`

Он должен хранить:

- active room
- placed furniture
- selection
- layout materials
- editor mode
- serialization payload

### Шаг 2. Сделать `ApartmentEditorScreen` тоньше

Экран должен стать orchestration/UI layer, а не хранилищем всей логики.

### Шаг 3. Подготовить нормальную сериализацию карты

Чтобы можно было:

- сохранять состояние
- синхронизировать с backend
- отправлять scene state наружу
- подготавливать future Unity sync

---

## 14. Краткое резюме

Текущий фронт `art_front` это:

- Flutter shell-приложение
- state management через `provider`
- service layer поверх HTTP API
- feature-based организация экранов
- гибридная web-архитектура карты
- общий 3D-редактор квартиры в Chrome на базе Three.js

Ключевая мысль:

Фронт в целом остаётся Flutter-приложением, но модуль карты уже работает как отдельная embedded web-3D система, встроенная в Flutter через bridge между Dart и JavaScript.