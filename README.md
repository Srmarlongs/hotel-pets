# Hotel para Pets

Aplicação web para controle de animais hospedados em um hotel para pets.
Dá para cadastrar, visualizar, editar e excluir os animais.

## Tecnologias

- Front-End: Flutter Web
- Back-End: Node.js + Express
- Dados: arquivo JSON local (`backend/data/animals.json`), criado automaticamente quando a API sobe

## Funcionalidades

- Cadastro, listagem, edição e exclusão (com confirmação)
- Nome e contato do tutor
- Espécie (Cachorro ou Gato) e raça
- Data de entrada e previsão de saída (opcional)
- Diárias até o momento (calculadas automaticamente)
- Diárias totais previstas (calculadas quando tem data de saída)
- Layout que se ajusta ao tamanho da tela

## Requisitos

- Node.js 18 ou superior
- Flutter SDK (stable)
- Google Chrome

## Estrutura

```text
hotel-pets/
├── backend/
│   ├── package.json
│   └── server.js
├── frontend/
│   ├── lib/
│   │   └── main.dart
│   ├── web/
│   └── pubspec.yaml
├── run-system.bat
├── run-sem-flutter.bat
├── run-backend.bat
├── run-frontend.bat
└── README.md
```

## Como rodar

### Windows (jeito mais fácil)

Dar dois cliques em `run-system.bat`. Ele abre uma janela para o back-end e outra para o Flutter.

### Windows sem o Flutter instalado

Se não tiver o Flutter (ou ele estiver bloqueado na máquina), dá para usar o site já compilado pelo GitHub Actions:

1. Na aba **Actions** do repositório, abra a execução mais recente
2. Em **Artifacts**, baixe o **hotel-pets-web**
3. Extraia o conteúdo numa pasta `site`, dentro do projeto
4. Dê dois cliques em `run-sem-flutter.bat`

Ele sobe o back-end, sobe o site e abre `http://localhost:8080` no navegador. Precisa só do Node.js.

### Back-End

```bash
cd backend
npm install
npm start
```

A API fica em `http://localhost:3000`.

### Front-End

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

Se a API estiver em outro endereço:

```bash
flutter run -d chrome --dart-define=API_URL=http://meu-servidor:3000
```

## Endpoints da API

| Método | Rota               | O que faz               |
|--------|--------------------|-------------------------|
| GET    | /api/animals       | Lista os animais        |
| GET    | /api/animals/:id   | Busca um animal         |
| POST   | /api/animals       | Cadastra um animal      |
| PUT    | /api/animals/:id   | Atualiza um animal      |
| DELETE | /api/animals/:id   | Exclui um animal        |

Exemplo de cadastro:

```json
{
  "nome": "Thor",
  "nomeTutor": "João da Silva",
  "contatoTutor": "(31) 99999-9999",
  "especie": "Cachorro",
  "raca": "Golden Retriever",
  "dataEntrada": "2026-09-20",
  "dataSaida": "2026-09-27"
}
```

## Cálculo das diárias

Eu considerei a diária como a diferença em dias entre as datas:

```text
Entrada: 20/09/2026
Saída prevista: 27/09/2026
Total previsto: 7 diárias
```

As diárias até o momento são calculadas pela API usando a data atual no horário de Brasília.
Se a entrada for uma data futura, fica 0.

## Segurança

Algumas coisas que eu fiz para a API não aceitar qualquer coisa:

- Validação de todos os campos no back-end (não confio só na validação do Flutter)
- Limite de tamanho nos textos e no corpo da requisição
- Só salvo os campos esperados (campos extras no JSON são ignorados)
- CORS liberado só para `localhost` (ou para o endereço da variável `ALLOWED_ORIGIN`)
- Mensagens de erro sem mostrar detalhes internos do servidor
- O arquivo de dados fica fora do Git, porque tem nome e telefone dos tutores
