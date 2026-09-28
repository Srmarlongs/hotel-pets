# Hotel para Pets

Fiz essa aplicação web para controlar os animais hospedados em um hotel para pets.
Nela dá para cadastrar, ver, editar e excluir os animais.

## Tecnologias que eu usei

- **Front-End:** Flutter Web
- **Back-End:** Node.js com Express
- **Dados:** um arquivo JSON local (`backend/data/animals.json`), que a API cria sozinha quando sobe

## O que o sistema faz

- Cadastro, listagem, edição e exclusão (com confirmação antes de excluir)
- Nome e contato do tutor
- Espécie (Cachorro ou Gato) e raça
- Data de entrada e previsão de saída (a saída é opcional)
- Diárias até o momento (calculadas automaticamente)
- Diárias totais previstas (calculadas quando tem data de saída)
- Layout que se ajusta ao tamanho da tela

## O que precisa ter instalado

- Node.js 18 ou superior
- Flutter SDK (stable)
- Google Chrome

## Como eu organizei as pastas

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
├── .github/workflows/ci.yml
├── run-system.bat
├── run-sem-flutter.bat
├── run-backend.bat
├── run-frontend.bat
└── README.md
```

Deixei o back-end e o front-end em pastas separadas no mesmo repositório para ficar mais fácil de baixar e rodar tudo junto.

## Como rodar

### Windows (jeito mais fácil)

É só dar dois cliques no `run-system.bat`. Ele abre uma janela para o back-end e outra para o Flutter, e o Chrome abre sozinho.

### Windows sem o Flutter instalado

Se a máquina não tiver o Flutter (ou ele estiver bloqueado), dá para usar o site que o GitHub Actions já compila:

1. Na aba **Actions** do repositório, abra a execução mais recente
2. Em **Artifacts**, baixe o **hotel-pets-web**
3. Extraia o conteúdo numa pasta `site`, dentro do projeto
4. Dê dois cliques no `run-sem-flutter.bat`

Ele sobe o back-end, sobe o site e abre `http://localhost:8080`. Para esse jeito só precisa do Node.js.

### Rodando na mão

Back-End:

```bash
cd backend
npm install
npm start
```

A API fica em `http://localhost:3000`.

Front-End (em outro terminal):

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

Se a API estiver em outro endereço, eu deixei dar para trocar sem mexer no código:

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

Exemplo do JSON que eu mando para cadastrar:

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

## Decisões que eu tomei

**Por que arquivo JSON e não banco de dados?**
O teste é pequeno e eu quis que quem for avaliar consiga rodar sem instalar e configurar um banco. O JSON resolve bem para esse tamanho. Se o sistema fosse crescer, eu trocaria por um banco (SQLite ou PostgreSQL, por exemplo), e só as funções `readAnimals` e `writeAnimals` precisariam mudar.

**Como eu calculei as diárias?**
Considerei a diária como a diferença em dias entre as datas. Por exemplo:

```text
Entrada: 20/09/2026
Saída prevista: 27/09/2026
Total previsto: 7 diárias
```

- **Diárias até o momento:** diferença entre a entrada e hoje. Se a entrada for uma data futura (reserva), fica 0.
- **Diárias totais previstas:** diferença entre a entrada e a saída prevista. Se não tiver saída, mostro "Não aplicável".

**Por que o cálculo fica no back-end?**
Assim o valor sai igual para qualquer tela que usar a API, e eu não preciso salvar as diárias no arquivo. Elas são recalculadas toda vez que alguém consulta, então estão sempre atualizadas. Também uso a data de hoje no horário de Brasília, para a diária não virar antes da hora se o servidor estiver em outro fuso.

**Por que as datas vão no formato `AAAA-MM-DD`?**
É um formato padrão, fácil de validar e de ordenar. Na tela eu mostro no formato brasileiro (DD/MM/AAAA).

**Por que validar no front e no back?**
No Flutter a validação é para o usuário ver o erro na hora, sem esperar a API. No back-end é para garantir, porque a API pode ser chamada direto (pelo Postman, por exemplo), sem passar pela tela.

**Por que uma tela só?**
Coloquei o formulário e a lista na mesma tela para o uso ficar rápido: clico em editar no card e os dados já aparecem no formulário do lado. Em tela pequena, o formulário fica em cima e a lista embaixo.

## Segurança

Algumas coisas que eu fiz para a API não aceitar qualquer coisa:

- Valido todos os campos no back-end, e não confio só na validação do Flutter
- Coloquei limite de tamanho nos textos e no corpo da requisição
- Só salvo os campos que eu espero (se mandarem campos a mais no JSON, eles são ignorados)
- Deixei o CORS liberado só para `localhost` (ou para o endereço da variável `ALLOWED_ORIGIN`)
- As mensagens de erro não mostram detalhes internos do servidor
- Salvo o arquivo de um jeito que não corrompe se der problema no meio, e faço uma alteração de cada vez
- O arquivo de dados fica fora do Git, porque tem nome e telefone dos tutores

## Testes automáticos

Configurei o GitHub Actions para rodar a cada commit. Ele sobe a API e testa se ela responde, e também analisa e compila o Flutter Web. O resultado aparece na aba **Actions**.

## O que eu melhoraria com mais tempo

- Trocar o JSON por um banco de dados
- Colocar login para os funcionários do hotel
- Criar testes unitários para o cálculo das diárias
- Adicionar busca e filtro na lista (por tutor ou espécie, por exemplo)
- Adicionar máscara no campo de telefone
