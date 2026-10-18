/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../dto/get_extra_field.dart';
import '../dto/spoolman_entity_type_enum.dart';
import '../dto/spoolman_extra_type_enum.dart';
import '../service/spoolman_service.dart';

/// Seção de campos extras no formulário do Spoolman.
///
/// As definições vêm do servidor ([spoolmanExtraFieldsProvider]) e cada campo
/// é registrado no `FormBuilder` com o nome [GetExtraField.formFieldName];
/// [ExtraFieldsFormExtension.extractExtraFields] reconstrói o mapa `extra`
/// da entidade a partir dos dados do formulário.
class ExtraFieldsFormSection extends ConsumerWidget {
  const ExtraFieldsFormSection({
    super.key,
    required this.machineUUID,
    required this.type,
    this.extraValues,
    this.header,
  });

  final String machineUUID;
  final SpoolmanEntityType type;
  final Map<String, dynamic>? extraValues;
  final Widget? header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fields = ref.watch(spoolmanExtraFieldsProvider(machineUUID, type)).value ?? const <GetExtraField>[];
    if (fields.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header!,
        const SizedBox(height: 8),
        for (final field in fields) ...[
          _ExtraFieldFormField(field: field, value: extraValues?[field.key]),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ExtraFieldFormField extends StatelessWidget {
  const _ExtraFieldFormField({required this.field, this.value});

  final GetExtraField field;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final label = field.name ?? field.key;
    final decoration = InputDecoration(
      labelText: label,
      suffixText: field.unit,
      border: const OutlineInputBorder(),
    );
    final name = field.formFieldName;
    final type = field.fieldType ?? SpoolmanExtraType.text;
    final choices = field.choices ?? const <String>[];

    return switch (type) {
      SpoolmanExtraType.boolean => FormBuilderSwitch(
          name: name,
          initialValue: value is bool ? value as bool : field.defaultValue == 'true',
          title: Text(label),
        ),
      SpoolmanExtraType.choice when field.multiChoice == true => FormBuilderFilterChips(
          name: name,
          decoration: decoration,
          options: [
            for (final choice in choices)
              FormBuilderChipOption<String>(value: choice, child: Text(choice)),
          ],
          initialValue: value is List ? value.cast<String>() : const <String>[],
        ),
      SpoolmanExtraType.choice => FormBuilderDropdown<String>(
          name: name,
          decoration: decoration,
          initialValue: value?.toString() ?? field.defaultValue,
          items: [
            for (final choice in choices)
              DropdownMenuItem(value: choice, child: Text(choice)),
          ],
        ),
      SpoolmanExtraType.datetime => FormBuilderDateTimePicker(
          name: name,
          decoration: decoration,
          initialValue: value is DateTime ? value : (value is String ? DateTime.tryParse(value) : null),
          inputType: InputType.both,
        ),
      SpoolmanExtraType.integer || SpoolmanExtraType.integerRange => _NumericFormField(
          name: name,
          decoration: decoration,
          initial: value,
          integer: true,
        ),
      SpoolmanExtraType.float || SpoolmanExtraType.floatRange => _NumericFormField(
          name: name,
          decoration: decoration,
          initial: value,
          integer: false,
        ),
      SpoolmanExtraType.text => FormBuilderTextField(
          name: name,
          decoration: decoration,
          initialValue: value?.toString() ?? field.defaultValue,
        ),
    };
  }
}

/// Campo numérico tipado (inteiro ou decimal) dentro do `FormBuilder`.
class _NumericFormField extends StatelessWidget {
  const _NumericFormField({
    required this.name,
    required this.decoration,
    required this.initial,
    required this.integer,
  });

  final String name;
  final InputDecoration decoration;
  final dynamic initial;
  final bool integer;

  @override
  Widget build(BuildContext context) {
    final initialNum = initial is num ? initial as num : num.tryParse('${initial ?? ''}');
    return FormBuilderField<num>(
      name: name,
      initialValue: initialNum,
      builder: (field) => TextFormField(
        initialValue: field.value?.toString() ?? '',
        decoration: field.hasError ? decoration.copyWith(errorText: field.errorText) : decoration,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        onChanged: (text) {
          final trimmed = text.trim();
          if (trimmed.isEmpty) {
            field.didChange(null);
            return;
          }
          field.didChange(integer ? int.tryParse(trimmed) : double.tryParse(trimmed));
        },
      ),
    );
  }
}

/// Reconstrução do mapa `extra` a partir dos dados do formulário.
extension ExtraFieldsFormExtension on Map<String, dynamic> {
  /// Extrai os valores dos campos extras do Spoolman (registrados com o
  /// prefixo [spoolmanExtraFieldPrefix]) dos dados do formulário.
  Map<String, dynamic> extractExtraFields() {
    return {
      for (final entry in entries)
        if (entry.key.startsWith(spoolmanExtraFieldPrefix))
          entry.key.substring(spoolmanExtraFieldPrefix.length): _normalize(entry.value),
    };
  }

  Object? _normalize(Object? value) {
    if (value is DateTime) return value.toIso8601String();
    return value;
  }
}
