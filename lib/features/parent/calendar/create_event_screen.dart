import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/calendar_event_model.dart';
import '../../../data/models/child_model.dart';
import '../../../data/services/calendar_providers.dart';
import '../../../data/services/child_providers.dart';
import '../../../data/services/auth_provider.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  final CalendarEventModel? eventToEdit;
  final DateTime? initialDate;

  const CreateEventScreen({super.key, this.eventToEdit, this.initialDate});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _locationController;

  String _selectedCategory = 'Consulta Médica';
  String _selectedChildId = 'all'; // Padrão: Evento Familiar
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  bool _isLoading = false;
  bool _notifyParents = true;
  bool _visibleToChild = false;

  final List<String> _categories = [
    'Consulta Médica',
    'Terapia',
    'Escola',
    'Reunião',
    'Passeio',
    'Festa',
    'Esporte',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    final ev = widget.eventToEdit;

    _titleController = TextEditingController(text: ev?.title ?? '');
    _descController = TextEditingController(text: ev?.description ?? '');
    _locationController = TextEditingController(text: ev?.location ?? '');

    if (ev != null) {
      _selectedCategory = ev.category;
      _selectedChildId = ev.childId;
      _startDate = ev.startDateTime;
      _startTime = TimeOfDay.fromDateTime(ev.startDateTime);
      _endTime = TimeOfDay.fromDateTime(ev.endDateTime);
      _notifyParents = ev.notifyParents;
      _visibleToChild = ev.visibleToChild;
    } else {
      _startDate = widget.initialDate ?? DateTime.now();
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay(
        hour: (_startTime.hour + 1) % 24,
        minute: _startTime.minute,
      );

      // Tenta pré-selecionar a criança que já estava no dashboard
      final currentChild = ref.read(selectedChildProvider);
      if (currentChild != null) _selectedChildId = currentChild.id;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          // Auto-ajusta o fim para 1h depois se for antes do início
          if (_endTime.hour < _startTime.hour) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final endDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final event = CalendarEventModel(
        id: widget.eventToEdit?.id ?? '',
        parentId: user.uid,
        childId: _selectedChildId,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        category: _selectedCategory,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        notifyParents: _notifyParents,
        visibleToChild: _visibleToChild,
      );

      if (widget.eventToEdit == null) {
        await ref.read(calendarServiceProvider).addEvent(event);
      } else {
        await ref.read(calendarServiceProvider).updateEvent(event);
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
  Widget build(BuildContext context) {
    final children = ref.watch(parentChildrenStreamProvider).value ?? [];

    // Constrói a lista de opções para o Dropdown de Criança
    List<DropdownMenuItem<String>> childItems = [
      const DropdownMenuItem(
        value: 'all',
        child: Text('Toda a Família (Geral)'),
      ),
    ];
    childItems.addAll(
      children.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.eventToEdit == null ? 'Novo Evento' : 'Editar Evento',
        ),
      ),
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
                  labelText: 'Título do Evento',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedChildId,
                decoration: const InputDecoration(
                  labelText: 'Membro Vinculado',
                  border: OutlineInputBorder(),
                ),
                items: childItems,
                onChanged: (val) => setState(() => _selectedChildId = val!),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy (EEEE)', 'pt_BR').format(_startDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(isStart: true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Início',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _startTime.format(context),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(isStart: false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Término',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _endTime.format(context),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Localização (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observações (Opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              SwitchListTile(
                title: const Text('Notificar no celular dos pais'),
                value: _notifyParents,
                onChanged: (val) => setState(() => _notifyParents = val),
              ),
              SwitchListTile(
                title: const Text('Mostrar na rotina da criança'),
                subtitle: const Text('Aparece no app da criança como lembrete'),
                value: _visibleToChild,
                onChanged: (val) => setState(() => _visibleToChild = val),
              ),

              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveEvent,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Salvar Evento',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
