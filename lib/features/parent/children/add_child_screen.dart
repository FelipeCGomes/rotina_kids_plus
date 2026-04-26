import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../data/models/child_model.dart';
import '../../../data/services/child_providers.dart';

class AddChildScreen extends ConsumerStatefulWidget {
  final ChildModel? childToEdit;
  const AddChildScreen({super.key, this.childToEdit});

  @override
  ConsumerState<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends ConsumerState<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _pinController;

  DateTime _selectedBirthDate = DateTime.now().subtract(
    const Duration(days: 365 * 5),
  );
  String _selectedSex = 'Masculino';
  bool _isStudying = false;
  String? _selectedEducationLevel;
  String _selectedAvatar = 'avatar_boy';
  List<String> _selectedDisorders = [];

  final Map<String, String> _disorderLegends = {
    'TEA':
        'TEA: Foco em comunicação, interação social e padrões comportamentais repetitivos.',
    'TDAH': 'TDAH: Foco em desatenção, hiperatividade e impulsividade.',
    'TOD':
        'TOD: Foco em comportamento opositivo, desafiador e hostil, contra figuras de autoridade.',
    'DI':
        'Deficiência Intelectual (DI): Pode acompanhar o TEA, afetando o desenvolvimento cognitivo.',
    'TOC':
        'TOC (Transtorno Obsessivo-Compulsivo): Pensamentos intrusivos e rituais repetitivos.',
    'TAG':
        'TAG (Transtorno de Ansiedade Generalizada): Ansiedade excessiva e constante.',
    'TPAC':
        'TPAC (Transtorno de Processamento Auditivo Central): Dificuldade em interpretar sons.',
  };

  @override
  void initState() {
    super.initState();
    final c = widget.childToEdit;
    // Inicializa os campos com os dados existentes se for edição
    _nameController = TextEditingController(text: c?.name ?? '');
    _lastNameController = TextEditingController(text: c?.lastName ?? '');
    _pinController = TextEditingController(text: c?.pinCode ?? '');

    if (c != null) {
      _selectedBirthDate = c.birthDate;
      _selectedSex = c.sex;
      _isStudying = c.isStudying;
      _selectedEducationLevel = c.educationLevel;
      _selectedAvatar = c.avatarId;
      _selectedDisorders = List.from(c.disorders);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final child = ChildModel(
      id:
          widget.childToEdit?.id ??
          '', // Se tiver ID, mantém para atualizar. Se não, cria novo.
      parentId: user.uid,
      name: _nameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      birthDate: _selectedBirthDate,
      sex: _selectedSex,
      disorders: _selectedDisorders,
      isStudying: _isStudying,
      educationLevel: _isStudying ? _selectedEducationLevel : null,
      avatarId: _selectedAvatar,
      currentXp: widget.childToEdit?.currentXp ?? 0,
      totalXp: widget.childToEdit?.totalXp ?? 0,
      level: widget.childToEdit?.level ?? 1,
      pinCode: _pinController.text.trim().isEmpty
          ? null
          : _pinController.text.trim(),
    );

    try {
      // Chama o serviço que agora lida com create/update automaticamente
      await ref.read(childServiceProvider).saveChild(child);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Perfil?'),
        content: const Text(
          'Isso apagará todos os dados e o progresso. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(childServiceProvider)
                  .deleteChild(widget.childToEdit!.id);
              if (mounted) {
                Navigator.pop(ctx); // Fecha o alerta
                context.pop(); // Volta para o Dashboard
              }
            },
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.childToEdit == null ? 'Cadastrar Filho' : 'Editar Perfil',
        ),
        actions: [
          if (widget.childToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: _confirmDelete,
              tooltip: 'Excluir Perfil',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Dados Básicos'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Sobrenome',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Nascimento: ${DateFormat('dd/MM/yyyy').format(_selectedBirthDate)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedBirthDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _selectedBirthDate = date);
                },
              ),

              const Text('Sexo:'),
              Row(
                children: [
                  Radio(
                    value: 'Masculino',
                    groupValue: _selectedSex,
                    onChanged: (v) =>
                        setState(() => _selectedSex = v.toString()),
                  ),
                  const Text('Masculino'),
                  Radio(
                    value: 'Feminino',
                    groupValue: _selectedSex,
                    onChanged: (v) =>
                        setState(() => _selectedSex = v.toString()),
                  ),
                  const Text('Feminino'),
                ],
              ),

              const Divider(height: 40),
              _buildSectionTitle('Saúde e Desenvolvimento'),
              const Text(
                'Assinale se houver diagnóstico:',
                style: TextStyle(color: Colors.grey),
              ),
              Wrap(
                children: _disorderLegends.keys.map((key) {
                  return SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: CheckboxListTile(
                      title: Text(key, style: const TextStyle(fontSize: 14)),
                      value: _selectedDisorders.contains(key),
                      onChanged: (val) {
                        setState(() {
                          if (val!) {
                            _selectedDisorders.add(key);
                          } else {
                            _selectedDisorders.remove(key);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  );
                }).toList(),
              ),

              if (_selectedDisorders.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _selectedDisorders
                        .map(
                          (d) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _disorderLegends[d]!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),

              const Divider(height: 40),
              _buildSectionTitle('Escolaridade'),
              SwitchListTile(
                title: const Text('Estuda atualmente?'),
                value: _isStudying,
                onChanged: (v) => setState(() => _isStudying = v),
              ),
              if (_isStudying)
                DropdownButtonFormField<String>(
                  initialValue: _selectedEducationLevel,
                  decoration: const InputDecoration(
                    labelText: 'Nível de Ensino',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      [
                            'Educação Infantil 1º período',
                            'Educação Infantil 2º período',
                            'Ensino Fundamental',
                            'Ensino Médio',
                          ]
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _selectedEducationLevel = v),
                ),

              const SizedBox(height: 30),
              _buildSectionTitle('Segurança'),
              TextFormField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Senha do Perfil (4 dígitos)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                ),
                child: Text(
                  widget.childToEdit == null
                      ? 'SALVAR PERFIL'
                      : 'ATUALIZAR PERFIL',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }
}
