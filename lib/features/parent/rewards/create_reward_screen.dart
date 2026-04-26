import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/reward_model.dart';
import '../../../data/services/reward_providers.dart';
import '../../../data/services/child_providers.dart';

class CreateRewardScreen extends ConsumerStatefulWidget {
  final RewardModel? rewardToEdit;
  const CreateRewardScreen({super.key, this.rewardToEdit});

  @override
  ConsumerState<CreateRewardScreen> createState() => _CreateRewardScreenState();
}

class _CreateRewardScreenState extends ConsumerState<CreateRewardScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _xpController;
  late TextEditingController _durationController;

  String _selectedType = 'Tempo livre';
  bool _isLoading = false;
  bool _requiresApproval = true;
  bool _isTimeBased = false;

  final List<String> _rewardTypes = [
    'Tempo de app',
    'Tempo livre',
    'Recompensa manual',
    'Presente',
    'Atividade em família',
    'Acessório do avatar',
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.rewardToEdit;

    _titleController = TextEditingController(text: r?.title ?? '');
    _descController = TextEditingController(text: r?.description ?? '');
    _xpController = TextEditingController(text: r?.xpCost.toString() ?? '50');
    _durationController = TextEditingController(
      text: r?.durationMinutes?.toString() ?? '',
    );

    if (r != null) {
      _selectedType = r.rewardType;
      _requiresApproval = r.requiresApproval;
      _checkIfTimeBased(r.rewardType);
    } else {
      _checkIfTimeBased(_selectedType);
    }
  }

  void _checkIfTimeBased(String type) {
    setState(() {
      _isTimeBased = (type == 'Tempo de app' || type == 'Tempo livre');
    });
  }

  Future<void> _saveReward() async {
    if (!_formKey.currentState!.validate()) return;

    final currentChild = ref.read(selectedChildProvider);
    final childId = widget.rewardToEdit?.childId ?? currentChild?.id;

    if (childId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma criança selecionada.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final reward = RewardModel(
        id: widget.rewardToEdit?.id ?? '',
        childId: childId,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        xpCost: int.parse(_xpController.text.trim()),
        rewardType: _selectedType,
        requiresApproval: _requiresApproval,
        durationMinutes: _isTimeBased
            ? int.tryParse(_durationController.text.trim())
            : null,
      );

      final service = ref.read(rewardServiceProvider);
      if (widget.rewardToEdit == null) {
        await service.addReward(reward);
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Prêmio criado!')));
      } else {
        await service.updateReward(reward);
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Prêmio atualizado!')));
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _xpController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.rewardToEdit != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Prêmio' : 'Novo Prêmio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Prêmio (Ex: Assistir YouTube)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Regras ou descrição (Opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Recompensa',
                  border: OutlineInputBorder(),
                ),
                items: _rewardTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    _selectedType = val;
                    _checkIfTimeBased(val);
                  }
                },
              ),
              const SizedBox(height: 16),

              if (_isTimeBased) ...[
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duração em minutos',
                    hintText: 'Ex: 30',
                    border: OutlineInputBorder(),
                    suffixText: 'min',
                  ),
                  validator: (value) =>
                      _isTimeBased && (value == null || value.isEmpty)
                      ? 'Informe o tempo'
                      : null,
                ),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _xpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Preço em XP',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.star, color: Colors.amber),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Exige\nAprovação',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: _requiresApproval,
                      onChanged: (val) =>
                          setState(() => _requiresApproval = val),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveReward,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Salvar Alterações' : 'Criar Prêmio',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
