import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/task_model.dart';
import '../../../data/services/task_providers.dart';
import '../../../data/services/child_providers.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  final TaskModel? taskToEdit;
  const CreateTaskScreen({super.key, this.taskToEdit});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _xpController;
  late TextEditingController _intervalController;
  late TextEditingController _durationDaysController;

  String? _selectedChildId;
  String _selectedCategory = 'Casa';
  String _selectedPeriod = 'Manhã';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay? _selectedEndTime;

  bool _isLoading = false;
  bool _requiresApproval = true;
  bool _hasEndTime = false;

  // === NOVAS VARIÁVEIS DE REPETIÇÃO ===
  bool _isRecurring = false;
  bool _repeatEveryDay = true;

  bool _hasInterval = false;
  bool _hasDurationLimit = false;

  final List<String> _categories = [
    'Higiene',
    'Escola',
    'Saúde',
    'Casa',
    'Terapia',
    'Consulta',
    'Medicamento',
    'Alimentação',
    'Sono',
    'Outros',
  ];
  final List<String> _periods = ['Manhã', 'Tarde', 'Noite'];
  final List<String> _weekDays = [
    'Dom',
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
  ];
  List<String> _selectedDays = [];

  @override
  void initState() {
    super.initState();
    final t = widget.taskToEdit;

    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _xpController = TextEditingController(text: t?.xpReward.toString() ?? '10');
    _intervalController = TextEditingController(
      text: t?.intervalHours?.toString() ?? '',
    );
    _durationDaysController = TextEditingController(
      text: t?.durationInDays?.toString() ?? '',
    );

    if (t != null) {
      _selectedChildId = t.childId;
      _selectedCategory = t.category;
      _selectedPeriod = t.period;
      _selectedDate = t.startDate;
      _requiresApproval = t.requiresApproval;

      final timeParts = t.time.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );

      if (t.endTime != null && t.endTime!.isNotEmpty) {
        _hasEndTime = true;
        final endParts = t.endTime!.split(':');
        _selectedEndTime = TimeOfDay(
          hour: int.parse(endParts[0]),
          minute: int.parse(endParts[1]),
        );
      }

      // Preenche a tela de edição corretamente
      _isRecurring = t.isRecurring;
      if (_isRecurring) {
        _selectedDays = List.from(t.daysOfWeek);
        _repeatEveryDay =
            _selectedDays.length == 7; // Se tem 7 dias, é "Todos os dias"
      }

      if (t.intervalHours != null) _hasInterval = true;
      if (t.durationInDays != null) _hasDurationLimit = true;
    } else {
      _selectedChildId = ref.read(selectedChildProvider)?.id;
      _selectedDays = List.from(
        _weekDays,
      ); // Começa com todos os dias selecionados por padrão
    }
  }

  void _onCategoryChanged(String? category) {
    if (category == null) return;
    setState(() {
      _selectedCategory = category;
      _hasEndTime =
          (category == 'Consulta' ||
          category == 'Terapia' ||
          category == 'Escola');
      if (category == 'Medicamento') {
        _hasInterval = true;
        _isRecurring = true;
        _repeatEveryDay = true;
        _hasDurationLimit = true;
        _selectedDays = List.from(_weekDays);
      } else {
        _hasInterval = false;
        _hasDurationLimit = false;
      }
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime({required bool isEndTime}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isEndTime
          ? (_selectedEndTime ?? _selectedTime)
          : _selectedTime,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isEndTime)
          _selectedEndTime = picked;
        else
          _selectedTime = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    // Validação de segurança
    if (_isRecurring && !_repeatEveryDay && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione pelo menos um dia para a tarefa se repetir.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedChildId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma criança!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final taskService = ref.read(taskServiceProvider);
      final children = ref.read(parentChildrenStreamProvider).value ?? [];

      final formattedTime =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      String? formattedEndTime;
      if (_hasEndTime && _selectedEndTime != null) {
        formattedEndTime =
            '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}';
      }

      // Garante que se for "Todos os dias", a lista vai completa pro banco
      final daysToSave = _isRecurring
          ? (_repeatEveryDay ? _weekDays : _selectedDays)
          : [];

      // --- LÓGICA DE SALVAMENTO MÚLTIPLO (TODA A FAMÍLIA) ---
      if (_selectedChildId == 'all' && widget.taskToEdit == null) {
        for (var child in children) {
          final task = TaskModel(
            id: '',
            childId: child.id,
            title: _titleController.text.trim(),
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            category: _selectedCategory,
            period: _selectedPeriod,
            startDate: _selectedDate,
            time: formattedTime,
            xpReward: int.parse(_xpController.text.trim()),
            requiresApproval: _requiresApproval,
            endTime: formattedEndTime,
            isRecurring: _isRecurring,
            daysOfWeek: daysToSave,
            intervalHours: _hasInterval
                ? int.tryParse(_intervalController.text.trim())
                : null,
            durationInDays: _hasDurationLimit
                ? int.tryParse(_durationDaysController.text.trim())
                : null,
          );
          await taskService.addTask(task);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tarefas criadas para todos os filhos!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // --- SALVAMENTO ÚNICO (UMA CRIANÇA OU EDIÇÃO) ---
        final task = TaskModel(
          id: widget.taskToEdit?.id ?? '',
          childId: _selectedChildId!,
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          category: _selectedCategory,
          period: _selectedPeriod,
          startDate: _selectedDate,
          time: formattedTime,
          xpReward: int.parse(_xpController.text.trim()),
          requiresApproval: _requiresApproval,
          endTime: formattedEndTime,
          isRecurring: _isRecurring,
          daysOfWeek: daysToSave,
          intervalHours: _hasInterval
              ? int.tryParse(_intervalController.text.trim())
              : null,
          durationInDays: _hasDurationLimit
              ? int.tryParse(_durationDaysController.text.trim())
              : null,
        );

        if (widget.taskToEdit == null) {
          await taskService.addTask(task);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tarefa criada com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          await taskService.updateTask(task);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tarefa atualizada com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _xpController.dispose();
    _intervalController.dispose();
    _durationDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.taskToEdit != null;
    final childrenAsync = ref.watch(parentChildrenStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Tarefa' : 'Nova Tarefa')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- SELETOR DE CRIANÇA ---
              childrenAsync.when(
                data: (children) {
                  if (children.isEmpty) return const SizedBox.shrink();

                  if (_selectedChildId != null &&
                      _selectedChildId != 'all' &&
                      !children.any((c) => c.id == _selectedChildId)) {
                    _selectedChildId = null;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedChildId,
                      decoration: const InputDecoration(
                        labelText: 'Para quem é esta tarefa?',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people_outline),
                      ),
                      items: [
                        if (!isEditing)
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text(
                              'Toda a Família (Todos)',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ...children.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedChildId = val),
                      validator: (val) =>
                          val == null ? 'Selecione uma criança' : null,
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const SizedBox.shrink(),
              ),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'O que deve ser feito?',
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
                  labelText: 'Descrição ou orientações (Opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                      onChanged: _onCategoryChanged,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedPeriod,
                      decoration: const InputDecoration(
                        labelText: 'Período',
                        border: OutlineInputBorder(),
                      ),
                      items: _periods
                          .map(
                            (per) =>
                                DropdownMenuItem(value: per, child: Text(per)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedPeriod = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data de Início',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                            ),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: () => _pickTime(isEndTime: false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hora',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_selectedTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _xpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'XP',
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
              const Divider(),

              // ==========================================
              // NOVA CONFIGURAÇÃO DE REPETIÇÃO
              // ==========================================
              Card(
                elevation: 0,
                color: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Repetir Tarefa',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      value: _isRecurring,
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) => setState(() => _isRecurring = val),
                    ),

                    if (_isRecurring) ...[
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Todos os dias'),
                        value: _repeatEveryDay,
                        onChanged: (val) {
                          setState(() {
                            _repeatEveryDay = val;
                            if (val) {
                              _selectedDays = List.from(
                                _weekDays,
                              ); // Marca todos
                            } else {
                              _selectedDays
                                  .clear(); // Desmarca para a pessoa escolher
                            }
                          });
                        },
                      ),

                      if (!_repeatEveryDay)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _weekDays.map((day) {
                              final isSelected = _selectedDays.contains(day);
                              return FilterChip(
                                label: Text(day),
                                selected: isSelected,
                                selectedColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                checkmarkColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedDays.add(day);
                                      // Se a pessoa marcou todos manualmente, liga o "Todos os dias"
                                      if (_selectedDays.length == 7)
                                        _repeatEveryDay = true;
                                    } else {
                                      _selectedDays.remove(day);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ==========================================
              SwitchListTile(
                title: const Text('Definir horário de término'),
                value: _hasEndTime,
                onChanged: (val) => setState(() => _hasEndTime = val),
              ),
              if (_hasEndTime)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: InkWell(
                    onTap: () => _pickTime(isEndTime: true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Término previsto',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_selectedEndTime?.format(context) ?? '--:--'),
                    ),
                  ),
                ),

              SwitchListTile(
                title: const Text('Repetir no mesmo dia'),
                value: _hasInterval,
                onChanged: (val) => setState(() => _hasInterval = val),
              ),
              if (_hasInterval)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextFormField(
                    controller: _intervalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Intervalo em horas',
                      border: OutlineInputBorder(),
                      suffixText: 'horas',
                    ),
                  ),
                ),

              SwitchListTile(
                title: const Text('Limitar período em dias'),
                value: _hasDurationLimit,
                onChanged: (val) => setState(() => _hasDurationLimit = val),
              ),
              if (_hasDurationLimit)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextFormField(
                    controller: _durationDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duração (em dias)',
                      border: OutlineInputBorder(),
                      suffixText: 'dias',
                    ),
                    validator: (value) =>
                        _hasDurationLimit && (value == null || value.isEmpty)
                        ? 'Informe os dias'
                        : null,
                  ),
                ),

              const SizedBox(height: 30),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveTask,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Salvar Alterações' : 'Salvar Tarefa',
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
