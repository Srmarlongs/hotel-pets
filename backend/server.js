const express = require('express');
const cors = require('cors');
const fs = require('fs/promises');
const path = require('path');
const crypto = require('crypto');

const app = express();
const PORT = Number(process.env.PORT || 3000);

// Aqui eu defino onde os dados ficam salvos. Usei um arquivo JSON para não
// precisar instalar banco de dados só para o teste.
const DATA_DIR = path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'animals.json');

// Limite de caracteres que eu aceito nos campos de texto.
const MAX_TEXTO = 100;
const ESPECIES = ['Cachorro', 'Gato'];

// Tirei o header "X-Powered-By" para não mostrar que a API usa Express.
app.disable('x-powered-by');

// Eu só libero o CORS para o localhost (o Flutter Web abre numa porta
// aleatória) ou para um endereço que eu passar na variável ALLOWED_ORIGIN.
app.use(
  cors({
    origin(origin, callback) {
      const liberado =
        !origin ||
        /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin) ||
        origin === process.env.ALLOWED_ORIGIN;

      callback(null, liberado);
    },
  })
);

// Coloquei limite no tamanho do corpo da requisição para ninguém mandar
// um JSON gigante e travar o servidor.
app.use(express.json({ limit: '10kb' }));

app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  next();
});

// Cria a pasta e o arquivo de dados caso ainda não existam.
async function ensureDataFile() {
  await fs.mkdir(DATA_DIR, { recursive: true });
  try {
    await fs.access(DATA_FILE);
  } catch {
    await fs.writeFile(DATA_FILE, '[]', 'utf8');
  }
}

async function readAnimals() {
  await ensureDataFile();
  const content = await fs.readFile(DATA_FILE, 'utf8');
  if (!content.trim()) return [];

  const data = JSON.parse(content);
  if (!Array.isArray(data)) {
    throw new Error('O arquivo de dados precisa conter uma lista.');
  }
  return data;
}

// Primeiro eu salvo num arquivo temporário e depois renomeio. Assim, se der
// algum problema no meio da gravação, o arquivo original não corrompe.
async function writeAnimals(animals) {
  await ensureDataFile();
  const tempFile = DATA_FILE + '.tmp';
  await fs.writeFile(tempFile, JSON.stringify(animals, null, 2), 'utf8');
  await fs.rename(tempFile, DATA_FILE);
}

// Fila simples: como tudo fica num arquivo só, eu faço uma alteração de cada
// vez para duas requisições ao mesmo tempo não apagarem os dados uma da outra.
let fila = Promise.resolve();

function alterarAnimais(acao) {
  const tarefa = fila.then(async () => {
    const animals = await readAnimals();
    const resultado = await acao(animals);
    if (resultado && resultado.salvar) {
      await writeAnimals(animals);
    }
    return resultado;
  });

  fila = tarefa.catch(() => {});
  return tarefa;
}

// Converte "AAAA-MM-DD" para Date e confere se a data existe mesmo
// (ex: 2026-02-31 não passa).
function parseDateOnly(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return null;
  }

  const [year, month, day] = value.split('-').map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));

  if (
    date.getUTCFullYear() !== year ||
    date.getUTCMonth() !== month - 1 ||
    date.getUTCDate() !== day
  ) {
    return null;
  }

  return date;
}

// Pego a data de hoje no horário de Brasília, para as diárias não virarem
// antes da hora por causa do fuso do servidor.
function getTodayBrazil() {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: 'America/Sao_Paulo',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(new Date());

  const year = parts.find((part) => part.type === 'year').value;
  const month = parts.find((part) => part.type === 'month').value;
  const day = parts.find((part) => part.type === 'day').value;

  return `${year}-${month}-${day}`;
}

function daysBetween(startValue, endValue) {
  const start = parseDateOnly(startValue);
  const end = parseDateOnly(endValue);
  if (!start || !end) return null;

  const UM_DIA = 1000 * 60 * 60 * 24;
  return Math.floor((end.getTime() - start.getTime()) / UM_DIA);
}

// Antes de devolver o animal para o front eu já mando as diárias calculadas.
// Se a entrada for no futuro, as diárias até o momento ficam 0.
function serializeAnimal(animal) {
  const hoje = getTodayBrazil();
  const diariasAteHoje = daysBetween(animal.dataEntrada, hoje);

  let diariasTotais = null;
  if (animal.dataSaida) {
    diariasTotais = daysBetween(animal.dataEntrada, animal.dataSaida);
  }

  return {
    ...animal,
    diariasAteOMomento: Math.max(0, diariasAteHoje ?? 0),
    diariasTotaisPrevistas:
      diariasTotais === null ? null : Math.max(0, diariasTotais),
  };
}

function textoValido(valor) {
  const texto = String(valor ?? '').trim();
  return texto.length > 0 && texto.length <= MAX_TEXTO;
}

