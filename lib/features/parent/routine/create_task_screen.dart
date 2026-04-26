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

  String _selectedCategory = 'Casa';
  String _selectedPeriod = 'Manhã';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay? _selectedEndTime;

  bool _isLoading = false;
  bool _requiresApproval = true;
  bool _hasEndTime = false;
  bool _isRecurring = false;
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

      _isRecurring = t.isRecurring;
      if (_isRecurring) _selectedDays = List.from(t.daysOfWeek);
      if (t.intervalHours != null) _hasInterval = true;
      if (t.durationInDays != null) _hasDurationLimit = true;
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
        _hasDurationLimit = true;
        _selectedDays.clear();
        _selectedDays.addAll(_weekDays);
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
    if (_isRecurring && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um dia para repetir.'),
        ),
      );
      return;
    }

    final currentChild = ref.read(selectedChildProvider);
    final childId = widget.taskToEdit?.childId ?? currentChild?.id;

    if (childId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma criança selecionada.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final taskService = ref.read(taskServiceProvider);

      final formattedTime =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      String? formattedEndTime;

      if (_hasEndTime && _selectedEndTime != null) {
        formattedEndTime =
            '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}';
      }

      final task = TaskModel(
        id: widget.taskToEdit?.id ?? '',
        childId: childId,
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
        daysOfWeek: _isRecurring ? _selectedDays : [],
        intervalHours: _hasInterval
            ? int.tryParse(_intervalController.text.trim())
            : null,
        durationInDays: _hasDurationLimit
            ? int.tryParse(_durationDaysController.text.trim())
            : null,
      );

      if (widget.taskToEdit == null) {
        await taskService.addTask(task);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tarefa criada com sucesso!')),
          );
      } else {
        await taskService.updateTask(task);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tarefa atualizada com sucesso!')),
          );
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
    _intervalController.dispose();
    _durationDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.taskToEdit != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Tarefa' : 'Nova Tarefa')),
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
              const SizedBox(height: 24),
              const Divider(),

              // --- CONFIGURAÇÕES AVANÇADAS ---
              SwitchListTile(
                title: const Text('Definir horário de término'),
                subtitle: const Text('Ideal para aulas e consultas'),
                value: _hasEndTime,
                onChanged: (val) => setState(() => _hasEndTime = val),
              ),
              if (_hasEndTime)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: InkWell(
                    onTap: () => _pickTime(isEndTime: true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Término previsto',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _selectedEndTime?.format(context) ?? '--:--',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ),

              SwitchListTile(
                title: const Text('Repetir em dias específicos'),
                subtitle: const Text('Cria uma rotina contínua'),
                value: _isRecurring,
                onChanged: (val) => setState(() => _isRecurring = val),
              ),
              if (_isRecurring)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Wrap(
                    spacing: 8,
                    children: _weekDays.map((day) {
                      final isSelected = _selectedDays.contains(day);
                      return FilterChip(
                        label: Text(day),
                        selected: isSelected,
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDays.add(day);
                            } else {
                              _selectedDays.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

              SwitchListTile(
                title: const Text('Repetir no mesmo dia'),
                subtitle: const Text('Ex: Tomar remédio a cada 8 horas'),
                value: _hasInterval,
                onChanged: (val) => setState(() => _hasInterval = val),
              ),
              if (_hasInterval)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: TextFormField(
                    controller: _intervalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Intervalo em horas',
                      hintText: 'Ex: 8',
                      border: OutlineInputBorder(),
                      suffixText: 'horas',
                    ),
                  ),
                ),

              SwitchListTile(
                title: const Text('Limitar período em dias'),
                subtitle: const Text('Ex: Tratamento por 15 dias'),
                value: _hasDurationLimit,
                onChanged: (val) => setState(() => _hasDurationLimit = val),
              ),
              if (_hasDurationLimit)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: TextFormField(
                    controller: _durationDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duração (em dias)',
                      hintText: 'Ex: 15',
                      border: OutlineInputBorder(),
                      suffixText: 'dias',
                    ),
                    validator: (value) =>
                        _hasDurationLimit && (value == null || value.isEmpty)
                        ? 'Informe a quantidade de dias'
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
