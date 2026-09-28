@echo off
setlocal
cd /d "%~dp0frontend"

echo =============================================
echo       HOTEL PARA PETS - FRONT-END
echo =============================================
echo.

rem Primeiro eu vejo se o Flutter esta no PATH.
where flutter >nul 2>nul
if not errorlevel 1 goto rodar

rem Se nao estiver, procuro nas pastas mais comuns.
for %%P in ("%USERPROFILE%\Downloads\flutter\bin" "%USERPROFILE%\develop\flutter\bin" "C:\src\flutter\bin" "C:\flutter\bin") do (
  if exist "%%~P\flutter.bat" (
    set "PATH=%PATH%;%%~P"
    goto rodar
  )
)

echo ERRO: nao encontrei o Flutter.
echo Instale o Flutter ou adicione a pasta flutter\bin no PATH.
pause
exit /b 1

:rodar
echo Baixando dependencias do Flutter...
call flutter pub get
if errorlevel 1 (
  echo.
  echo ERRO: nao foi possivel baixar as dependencias.
  pause
  exit /b 1
)

echo.
echo Abrindo no Chrome...
call flutter run -d chrome

pause
