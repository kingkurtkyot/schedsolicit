import 'package:flutter/material.dart';

enum ViewMode { list, calendar, agenda }

class ViewSwitcher extends StatelessWidget {
  final ViewMode currentMode;
  final ValueChanged<ViewMode> onModeChanged;

  const ViewSwitcher({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ViewMode>(
      segments: const [
        ButtonSegment(
          value: ViewMode.list,
          icon: Icon(Icons.view_list_outlined),
          label: Text('List'),
        ),
        ButtonSegment(
          value: ViewMode.calendar,
          icon: Icon(Icons.calendar_month_outlined),
          label: Text('Calendar'),
        ),
        ButtonSegment(
          value: ViewMode.agenda,
          icon: Icon(Icons.view_agenda_outlined),
          label: Text('Agenda'),
        ),
      ],
      selected: {currentMode},
      onSelectionChanged: (set) => onModeChanged(set.first),
    );
  }
}
