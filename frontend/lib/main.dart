import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Endereço da API. Deixei o localhost como padrão, mas dá para trocar sem
// mexer no código: flutter run -d chrome --dart-define=API_URL=http://...
const String baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:3000',
);

// Tempo máximo que eu espero a API responder antes de mostrar erro.
const Duration timeout = Duration(seconds: 10);

void main() {
  runApp(const HotelPetsApp());
}

class HotelPetsApp extends StatelessWidget {
  const HotelPetsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotel para Pets',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      home: const HomePage(),
    );
  }
}

// Classe que representa o animal que vem da API.
// As diárias eu não calculo aqui, elas já vêm prontas do back-end.
class Animal {
  final String id;
  final String nome;
  final String nomeTutor;
  final String contatoTutor;
  final String especie;
  final String raca;
  final String dataEntrada;
  final String? dataSaida;
  final int diariasAteOMomento;
  final int? diariasTotaisPrevistas;

  const Animal({
    required this.id,
    required this.nome,
    required this.nomeTutor,
    required this.contatoTutor,
    required this.especie,
    required this.raca,
    required this.dataEntrada,
    required this.dataSaida,
    required this.diariasAteOMomento,
    required this.diariasTotaisPrevistas,
  });

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      nomeTutor: json['nomeTutor']?.toString() ?? '',
      contatoTutor: json['contatoTutor']?.toString() ?? '',
      especie: json['especie']?.toString() ?? '',
      raca: json['raca']?.toString() ?? '',
      dataEntrada: json['dataEntrada']?.toString() ?? '',
      dataSaida: json['dataSaida']?.toString(),
      diariasAteOMomento: (json['diariasAteOMomento'] as num?)?.toInt() ?? 0,
      diariasTotaisPrevistas: (json['diariasTotaisPrevistas'] as num?)?.toInt(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _tutorController = TextEditingController();
  final _contatoController = TextEditingController();
  final _racaController = TextEditingController();
  final _entradaController = TextEditingController();
  final _saidaController = TextEditingController();

  List<Animal> _animals = [];
  String _especie = 'Cachorro';

  // Quando _editingId é null o formulário está cadastrando.
  // Quando tem valor, estou editando o animal com esse id.
  String? _editingId;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _tutorController.dispose();
    _contatoController.dispose();
    _racaController.dispose();
    _entradaController.dispose();
    _saidaController.dispose();
    super.dispose();
  }

  // Transformo o erro em uma mensagem que dá para mostrar para o usuário.
  String _errorMessage(Object error) {
    if (error is TimeoutException) {
      return 'A API demorou para responder. Verifique se o back-end está rodando.';
    }
    if (error is http.ClientException) {
      return 'Não consegui conectar na API ($baseUrl).';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  // Busca a lista de animais no back-end.
  Future<void> _loadAnimals() async {
    setState(() {
      _loading = true;
    });

    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/animals')).timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Erro ao carregar os animais.');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw Exception('Resposta inválida da API.');
      }

      final animals = decoded
          .map((item) => Animal.fromJson(item as Map<String, dynamic>))
          .toList();

      if (!mounted) return;

      setState(() {
        _animals = animals;
      });
    } catch (e) {
      _showMessage(_errorMessage(e), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // Uso o mesmo método para cadastrar (POST) e para editar (PUT).
  Future<void> _saveAnimal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    final saida = _saidaController.text.trim();
    final payload = {
      'nome': _nomeController.text.trim(),
      'nomeTutor': _tutorController.text.trim(),
      'contatoTutor': _contatoController.text.trim(),
      'especie': _especie,
      'raca': _racaController.text.trim(),
      'dataEntrada': _entradaController.text.trim(),
      'dataSaida': saida.isEmpty ? null : saida,
    };

    try {
      final creating = _editingId == null;
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode(payload);

      final http.Response response;
      if (creating) {
        response = await http
            .post(Uri.parse('$baseUrl/api/animals'), headers: headers, body: body)
            .timeout(timeout);
      } else {
        response = await http
            .put(Uri.parse('$baseUrl/api/animals/$_editingId'),
                headers: headers, body: body)
            .timeout(timeout);
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(_readApiError(response));
      }

      _clearForm();
      await _loadAnimals();

      _showMessage(
        creating
            ? 'Animal cadastrado com sucesso!'
            : 'Animal atualizado com sucesso!',
      );
    } catch (e) {
      _showMessage(_errorMessage(e), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // Quando a API devolve erro de validação, ela manda uma lista "errors".
  // Aqui eu junto tudo numa mensagem só.
  String _readApiError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body['errors'] is List && (body['errors'] as List).isNotEmpty) {
          return (body['errors'] as List).join('\n');
        }
        if (body['message'] != null) {
          return body['message'].toString();
        }
      }
    } catch (_) {
      // Se a resposta não for JSON, cai na mensagem padrão lá embaixo.
    }
    return 'Erro ao salvar.';
  }

