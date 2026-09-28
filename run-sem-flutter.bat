@echo off
setlocal
cd /d "%~dp0"

echo =============================================
echo    HOTEL PARA PETS - RODAR SEM O FLUTTER
echo =============================================
echo.

rem Esse script e para quem nao tem o Flutter instalado.
rem Ele usa o site ja compilado pelo GitHub Actions (hotel-pets-web).
rem Primeiro eu procuro o site na pasta "site" do projeto
rem e, se nao achar, em Downloads\hotel-pets-web.
set "SITE=%~dp0site"
if not exist "%SITE%\index.html" set "SITE=%USERPROFILE%\Downloads\hotel-pets-web"

if not exist "%SITE%\index.html" (
  echo ERRO: nao achei o site compilado.
  echo.
  echo 1. Abra o repositorio no GitHub e va em Actions
  echo 2. Entre na execucao mais recente
  echo 3. Em Artifacts, baixe o hotel-pets-web
  echo 4. Extraia o conteudo na pasta "site", dentro deste projeto
  pause
  exit /b 1
)

echo Iniciando o back-end...
start "Hotel Pets - Back-End" cmd /k call "%~dp0run-backend.bat"

echo Iniciando o site...
start "Hotel Pets - Site" cmd /k "cd /d "%SITE%" && npx.cmd --yes http-server -p 8080 -c-1"

rem Espero os dois servidores subirem antes de abrir o navegador.
echo Aguardando os servidores subirem...
timeout /t 8 /nobreak >nul

start "" http://localhost:8080

echo.
echo Pronto! O sistema abriu em http://localhost:8080
echo Para parar, feche as janelas "Back-End" e "Site".
pause
