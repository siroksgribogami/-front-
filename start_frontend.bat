@echo off
setlocal
chcp 65001 >nul

cd /d "%~dp0"

echo ==========================================
echo   ARTHOUSE FRONTEND START (Flutter)
echo ==========================================

if not exist "pubspec.yaml" (
  echo [ERROR] Не найден Flutter-проект в текущей папке.
  pause
  exit /b 1
)

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Команда flutter не найдена в PATH.
  echo Установи Flutter SDK и проверь: flutter doctor
  pause
  exit /b 1
)

set "API_BASE_URL=http://localhost:8000"

echo [1/3] Проверяю зависимости Flutter...
call flutter pub get
if errorlevel 1 (
  echo [ERROR] Не удалось выполнить flutter pub get.
  pause
  exit /b 1
)

echo [2/3] Запускаю фронт на Chrome...
echo [3/3] Команда: flutter run -d chrome --dart-define=API_BASE_URL=%API_BASE_URL%
call flutter run -d chrome --dart-define=API_BASE_URL=%API_BASE_URL%

:END
echo.
echo Фронтенд остановлен.
pause
