# Unity Bridge

## Назначение

Этот документ фиксирует текущий рабочий мост между Flutter и Unity в проекте `art_front`.

Мост сделан поверх одного JSON-контракта и поддерживает три режима запуска Unity:

- Chrome / ПК через Unity WebGL и `iframe + postMessage`
- Android embedded host через `MethodChannel`
- Windows desktop player через файловый bridge

Во Flutter мост теперь доступен из основного экрана карты: `ApartmentEditorScreen` умеет собрать текущее состояние квартиры, отправить его в `UnityMapHostScreen` и принять обратно snapshot от Unity.

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

### Chrome / ПК

Flutter web поднимает iframe с `web/unity_bridge_host.html`.

Дальше команды идут так:

- Flutter -> `postMessage`
- host page -> `unityInstance.SendMessage(...)`
- Unity WebGL -> `.jslib` callback
- `.jslib` -> `window.parent.postMessage(...)`

Ожидаемый export лежит в:

- `art_front/web/unity_build/Build/ARTHOUSEMap.loader.js`
- `art_front/web/unity_build/Build/ARTHOUSEMap.framework.js`
- `art_front/web/unity_build/Build/ARTHOUSEMap.data`
- `art_front/web/unity_build/Build/ARTHOUSEMap.wasm`
- `art_front/web/unity_build/StreamingAssets/Models/*`

Для Unity добавлен builder:

- `ARTHouse/Build/Export WebGL For Flutter Web`

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

Нужен WebGL export Unity в `art_front/web/unity_build` через новый builder `ARTHouse/Build/Export WebGL For Flutter Web`.

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