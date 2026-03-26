# Unity Bridge

## Назначение

Мост между Flutter и Unity в проекте `art_front`. **Во фронте нет встроенной реализации карты на Unity** — только контракт и канал связи, чтобы Flutter и Unity могли работать вместе (Unity подключается отдельно).

Режимы:

- **Web (Chrome/ПК):** iframe с `unity_bridge_host.html` — **не загружает Unity WebGL**. Страница поднимает только мост (postMessage). Unity можно подключить отдельно через `window.ArthouseFlutterBridge.registerUnity(sendMessage)`.
- **Android:** embedded host через `MethodChannel` (при наличии unityLibrary).
- **Windows desktop:** отдельный Unity player (.exe) и файловый bridge.

`ApartmentEditorScreen` собирает состояние квартиры, открывает `UnityMapHostScreen` и по мосту отправляет/принимает snapshot.

## Основные файлы Flutter

- `lib/models/unity/unity_map_contract.dart`
- `lib/services/unity/unity_map_bridge_service.dart`
- `lib/services/unity/unity_map_desktop_service.dart`
- `lib/services/unity/unity_map_desktop_service_io.dart`
- `lib/screens/map/unity/unity_map_host_screen.dart`
- `lib/screens/map/unity/unity_map_web_surface.dart`
- `lib/screens/map/unity/unity_map_web_surface_web.dart`
- `lib/screens/map/editor/apartment_editor_screen.dart`

## Основные файлы Unity

- `map/Assets/Scripts/Core/MapContracts.cs`
- `map/Assets/Scripts/Core/FlutterUnityMapBridge.cs`
- `map/Assets/Plugins/WebGL/ArthouseFlutterBridge.jslib`
- `map/Assets/Scripts/Editor/MapEditorBootstrap.cs`
- `map/Assets/Editor/WindowsExportBuilder.cs`
- `map/Assets/Editor/AndroidExportBuilder.cs`
- `map/Assets/Editor/WebGLExportBuilder.cs`

## Канонический контракт

Flutter и Unity синхронизируются через одну структуру `UnityApartmentMapData` / `ApartmentMapData`.

Верхний уровень JSON:

```json
{
  "apartmentId": "arthouse_demo_apartment",
  "apartmentName": "ARTHouse Demo Apartment",
  "rooms": [],
  "tasks": []
}
```

Комната содержит:

- `roomId`
- `displayName`
- `gridSize`
- `floorMaterialId`
- `wallMaterialId`
- `walls`
- `openings`
- `stairs`
- `furniture`

Элемент мебели содержит:

- `instanceId`
- `roomId`
- `templateId`
- `displayName`
- `category`
- `gridPosition`
- `footprint`
- `rotationQuarterTurns`
- `supportsStackingAbove`
- `requiresSupportSurface`
- `blocksPlacement`
- `parentFurnitureInstanceId`
- `elevation`

Задача содержит:

- `taskId`
- `roomId`
- `furnitureInstanceId`
- `title`
- `description`
- `status`

## Команды моста

Поддерживаемые команды одинаковы для WebGL, Android и Windows desktop:

- `initializeEditor`
- `focusRoom`
- `undo`
- `redo`
- `requestSnapshot`

### Android

Flutter вызывает Unity через `MethodChannel` `arthouse/unity_map_bridge`.

Unity отправляет snapshot обратно через Android callback class:

- `com.arthouse.art_front.UnityBridgeCallbacks`

### Chrome / ПК (только мост)

Flutter web открывает iframe с `web/unity_bridge_host.html`. Эта страница **не загружает Unity WebGL** (нет loader.js, нет createUnityInstance). Работает только мост:

- Flutter → `postMessage` в iframe
- host обрабатывает команды и при наличии зарегистрированного Unity вызывает его (см. ниже)
- ответы/snapshot → `window.parent.postMessage` во Flutter

Чтобы подключить Unity к мосту (например, свой WebGL build в другой вкладке или на том же origin):

```js
window.ArthouseFlutterBridge.registerUnity(function(gameObject, method, argument) {
  // вызвать Unity: например unityInstance.SendMessage(gameObject, method, argument);
});
```

Также доступны: `notifyReady()` (когда Unity готов), `pushSnapshot(roomId, snapshotJson)` (отправка snapshot во Flutter).

### Windows desktop

Flutter запускает Unity `.exe` с аргументом:

```text
--arthouse-bridge-dir <path>
```

Внутри этой директории используются два файла:

- `command.json`
- `snapshot.json`

`command.json` содержит:

```json
{
  "token": "unique_command_id",
  "method": "initializeEditor",
  "payload": "{...json map...}",
  "roomId": "living_room"
}
```

`snapshot.json` содержит:

```json
{
  "roomId": "living_room",
  "snapshotJson": "{...json map...}"
}
```

## Текущая интеграция в UI

`ApartmentEditorScreen` остается главным экраном карты и общего 3D-вида квартиры.

Теперь он дополнительно умеет:

- собрать локальную мебель из общего редактора в `UnityFurnitureItem`
- отправить текущую квартиру в `UnityMapHostScreen`
- принять snapshot из Unity
- обновить `MapEditorProvider`
- восстановить мебель назад в Flutter-редактор

Это важно: Unity-мост не создает второй источник истины. На вход и на выход используется один и тот же JSON-контракт квартиры.

## Что еще нужно для полного runtime

### Android

Нужен экспорт `unityLibrary` и реальная регистрация platform view / method channel на Android-стороне Flutter host.

### Chrome / ПК

Во фронте только мост; WebGL-билд Unity во Flutter не встраивается. Чтобы использовать Unity на вебе, подключите его через `ArthouseFlutterBridge.registerUnity(sendMessage)` (например, со своей страницы с Unity WebGL).

### Windows

Нужен собранный Unity player в:

`map/Builds/Windows`

Предпочтительное имя exe уже поддержано во Flutter:

- `ARTHOUSEMap.exe`
- `ARTHouseMap.exe`
- `ARTHOUSE.exe`
- `UnityMap.exe`

## Практический сценарий работы

1. Пользователь открывает карту во Flutter.
2. Flutter показывает общий 3D-вид квартиры.
3. Кнопка `Unity bridge` открывает host-экран Unity.
4. Flutter передает в Unity полный snapshot квартиры.
5. Unity редактирует карту и мебель.
6. По `Применить` snapshot возвращается во Flutter.
7. Flutter обновляет комнаты, задачи и мебель в основном редакторе.