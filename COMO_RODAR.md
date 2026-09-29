# Como rodar o sistema (passo a passo)

Escrevi esse guia para quem for avaliar o projeto conseguir rodar sem dor de cabeça.
Coloquei aqui o jeito mais fácil e também o passo a passo pelo CMD e pelo PowerShell,
porque enquanto eu testava passei por alguns erros e deixei no final como eu resolvi cada um.

O sistema tem duas partes que precisam ficar rodando **ao mesmo tempo**:

- **Back-End (API em Node.js):** roda em `http://localhost:3000`
- **Front-End (Flutter Web):** abre no Chrome

Por isso sempre uso **duas janelas de terminal**: uma para cada parte.

---

## 1. O que precisa estar instalado

| Programa | Versão | Como eu confiro |
|---|---|---|
| Node.js | 18 ou superior | `node -v` |
| Flutter SDK | stable (3.24 ou superior) | `flutter --version` |
| Google Chrome | qualquer versão recente | — |

Se o `flutter --version` não funcionar, veja a seção 5 (rodar sem o Flutter).

---

## 2. Jeito mais fácil (Windows)

1. Baixe o projeto (botão verde **Code → Download ZIP**) e extraia.
2. Entre na pasta do projeto.
3. Dê dois cliques em **`run-system.bat`**.

Ele abre uma janela para o back-end e outra para o Flutter, e o Chrome abre sozinho.
Na primeira vez demora alguns minutos porque o Flutter compila tudo.

Se o Windows bloquear o `.bat` ou ele não funcionar, siga o passo a passo pelo CMD ou pelo PowerShell abaixo.

---

## 3. Passo a passo pelo CMD (Prompt de Comando)

> Para abrir o CMD: aperte `Win + R`, digite `cmd` e dê Enter.

Nos exemplos eu considero que o projeto foi extraído em `Downloads\hotel-pets-master`.
Se estiver em outro lugar, é só trocar o caminho.

### Janela 1 — Back-End

```cmd
cd /d "%USERPROFILE%\Downloads\hotel-pets-master\backend"
npm install
npm start
```

Tem que aparecer:

```text
Servidor rodando em http://localhost:3000
```

**Deixe essa janela aberta e não digite mais nada nela.**

### Janela 2 — Front-End

Abra **outro** CMD:

```cmd
cd /d "%USERPROFILE%\Downloads\hotel-pets-master\frontend"
flutter pub get
flutter run -d chrome
```

O Chrome abre sozinho com o sistema.

---

## 4. Passo a passo pelo PowerShell

> Para abrir o PowerShell: aperte `Win + R`, digite `powershell` e dê Enter.

No PowerShell os comandos são um pouco diferentes do CMD:

- não existe o `cd /d` → uso só `cd`
- `%USERPROFILE%` vira `$env:USERPROFILE`
- uso `npm.cmd` no lugar de `npm`, porque em muitos Windows o PowerShell bloqueia scripts `.ps1` e o `npm` normal dá erro

### Janela 1 — Back-End

```powershell
cd "$env:USERPROFILE\Downloads\hotel-pets-master\backend"
npm.cmd install
npm.cmd start
```

Tem que aparecer `Servidor rodando em http://localhost:3000`. **Deixe essa janela aberta.**

### Janela 2 — Front-End

Abra **outro** PowerShell:

```powershell
cd "$env:USERPROFILE\Downloads\hotel-pets-master\frontend"
flutter pub get
flutter run -d chrome
```

---

## 5. Rodando sem o Flutter

Caso não consiga usar o Flutter (não está instalado ou está bloqueado na máquina, como aconteceu no meu computador do trabalho), dá para usar o site que o GitHub Actions já compila a cada commit. Assim só precisa do Node.js.

### Passo 1 — Baixar o site pronto

1. No repositório, clique na aba **Actions**
2. Clique na execução mais recente (a primeira da lista, com o check verde)
3. Role até o final da página, na parte **Artifacts**
4. Clique em **hotel-pets-web** para baixar o ZIP

### Passo 2 — Extrair

Extraia o ZIP numa pasta `site` dentro do projeto (ou em `Downloads\hotel-pets-web`).
Dentro da pasta tem que aparecer o arquivo `index.html`.

Pelo PowerShell dá para extrair assim:

```powershell
cd "$env:USERPROFILE\Downloads"
Expand-Archive ".\hotel-pets-web.zip" ".\hotel-pets-web" -Force
```

