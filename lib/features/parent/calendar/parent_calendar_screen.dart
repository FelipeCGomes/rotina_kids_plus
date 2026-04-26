import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ParentCalendarScreen extends StatefulWidget {
  const ParentCalendarScreen({super.key});

  @override
  State<ParentCalendarScreen> createState() => _ParentCalendarScreenState();
}

class _ParentCalendarScreenState extends State<ParentCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final List<String> _classifications = [
    'Consulta',
    'Medicamento',
    'Treino',
    'Aula',
    'Exames',
    'Alimentação',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // O modal de cadastro fica aqui agora
  void _showAddEventModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EventFormModal(
        classifications: _classifications,
        selectedDate: _selectedDay!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda Completa')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) => setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            }),
            onFormatChanged: (format) =>
                setState(() => _calendarFormat = format),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildEventTile(
                  'Vitamina C',
                  '08:00',
                  'Medicamento',
                  Colors.green,
                ),
                _buildEventTile('Pediatra', '14:30', 'Consulta', Colors.red),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventModal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventTile(String title, String time, String cat, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.circle, color: color, size: 12),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(cat),
        trailing: Text(time),
      ),
    );
  }
}

// Widget auxiliar para o Modal
class _EventFormModal extends StatelessWidget {
  final List<String> classifications;
  final DateTime selectedDate;
  const _EventFormModal({
    required this.classifications,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Novo Lembrete',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Título',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            items: classifications
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) {},
            decoration: const InputDecoration(
              labelText: 'Classificação',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Salvar'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
