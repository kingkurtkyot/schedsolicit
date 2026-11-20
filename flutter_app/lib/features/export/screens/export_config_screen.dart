import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../solicitation/providers/solicitation_provider.dart';
import '../../shared/models/base_item.dart';
import '../services/export_engine.dart';

class ExportConfigScreen extends ConsumerStatefulWidget {
  final dynamic filter;

  const ExportConfigScreen({super.key, this.filter});

  @override
  ConsumerState<ExportConfigScreen> createState() => _ExportConfigScreenState();
}

class _ExportConfigScreenState extends ConsumerState<ExportConfigScreen> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  ExportLayout _selectedLayout = ExportLayout.list;
  ExportContentLevel _contentLevel = ExportContentLevel.full;
  String _targetModule = 'both'; // schedule, solicitation, both
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Configuration')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Export Format', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ExportFormat.values.map((f) {
              return ChoiceChip(
                label: Text(f.name.toUpperCase()),
                selected: _selectedFormat == f,
                onSelected: (val) => val ? setState(() => _selectedFormat = f) : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          const Text('Module Scope', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'schedule', label: Text('Schedule')),
              ButtonSegment(value: 'solicitation', label: Text('Solicitations')),
              ButtonSegment(value: 'both', label: Text('Both')),
            ],
            selected: {_targetModule},
            onSelectionChanged: (set) => setState(() => _targetModule = set.first),
          ),
          const SizedBox(height: 24),

          const Text('Content Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          SegmentedButton<ExportContentLevel>(
            segments: const [
              ButtonSegment(value: ExportContentLevel.summary, label: Text('Summary')),
              ButtonSegment(value: ExportContentLevel.full, label: Text('Full Details')),
            ],
            selected: {_contentLevel},
            onSelectionChanged: (set) => setState(() => _contentLevel = set.first),
          ),
          const SizedBox(height: 32),

          if (_isExporting)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.file_download),
              label: const Text('Generate & Preview'),
              onPressed: _startExport,
            ),
        ],
      ),
    );
  }

  void _startExport() async {
    setState(() => _isExporting = true);

    final List<BaseItem> items = [];
    if (_targetModule == 'schedule' || _targetModule == 'both') {
      final sch = ref.read(scheduleListProvider).value ?? [];
      items.addAll(sch);
    }
    if (_targetModule == 'solicitation' || _targetModule == 'both') {
      final sol = ref.read(solicitationListProvider).value ?? [];
      items.addAll(sol);
    }

    try {
      final file = await ExportEngine.generateExport(
        format: _selectedFormat,
        items: items,
        layout: _selectedLayout,
        contentLevel: _contentLevel,
      );

      if (mounted) {
        context.push('/export/preview', extra: {
          'file_path': file.path,
          'format': _selectedFormat.name,
          'items_count': items.length,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}
