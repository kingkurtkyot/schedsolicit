import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/field_definition.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/validators.dart';

class DynamicForm extends StatefulWidget {
  final List<FieldDefinition> fields;
  final Map<String, dynamic> initialValues;
  final ValueChanged<Map<String, dynamic>> onSave;
  final String submitButtonText;
  final List<String> customCategories;

  const DynamicForm({
    super.key,
    required this.fields,
    this.initialValues = const {},
    required this.onSave,
    this.submitButtonText = 'Save',
    this.customCategories = const [],
  });

  @override
  State<DynamicForm> createState() => _DynamicFormState();
}

class _DynamicFormState extends State<DynamicForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _values;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _values = Map<String, dynamic>.from(widget.initialValues);
    for (final field in widget.fields) {
      if (!_values.containsKey(field.key)) {
        if (field.defaultValue != null) {
          _values[field.key] = field.defaultValue;
        } else if (field.type == FieldType.checkbox) {
          _values[field.key] = false;
        }
      }

      if (field.type == FieldType.text ||
          field.type == FieldType.textarea ||
          field.type == FieldType.phone ||
          field.type == FieldType.email ||
          field.type == FieldType.currency) {
        _controllers[field.key] = TextEditingController(
          text: _values[field.key]?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      // Sync text controllers into values
      for (final entry in _controllers.entries) {
        _values[entry.key] = entry.value.text;
      }
      widget.onSave(_values);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group fields by section
    final sections = <FieldSection, List<FieldDefinition>>{};
    for (final f in widget.fields) {
      if (f.isVisible(_values)) {
        sections.putIfAbsent(f.section, () => []).add(f);
      }
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        children: [
          for (final section in FieldSection.values)
            if (sections.containsKey(section) && sections[section]!.isNotEmpty) ...[
              _buildSectionHeader(section),
              const SizedBox(height: DesignTokens.spaceSm),
              for (final field in sections[section]!) ...[
                _buildField(field),
                const SizedBox(height: DesignTokens.spaceMd),
              ],
              const SizedBox(height: DesignTokens.spaceSm),
            ],
          const SizedBox(height: DesignTokens.spaceLg),
          ElevatedButton(
            onPressed: _submit,
            child: Text(
              widget.submitButtonText,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(FieldSection section) {
    final title = switch (section) {
      FieldSection.basic => 'Basic Info',
      FieldSection.contact => 'Contact Details',
      FieldSection.timing => 'Date & Timing',
      FieldSection.details => 'Additional Details',
      FieldSection.request => 'Request Specification',
      FieldSection.fulfillment => 'Fulfillment & Given',
      FieldSection.tracking => 'Tracking Info',
      FieldSection.meta => 'Metadata & Status',
    };

    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildField(FieldDefinition field) {
    if (field.readOnly) {
      return TextFormField(
        initialValue: _values[field.key]?.toString() ?? '',
        readOnly: true,
        decoration: InputDecoration(
          labelText: field.label,
          filled: true,
        ),
      );
    }

    switch (field.type) {
      case FieldType.text:
      case FieldType.phone:
      case FieldType.email:
      case FieldType.currency:
        return _buildTextInput(field);
      case FieldType.textarea:
        return _buildTextArea(field);
      case FieldType.date:
        return _buildDatePicker(field);
      case FieldType.time:
        return _buildTimePicker(field);
      case FieldType.datetime:
        return _buildDateTimePicker(field);
      case FieldType.checkbox:
        return _buildCheckbox(field);
      case FieldType.dropdown:
        return _buildDropdown(field);
      case FieldType.repeat:
        return _buildRepeatPicker(field);
      case FieldType.reminders:
        return _buildRemindersPicker(field);
    }
  }

  Widget _buildTextInput(FieldDefinition field) {
    TextInputType keyboardType = TextInputType.text;
    if (field.type == FieldType.phone) keyboardType = TextInputType.phone;
    if (field.type == FieldType.email) keyboardType = TextInputType.emailAddress;
    if (field.type == FieldType.currency) {
      keyboardType = const TextInputType.numberWithOptions(decimal: true);
    }

    return TextFormField(
      controller: _controllers[field.key],
      keyboardType: keyboardType,
      maxLength: field.maxLength,
      decoration: InputDecoration(
        labelText: field.label,
        prefixText: field.type == FieldType.currency ? '\$ ' : null,
      ),
      validator: (val) {
        if (field.required) {
          final res = FormValidators.required(val);
          if (res != null) return res;
        }
        if (field.type == FieldType.email) {
          return FormValidators.email(val);
        }
        if (field.type == FieldType.phone) {
          return FormValidators.phone(val);
        }
        if (field.type == FieldType.currency) {
          return FormValidators.currency(val);
        }
        return null;
      },
    );
  }

  Widget _buildTextArea(FieldDefinition field) {
    return TextFormField(
      controller: _controllers[field.key],
      maxLines: 4,
      minLines: 2,
      decoration: InputDecoration(
        labelText: field.label,
        alignLabelWithHint: true,
      ),
      validator: field.required ? FormValidators.required : null,
    );
  }

  Widget _buildDatePicker(FieldDefinition field) {
    final currentVal = _values[field.key] is DateTime
        ? _values[field.key] as DateTime
        : DateTime.tryParse(_values[field.key]?.toString() ?? '');

    final displayStr = currentVal != null ? DateFormat('MMM d, yyyy').format(currentVal) : 'Select date';

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: currentVal ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() {
            _values[field.key] = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(displayStr),
      ),
    );
  }

  Widget _buildTimePicker(FieldDefinition field) {
    final currentStr = _values[field.key]?.toString() ?? 'Select time';

    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (picked != null) {
          final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          setState(() {
            _values[field.key] = formatted;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.label,
          suffixIcon: const Icon(Icons.access_time_outlined),
        ),
        child: Text(currentStr),
      ),
    );
  }

  Widget _buildDateTimePicker(FieldDefinition field) {
    final currentVal = _values[field.key] is DateTime
        ? _values[field.key] as DateTime
        : DateTime.tryParse(_values[field.key]?.toString() ?? '');

    final displayStr = currentVal != null ? DateFormat('MMM d, yyyy h:mm a').format(currentVal) : 'Select date & time';

    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: currentVal ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null && mounted) {
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (pickedTime != null) {
            final dt = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            setState(() {
              _values[field.key] = dt;
            });
          }
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.label,
          suffixIcon: const Icon(Icons.event),
        ),
        child: Text(displayStr),
      ),
    );
  }

  Widget _buildCheckbox(FieldDefinition field) {
    final val = _values[field.key] == true;

    return CheckboxListTile(
      title: Text(field.label),
      value: val,
      contentPadding: EdgeInsets.zero,
      onChanged: (bool? newVal) {
        setState(() {
          _values[field.key] = newVal ?? false;
        });
      },
    );
  }

  Widget _buildDropdown(FieldDefinition field) {
    List<String> options = field.options ?? [];
    if (field.useCustomCategories) {
      options = [...widget.customCategories, 'General', 'Work', 'Personal', 'Donation', 'Sponsorship'];
    }

    final currentVal = _values[field.key]?.toString();

    return DropdownButtonFormField<String>(
      value: (currentVal != null && options.contains(currentVal)) ? currentVal : null,
      decoration: InputDecoration(
        labelText: field.label,
      ),
      items: options.map((opt) {
        return DropdownMenuItem(value: opt, child: Text(opt));
      }).toList(),
      onChanged: (newVal) {
        setState(() {
          _values[field.key] = newVal;
        });
      },
    );
  }

  Widget _buildRepeatPicker(FieldDefinition field) {
    final currentVal = _values[field.key]?.toString() ?? 'None';
    final options = ['None', 'Daily', 'Weekly', 'Monthly', 'Yearly'];

    return DropdownButtonFormField<String>(
      value: options.contains(currentVal) ? currentVal : 'None',
      decoration: InputDecoration(
        labelText: field.label,
        suffixIcon: const Icon(Icons.repeat),
      ),
      items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
      onChanged: (val) {
        setState(() {
          _values[field.key] = val == 'None' ? null : val;
        });
      },
    );
  }

  Widget _buildRemindersPicker(FieldDefinition field) {
    final options = {
      '15 minutes before': 900,
      '30 minutes before': 1800,
      '1 hour before': 3600,
      '1 day before': 86400,
    };

    final currentOffsets = (_values[field.key] as List<dynamic>?)?.cast<int>() ?? [3600];
    final selectedDesc = options.entries
        .where((e) => currentOffsets.contains(e.value))
        .map((e) => e.key)
        .join(', ');

    return InputDecorator(
      decoration: InputDecoration(
        labelText: field.label,
        suffixIcon: const Icon(Icons.notifications_active_outlined),
      ),
      child: Text(selectedDesc.isNotEmpty ? selectedDesc : '1 hour before'),
    );
  }
}
