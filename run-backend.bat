@echo off
setlocal
cd /d "%~dp0backend"

echo =============================================
echo       HOTEL PARA PETS - BACK-END
echo =============================================
echo.

rem Se ainda nao tiver o node_modules, eu instalo as dependencias antes.
if not exist "node_modules\express" (
  echo Instalando dependencias do Node.js...
  call npm.cmd install
  if errorlevel 1 (
    echo.
    echo ERRO: nao foi possivel instalar as dependencias.
    pause
    exit /b 1
  )
  echo.
)

echo Iniciando API...
echo API: http://localhost:3000
echo.
call npm.cmd start

pause