  // Antes de excluir eu pergunto se a pessoa tem certeza.
  Future<void> _deleteAnimal(Animal animal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir animal'),
          content: Text('Deseja realmente excluir o registro de ${animal.nome}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/api/animals/${animal.id}'))
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Não foi possível excluir o animal.');
      }

      // Se eu estava editando justamente esse animal, limpo o formulário.
      if (_editingId == animal.id) {
        _clearForm();
      }

      await _loadAnimals();
      _showMessage('Animal excluído com sucesso!');
    } catch (e) {
      _showMessage(_errorMessage(e), isError: true);
    }
  }

  // Joga os dados do card no formulário para editar.
  void _editAnimal(Animal animal) {
    setState(() {
      _editingId = animal.id;
      _nomeController.text = animal.nome;
      _tutorController.text = animal.nomeTutor;
      _contatoController.text = animal.contatoTutor;
      _racaController.text = animal.raca;
      _entradaController.text = animal.dataEntrada;
      _saidaController.text = animal.dataSaida ?? '';
      _especie = animal.especie == 'Gato' ? 'Gato' : 'Cachorro';
    });
  }

  void _clearForm() {
    _nomeController.clear();
    _tutorController.clear();
    _contatoController.clear();
    _racaController.clear();
    _entradaController.clear();
    _saidaController.clear();

    if (!mounted) return;

    setState(() {
      _editingId = null;
      _especie = 'Cachorro';
    });
  }

  // Abre o calendário e salva a data no formato AAAA-MM-DD, que é o
  // formato que a API espera.
  Future<void> _pickDate(TextEditingController controller) async {
    final firstDate = DateTime(2020);
    final lastDate = DateTime(2100);

    DateTime initialDate = DateTime.tryParse(controller.text) ?? DateTime.now();
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (date == null) return;

    controller.text = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  // Mostra a data para o usuário no formato brasileiro (DD/MM/AAAA).
  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  // Campo de texto obrigatório com limite de 100 caracteres
  // (o mesmo limite que coloquei no back-end).
  Widget _textField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      maxLength: 100,
      decoration: _decoration(label).copyWith(counterText: ''),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Preencha este campo.';
        }
        return null;
      },
    );
  }

  Widget _phoneField() {
    return TextFormField(
      controller: _contatoController,
      keyboardType: TextInputType.phone,
      maxLength: 20,
      decoration: _decoration('Contato do Tutor').copyWith(
        hintText: '(31) 99999-9999',
        counterText: '',
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return 'Preencha este campo.';
        if (!RegExp(r'^[\d\s()+-]{8,20}$').hasMatch(text)) {
          return 'Digite um telefone válido.';
        }
        return null;
      },
    );
  }

  Widget _dateField(
    TextEditingController controller,
    String label, {
    bool optional = false,
    String? Function(DateTime date)? extraValidator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _pickDate(controller),
      decoration: _decoration(label).copyWith(
        suffixIcon: const Icon(Icons.calendar_month),
      ),
      validator: (value) {
        if (optional && (value == null || value.trim().isEmpty)) {
          return null;
        }
        final date = DateTime.tryParse(value ?? '');
        if (date == null) {
          return 'Selecione uma data válida.';
        }
        return extraValidator?.call(date);
      },
    );
  }

  // A saída prevista não pode ser antes da entrada.
  String? _validateSaida(DateTime saida) {
    final entrada = DateTime.tryParse(_entradaController.text);
    if (entrada != null && saida.isBefore(entrada)) {
      return 'A saída não pode ser antes da entrada.';
    }
    return null;
  }

  Widget _buildForm() {
    final editing = _editingId != null;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                editing ? 'Editar hospedagem' : 'Nova hospedagem',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              _textField(_nomeController, 'Nome do animal'),
              const SizedBox(height: 12),
              _textField(_tutorController, 'Nome do Tutor'),
              const SizedBox(height: 12),
              _phoneField(),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _especie,
                decoration: _decoration('Espécie'),
                items: const [
                  DropdownMenuItem(value: 'Cachorro', child: Text('Cachorro')),
                  DropdownMenuItem(value: 'Gato', child: Text('Gato')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _especie = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              _textField(_racaController, 'Raça'),
              const SizedBox(height: 12),
              _dateField(_entradaController, 'Data de entrada'),
              const SizedBox(height: 12),
              _dateField(
                _saidaController,
                'Previsão de data de saída',
                optional: true,
                extraValidator: _validateSaida,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _saving ? null : _saveAnimal,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(editing ? Icons.save : Icons.add),
                label: Text(
                  _saving
                      ? 'Salvando...'
                      : editing
                          ? 'Salvar alterações'
                          : 'Cadastrar animal',
                ),
              ),
              if (editing) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _clearForm,
                  child: const Text('Cancelar edição'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Um item de informação dentro do card (ícone + título + valor).
  Widget _infoItem(String title, String value, IconData icon) {
    return SizedBox(
      width: 220,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Card de cada animal hospedado, com os botões de editar e excluir.
  Widget _animalCard(Animal animal) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.pets)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animal.nome,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${animal.especie} • ${animal.raca}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Editar',
                  onPressed: () => _editAnimal(animal),
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  tooltip: 'Excluir',
                  onPressed: () => _deleteAnimal(animal),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _infoItem('Tutor', animal.nomeTutor, Icons.person_outline),
                _infoItem('Contato', animal.contatoTutor, Icons.phone_outlined),
                _infoItem(
                  'Entrada',
                  _formatDate(animal.dataEntrada),
                  Icons.login,
                ),
                _infoItem(
                  'Diárias até o momento',
                  '${animal.diariasAteOMomento}',
                  Icons.hotel,
                ),
                _infoItem(
                  'Saída prevista',
                  animal.dataSaida == null
                      ? 'Não informada'
                      : _formatDate(animal.dataSaida!),
                  Icons.logout,
                ),
                _infoItem(
                  'Diárias totais previstas',
                  animal.diariasTotaisPrevistas == null
                      ? 'Não aplicável'
                      : '${animal.diariasTotaisPrevistas}',
                  Icons.calculate_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_animals.isEmpty) {
      return const Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pets, size: 48, color: Colors.black38),
                SizedBox(height: 10),
                Text('Nenhum animal hospedado.'),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Animais hospedados',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            Chip(label: Text('${_animals.length}')),
            const Spacer(),
            IconButton(
              tooltip: 'Atualizar',
              onPressed: _loadAnimals,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._animals.map(_animalCard),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.pets),
            SizedBox(width: 8),
            Text('Hotel para Pets'),
          ],
        ),
      ),
      // Na tela grande eu coloco o formulário do lado da lista.
      // Na tela pequena fica um embaixo do outro.
      // Cada lado tem sua rolagem para não estourar quando tiver muitos animais.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1100;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: desktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 414,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 24, 0, 24),
                            child: _buildForm(),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
                            child: _buildList(),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildForm(),
                        const SizedBox(height: 24),
                        _buildList(),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
