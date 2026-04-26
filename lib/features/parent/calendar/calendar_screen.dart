import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../data/models/calendar_event_model.dart';
import '../../../data/models/child_model.dart';
import '../../../data/services/calendar_providers.dart';
import '../../../data/services/child_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  String _filterId = 'all';
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    final selected = ref.read(selectedChildProvider);
    if (selected != null) _filterId = selected.id;
  }

  // Ignora as horas para poder agrupar corretamente os eventos por dia no calendário
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(parentChildrenStreamProvider);
    final eventsAsync = ref.watch(calendarEventsStreamProvider(_filterId));

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda Familiar')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-event', extra: _selectedDay),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Barra de Filtros (Todas as crianças ou específica)
          childrenAsync.when(
            data: (children) => _buildFilterBar(children),
            loading: () => const SizedBox(height: 50),
            error: (_, _) => const SizedBox.shrink(),
          ),

          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erro: $err')),
              data: (events) {
                // Agrupa os eventos por Data para o TableCalendar ler os pontinhos
                final Map<DateTime, List<CalendarEventModel>> groupedEvents =
                    {};
                for (var event in events) {
                  final date = _normalizeDate(event.startDateTime);
                  if (groupedEvents[date] == null) groupedEvents[date] = [];
                  groupedEvents[date]!.add(event);
                }

                // Pega os eventos do dia selecionado
                final selectedDateNorm = _normalizeDate(
                  _selectedDay ?? _focusedDay,
                );
                final selectedEvents = groupedEvents[selectedDateNorm] ?? [];

                return Column(
                  children: [
                    // O Calendário em si
                    TableCalendar<CalendarEventModel>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      eventLoader: (day) =>
                          groupedEvents[_normalizeDate(day)] ?? [],
                      calendarStyle: CalendarStyle(
                        markerDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Mês',
                        CalendarFormat.week: 'Semana',
                      },
                      locale:
                          'pt_BR', // Se não formatar PT-BR automaticamente, pode precisar importar pacote extra, mas a numeração funcionará
                    ),
                    const Divider(),
                    // Lista de Eventos do dia selecionado
                    Expanded(
                      child: selectedEvents.isEmpty
                          ? const Center(
                              child: Text('Nenhum evento neste dia.'),
                            )
                          : ListView.builder(
                              itemCount: selectedEvents.length,
                              itemBuilder: (context, index) {
                                final event = selectedEvents[index];
                                return _buildEventCard(event);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(List<ChildModel> children) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ChoiceChip(
            label: const Text('Família (Todos)'),
            selected: _filterId == 'all',
            onSelected: (val) => setState(() => _filterId = 'all'),
          ),
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(child.name),
                selected: _filterId == child.id,
                onSelected: (val) => setState(() => _filterId = child.id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(CalendarEventModel event) {
    final children = ref.watch(parentChildrenStreamProvider).value ?? [];
    final childName = event.childId == 'all'
        ? 'Toda Família'
        : children
              .firstWhere(
                (c) => c.id == event.childId,
                orElse: () => ChildModel(
                  id: '',
                  parentId: '',
                  name: '?',
                  lastName: '',
                  birthDate: DateTime.now(),
                  sex: 'Masculino',
                  avatarId: 'avatar_default',
                ),
              )
              .name;

    final startTime = DateFormat('HH:mm').format(event.startDateTime);
    final endTime = DateFormat('HH:mm').format(event.endDateTime);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Container(
          width: 5,
          color: _getColorForCategory(event.category),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$startTime - $endTime • $childName'),
            if (event.location != null && event.location!.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location!,
                      style: const TextStyle(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () =>
              context.push('/create-event', extra: {'event': event}),
        ),
      ),
    );
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Consulta Médica':
        return Colors.red;
      case 'Terapia':
        return Colors.purple;
      case 'Escola':
        return Colors.blue;
      case 'Festa':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}