// Aqui eu valido tudo que chega do front. Mesmo o Flutter já validando,
// eu repito aqui porque a API pode ser chamada direto (Postman, curl...).
function validateAnimal(data) {
  const errors = [];

  if (!data || typeof data !== 'object' || Array.isArray(data)) {
    return ['Envie os dados do animal em formato JSON.'];
  }

  if (!textoValido(data.nome)) {
    errors.push(`O nome do animal é obrigatório (até ${MAX_TEXTO} caracteres).`);
  }

  if (!textoValido(data.nomeTutor)) {
    errors.push(`O nome do tutor é obrigatório (até ${MAX_TEXTO} caracteres).`);
  }

  // No contato eu aceito só números, espaço, parênteses, + e -.
  const contato = String(data.contatoTutor ?? '').trim();
  if (!/^[\d\s()+-]{8,20}$/.test(contato)) {
    errors.push('Informe um telefone válido para o tutor.');
  }

  if (!ESPECIES.includes(data.especie)) {
    errors.push('A espécie deve ser Cachorro ou Gato.');
  }

  if (!textoValido(data.raca)) {
    errors.push(`A raça é obrigatória (até ${MAX_TEXTO} caracteres).`);
  }

  const entrada = parseDateOnly(data.dataEntrada);
  if (!entrada) {
    errors.push('A data de entrada é inválida.');
  }

  // A data de saída é opcional, então só valido se vier preenchida.
  if (data.dataSaida !== null && data.dataSaida !== undefined && data.dataSaida !== '') {
    const saida = parseDateOnly(data.dataSaida);
    if (!saida) {
      errors.push('A data de saída é inválida.');
    } else if (entrada && saida < entrada) {
      errors.push('A data de saída não pode ser anterior à data de entrada.');
    }
  }

  return errors;
}

// Monto o objeto só com os campos que eu espero. Assim, se mandarem algum
// campo a mais no JSON, ele não vai parar no arquivo.
function montarAnimal(body) {
  return {
    nome: String(body.nome).trim(),
    nomeTutor: String(body.nomeTutor).trim(),
    contatoTutor: String(body.contatoTutor).trim(),
    especie: body.especie,
    raca: String(body.raca).trim(),
    dataEntrada: body.dataEntrada,
    dataSaida: body.dataSaida || null,
  };
}

app.get('/', (req, res) => {
  res.json({ message: 'Hotel para Pets API', status: 'online' });
});

// Lista todos os animais, do que entrou mais recente para o mais antigo.
app.get('/api/animals', async (req, res) => {
  try {
    const animals = await readAnimals();
    const result = animals
      .map(serializeAnimal)
      .sort((a, b) => b.dataEntrada.localeCompare(a.dataEntrada));

    res.json(result);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erro ao buscar os animais.' });
  }
});

// Busca um animal pelo id.
app.get('/api/animals/:id', async (req, res) => {
  try {
    const animals = await readAnimals();
    const animal = animals.find((item) => item.id === req.params.id);

    if (!animal) {
      return res.status(404).json({ message: 'Animal não encontrado.' });
    }

    res.json(serializeAnimal(animal));
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erro ao buscar o animal.' });
  }
});

// Cadastra um novo animal. O id eu gero aqui no back com randomUUID.
app.post('/api/animals', async (req, res) => {
  try {
    const errors = validateAnimal(req.body);
    if (errors.length) {
      return res.status(400).json({ message: 'Dados inválidos.', errors });
    }

    const agora = new Date().toISOString();
    const animal = {
      id: crypto.randomUUID(),
      ...montarAnimal(req.body),
      createdAt: agora,
      updatedAt: agora,
    };

    await alterarAnimais((animals) => {
      animals.push(animal);
      return { salvar: true };
    });

    res.status(201).json(serializeAnimal(animal));
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erro ao cadastrar o animal.' });
  }
});

// Atualiza um animal que já existe. Mantenho o id e o createdAt originais.
app.put('/api/animals/:id', async (req, res) => {
  try {
    const errors = validateAnimal(req.body);
    if (errors.length) {
      return res.status(400).json({ message: 'Dados inválidos.', errors });
    }

    const resultado = await alterarAnimais((animals) => {
      const index = animals.findIndex((item) => item.id === req.params.id);
      if (index === -1) return null;

      animals[index] = {
        ...animals[index],
        ...montarAnimal(req.body),
        updatedAt: new Date().toISOString(),
      };
      return { salvar: true, animal: animals[index] };
    });

    if (!resultado) {
      return res.status(404).json({ message: 'Animal não encontrado.' });
    }

    res.json(serializeAnimal(resultado.animal));
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erro ao atualizar o animal.' });
  }
});

// Exclui o animal pelo id.
app.delete('/api/animals/:id', async (req, res) => {
  try {
    const resultado = await alterarAnimais((animals) => {
      const index = animals.findIndex((item) => item.id === req.params.id);
      if (index === -1) return null;

      animals.splice(index, 1);
      return { salvar: true };
    });

    if (!resultado) {
      return res.status(404).json({ message: 'Animal não encontrado.' });
    }

    res.json({ message: 'Animal excluído com sucesso.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erro ao excluir o animal.' });
  }
});

// Qualquer rota que não existe cai aqui.
app.use((req, res) => {
  res.status(404).json({ message: 'Rota não encontrada.' });
});

// Tratamento de erros: JSON mal formatado, corpo grande demais ou qualquer
// outro erro. Não devolvo o erro completo para não expor detalhes internos.
app.use((error, req, res, next) => {
  if (error.type === 'entity.parse.failed') {
    return res.status(400).json({ message: 'JSON inválido.' });
  }

  if (error.type === 'entity.too.large') {
    return res.status(413).json({ message: 'Dados muito grandes.' });
  }

  console.error(error);
  res.status(500).json({ message: 'Erro interno no servidor.' });
});

// Só começo a ouvir a porta depois de garantir que o arquivo de dados existe.
ensureDataFile()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`Servidor rodando em http://localhost:${PORT}`);
    });
  })
  .catch((error) => {
    console.error('Não foi possível iniciar o servidor:', error);
    process.exit(1);
  });