### Passo 3 — Rodar

**Jeito fácil:** dois cliques em **`run-sem-flutter.bat`**. Ele sobe o back-end, sobe o site e abre o navegador.

**Pelo PowerShell (duas janelas):**

Janela 1 — Back-End:

```powershell
cd "$env:USERPROFILE\Downloads\hotel-pets-master\backend"
npm.cmd install
npm.cmd start
```

Janela 2 — Site:

```powershell
cd "$env:USERPROFILE\Downloads\hotel-pets-web"
npx.cmd http-server -p 8080 -c-1
```

Se perguntar `Ok to proceed? (y)`, digite `y` e Enter.

Depois é só abrir no Chrome: **http://localhost:8080**

**Pelo CMD:** é igual, só trocando o começo:

```cmd
cd /d "%USERPROFILE%\Downloads\hotel-pets-web"
npx http-server -p 8080 -c-1
```

---

## 6. Mac ou Linux

Os `.bat` são só para Windows, mas os comandos funcionam igual no terminal:

```bash
# Terminal 1
cd backend
npm install
npm start

# Terminal 2
cd frontend
flutter pub get
flutter run -d chrome
```

---

## 7. Erros que eu encontrei e como resolvi

**`Cannot find module 'express'`**
As dependências do back-end não foram instaladas (acontece sempre que baixa o projeto de novo).
Rode `npm install` (ou `npm.cmd install` no PowerShell) dentro da pasta `backend` e depois `npm start`.

**`Deseja finalizar o arquivo em lotes (S/N)?`**
Aparece quando aperta `Ctrl + C` no CMD. No terminal, `Ctrl + C` **para o servidor**, não copia texto.
Responda `N` e, se o servidor parou, rode `npm start` de novo. Para copiar texto, selecione com o mouse e use o botão direito.

**`cd : Não é possível localizar um parâmetro posicional...`**
Foi um comando do CMD (`cd /d` ou `%USERPROFILE%`) usado no PowerShell. Use os comandos da seção 4.

**`'Select-Object' não é reconhecido como um comando interno`**
Foi o contrário: comando do PowerShell no CMD. Digite `powershell` e Enter para trocar, ou use os comandos da seção 3.

**`npm : O arquivo ... npm.ps1 não pode ser carregado`**
O PowerShell está bloqueando scripts. Use `npm.cmd` e `npx.cmd` no lugar de `npm` e `npx`.

**`A sintaxe do comando está incorreta`**
Geralmente acontece quando o texto do caminho (`C:\Users\...>`) vai junto ao colar o comando. Digite só o comando.

**`EADDRINUSE: address already in use`**
A porta já está sendo usada, normalmente por uma janela do servidor que ficou aberta.
Feche as janelas antigas ou use outra porta (ex.: `-p 8081` no site).

**Tela abre mas aparece "Não consegui conectar na API"**
O back-end não está rodando. Abra a janela 1 de novo e rode `npm start`.

**`flutter` não é reconhecido**
O Flutter não está no PATH. Dá para adicionar só na janela atual:

```cmd
set PATH=%PATH%;C:\caminho\do\flutter\bin
```

```powershell
$env:Path += ";C:\caminho\do\flutter\bin"
```

Ou use o `run-frontend.bat`, que procura o Flutter nas pastas mais comuns.

**`dart.exe foi bloqueado pela política do Device Guard`** ou **"Controle de Aplicativo Inteligente bloqueou um arquivo"**
É uma regra de segurança do próprio Windows/empresa, não um erro do projeto.
Nesse caso eu usei o caminho da seção 5 (site já compilado + comandos no PowerShell), que só precisa do Node.js.

**O `npx http-server` mostrou uma lista de pastas no navegador em vez do sistema**
O comando rodou na pasta errada. Confira se o `cd` funcionou e se a pasta tem o `index.html` (dá para ver com `dir`).

---

## 8. Resumo rápido

| Situação | O que eu faço |
|---|---|
| Tenho Node e Flutter no Windows | Dois cliques em `run-system.bat` |
| O `.bat` foi bloqueado | Seção 3 (CMD) ou seção 4 (PowerShell) |
| Não tenho o Flutter | Seção 5 (site pronto do GitHub Actions) |
| Mac ou Linux | Seção 6 |
| Deu erro | Seção 7 |
