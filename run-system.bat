@echo off
cd /d "%~dp0"

echo =============================================
echo          HOTEL PARA PETS - SISTEMA
echo =============================================
echo.

rem Abro o back-end numa janela e o front-end em outra.
echo Iniciando o back-end...
start "Hotel Pets - Back-End" cmd /k call "%~dp0run-backend.bat"

rem Espero uns segundos para a API subir antes de abrir o Flutter.
timeout /t 5 /nobreak >nul

echo Iniciando o front-end...
start "Hotel Pets - Front-End" cmd /k call "%~dp0run-frontend.bat"
