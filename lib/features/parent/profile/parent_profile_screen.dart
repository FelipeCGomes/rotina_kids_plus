import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // IMPORT NOVO
import '../../../data/services/auth_provider.dart';

class ParentProfileScreen extends ConsumerStatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  ConsumerState<ParentProfileScreen> createState() =>
      _ParentProfileScreenState();
}

class _ParentProfileScreenState extends ConsumerState<ParentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  bool _isLoading = true;
  bool _isSaving = false;

  String _selectedGender = 'Prefiro não informar';
  DateTime? _birthDate;

  // --- MODO DO APARELHO (Agora Local) ---
  String _deviceMode = 'parent';

  List<Map<String, dynamic>> _linkedEmails = [];

  final List<String> _categories = [
    'Pai',
    'Mãe',
    'Tio',
    'Tia',
    'Avó',
    'Avô',
    'Medica',
    'Professora',
    'Instrutor',
    'Outros',
  ];

  final List<String> _genders = [
    'Masculino',
    'Feminino',
    'Outros',
    'Prefiro não informar',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadProfileData();
  }

  int? get _calculatedAge {
    if (_birthDate == null) return null;
    final today = DateTime.now();
    int age = today.year - _birthDate!.year;
    if (today.month < _birthDate!.month ||
        (today.month == _birthDate!.month && today.day < _birthDate!.day)) {
      age--;
    }
    return age;
  }

  Future<void> _loadProfileData() async {
    final user = ref.read(authStateProvider).value;

    if (user != null) {
      try {
        // 1. CARREGA DADOS DO FIREBASE (Nome, Idade, Emails)
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            _nameController.text = data['name'] ?? user.displayName ?? '';
            _selectedGender = data['gender'] ?? 'Prefiro não informar';

            if (data['birthDate'] != null) {
              _birthDate = DateTime.parse(data['birthDate']);
            }

            if (data['linkedEmails'] != null) {
              _linkedEmails = List<Map<String, dynamic>>.from(
                data['linkedEmails'],
              );
            }
          });
        } else {
          setState(() {
            _nameController.text = user.displayName ?? '';
          });
        }

        // 2. CARREGA O MODO DO APARELHO (Memória Local)
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          // Se não existir, o padrão é 'parent'
          _deviceMode = prefs.getString('local_device_mode') ?? 'parent';
        });
      } catch (e) {
        debugPrint('Erro ao carregar perfil: $e');
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final user = ref.read(authStateProvider).value;

    if (user != null) {
      try {
        // 1. SALVA DADOS NO FIREBASE (Menos o deviceMode)
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'gender': _selectedGender,
          'birthDate': _birthDate?.toIso8601String(),
          'linkedEmails': _linkedEmails,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        // 2. SALVA O MODO DO APARELHO NA MEMÓRIA LOCAL
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('local_device_mode', _deviceMode);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil e configurações atualizados!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    setState(() => _isSaving = false);
  }

  Future<void> _deleteAccount() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;

      final childrenSnapshot = await firestore
          .collection('children')
          .where('parentId', isEqualTo: user.uid)
          .get();

      for (var childDoc in childrenSnapshot.docs) {
        final tasksSnapshot = await firestore
            .collection('tasks')
            .where('childId', isEqualTo: childDoc.id)
            .get();
        for (var taskDoc in tasksSnapshot.docs) {
          await taskDoc.reference.delete();
        }
        await childDoc.reference.delete();
      }

      await firestore.collection('users').doc(user.uid).delete();
      await user.delete();

      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao excluir. Por segurança, faça logout, entre novamente e tente excluir. ($e)',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text('Atenção!', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: const Text(
          'Tem a certeza absoluta de que pretende excluir a sua conta?\n\n'
          'Esta ação é IRREVERSÍVEL. Todos os seus dados, assim como os perfis, rotinas, avatares e moedas de TODAS AS CRIANÇAS serão perdidos para sempre.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAccount();
            },
            child: const Text(
              'Sim, Excluir Tudo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEmailDialog() {
    final emailController = TextEditingController();
    String selectedCategory = 'Outros';
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Vincular Novo E-mail'),
            content: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Quem é essa pessoa?',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedCategory = val!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Digite um e-mail';
                      if (!val.contains('@')) return 'E-mail inválido';
                      if (_linkedEmails.any((e) => e['email'] == val.trim())) {
                        return 'E-mail já vinculado';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (dialogFormKey.currentState!.validate()) {
                    setState(() {
                      _linkedEmails.add({
                        'email': emailController.text.trim(),
                        'category': selectedCategory,
                      });
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Adicionar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _birthDate = picked);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final canAddMore = _linkedEmails.length < 7;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          if (!_isLoading)
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.check, size: 30),
                    tooltip: 'Salvar',
                    onPressed: _saveProfile,
                  ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (user != null) ...[
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue[100],
                        backgroundImage: user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                        child: user.photoURL == null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.blue,
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.email ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],

                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Configuração deste Aparelho',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Como o bloqueio de aplicativos deve se comportar neste celular/tablet?',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text(
                              'Celular do Responsável',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Bloqueio pausado. Ativa apenas se a criança iniciar uma sessão de jogo.',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: 'parent',
                            groupValue: _deviceMode,
                            activeColor: Colors.deepPurple,
                            secondary: const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.deepPurple,
                            ),
                            onChanged: (val) =>
                                setState(() => _deviceMode = val!),
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: const Text(
                              'Aparelho da Criança',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Bloqueio sempre ativo. Consome o tempo do perfil diretamente.',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: 'child',
                            groupValue: _deviceMode,
                            activeColor: Colors.blue,
                            secondary: const Icon(
                              Icons.child_care,
                              color: Colors.blue,
                            ),
                            onChanged: (val) =>
                                setState(() => _deviceMode = val!),
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: const Text(
                              'Compartilhado (Várias Crianças)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Ao abrir um app, o sistema pergunta quem vai jogar e pede a senha (PIN).',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: 'shared',
                            groupValue: _deviceMode,
                            activeColor: Colors.orange,
                            secondary: const Icon(
                              Icons.devices,
                              color: Colors.orange,
                            ),
                            onChanged: (val) =>
                                setState(() => _deviceMode = val!),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Dados do Responsável',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Seu Nome',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'O nome é obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedGender,
                            decoration: const InputDecoration(
                              labelText: 'Sexo',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: _genders
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedGender = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data Nasc.',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              child: Text(
                                _birthDate == null
                                    ? 'Selecione'
                                    : DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_birthDate!),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_calculatedAge != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Idade: $_calculatedAge anos',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rede de Apoio',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        Text(
                          '${_linkedEmails.length}/7',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: canAddMore ? Colors.grey : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Adicione familiares ou profissionais que também poderão acompanhar e aprovar as tarefas.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    if (_linkedEmails.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Nenhuma conta vinculada.',
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _linkedEmails.length,
                        itemBuilder: (context, index) {
                          final item = _linkedEmails[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.supervised_user_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                item['email'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                item['category'],
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => setState(
                                  () => _linkedEmails.removeAt(index),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: canAddMore
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: Text(
                          canAddMore
                              ? 'Vincular Novo E-mail'
                              : 'Limite de 7 e-mails atingido',
                        ),
                        onPressed: canAddMore ? _showAddEmailDialog : null,
                      ),
                    ),

                    const SizedBox(height: 60),
                    const Divider(),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.delete_forever),
                        label: const Text(
                          'Excluir Conta e Todos os Dados',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _showDeleteConfirmation,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
