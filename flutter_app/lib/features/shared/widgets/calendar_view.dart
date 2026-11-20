import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/base_item.dart';
import 'item_card.dart';

class CalendarViewWidget<T extends BaseItem> extends StatefulWidget {
  final List<T> items;
  final DateTime Function(T item) getItemDate;
  final void Function(T item) onItemTap;
  final void Function(T item) onItemEdit;
  final void Function(T item) onItemDelete;

  const CalendarViewWidget({
    super.key,
    required this.items,
    required this.getItemDate,
    required this.onItemTap,
    required this.onItemEdit,
    required this.onItemDelete,
  });

  @override
  State<CalendarViewWidget<T>> createState() => _CalendarViewWidgetState<T>();
}

class _CalendarViewWidgetState<T extends BaseItem> extends State<CalendarViewWidget<T>> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<T> _getEventsForDay(DateTime day) {
    return widget.items.where((item) {
      final itemDate = widget.getItemDate(item);
      return isSameDay(itemDate, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Column(
      children: [
        TableCalendar<T>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: _getEventsForDay,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
        const Divider(),
        Expanded(
          child: selectedEvents.isEmpty
              ? Center(
                  child: Text(
                    _selectedDay != null ? 'No items on this date' : 'Select a date to view items',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: selectedEvents.length,
                  itemBuilder: (context, index) {
                    final item = selectedEvents[index];
                    return ItemCard(
                      item: item,
                      dateLine: 'Scheduled Event',
                      onTap: () => widget.onItemTap(item),
                      onEdit: () => widget.onItemEdit(item),
                      onDelete: () => widget.onItemDelete(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
