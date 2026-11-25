import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/registro_model.dart';
import '../services/registro_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_message.dart';
import '../widgets/registro_tile.dart';
import 'registro_actions.dart';

/// Aba "Calendário": dias com registros ficam marcados; ao tocar em um dia
/// aparecem os registros dele e dá para cadastrar um novo naquela data.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final RegistroRepository _repo = RegistroRepository.instance;

  CalendarFormat _formato = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  /// Entrega ao calendário os registros de um dia (eventLoader).
  List<Registro> _eventosDoDia(DateTime dia) {
    return _repo.registros.where((r) => isSameDay(r.dataEvento, dia)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calendário',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: 'Novo registro neste dia',
        onPressed: () => abrirFormularioRegistro(context, data: _selectedDay),
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: _repo,
        builder: (context, _) {
          final doDia = _eventosDoDia(_selectedDay);
          return Column(
            children: [
              TableCalendar<Registro>(
                locale: 'pt_BR',
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _formato,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Mês',
                  CalendarFormat.twoWeeks: '2 semanas',
                  CalendarFormat.week: 'Semana',
                },
                startingDayOfWeek: StartingDayOfWeek.sunday,
                selectedDayPredicate: (dia) => isSameDay(_selectedDay, dia),
                eventLoader: _eventosDoDia,
                onDaySelected: (selecionado, focado) {
                  setState(() {
                    _selectedDay = selecionado;
                    _focusedDay = focado;
                  });
                },
                onFormatChanged: (formato) =>
                    setState(() => _formato = formato),
                onPageChanged: (focado) => _focusedDay = focado,
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonDecoration: BoxDecoration(
                    border: Border.all(color: AppColors.borda),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  formatButtonTextStyle: const TextStyle(fontSize: 13),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: AppColors.textoSecundario),
                  weekendStyle: TextStyle(color: AppColors.textoSecundario),
                ),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: const TextStyle(color: Colors.white),
                  weekendTextStyle: const TextStyle(
                    color: AppColors.textoSecundario,
                  ),
                  outsideTextStyle: const TextStyle(color: AppColors.borda),
                  todayDecoration: BoxDecoration(
                    color: AppColors.azul.withAlpha(90),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(color: Colors.white),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.verde,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: AppColors.laranja,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                ),
              ),
              const Divider(height: 1, color: AppColors.borda),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Registros de ${DateFormat('dd/MM/yyyy').format(_selectedDay)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: doDia.isEmpty
                    ? const EmptyMessage(
                        icon: Icons.event_available_outlined,
                        text: 'Nenhum registro neste dia.\nToque em + para adicionar.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: doDia.length,
                        itemBuilder: (context, i) {
                          final r = doDia[i];
                          return RegistroTile(
                            registro: r,
                            onTap: () => abrirDetalhesRegistro(context, r),
                            onEdit: () =>
                                abrirFormularioRegistro(context, registro: r),
                            onDelete: () => confirmarExclusao(context, r),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
