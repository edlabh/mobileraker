/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:math' as math;

import 'package:common/data/dto/files/gcode_file.dart';
import 'package:common/data/dto/machine/print_state_enum.dart';
import 'package:common/data/dto/machine/printer.dart';
import 'package:common/service/app_router.dart';
import 'package:common/service/moonraker/printer_service.dart';
import 'package:common/util/extensions/async_ext.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../service/ui/pro_routes.dart';
import '../data/model/gcode_structure.dart';
import '../data/model/layer.dart';
import '../data/model/move.dart';
import '../data/model/visualizer_options.dart';
import '../gcode_layer_renderer.dart';
import '../providers.dart';
import 'gcode_layer_visualizer.dart';

/// Card de dashboard do preview de G-code (acompanha a impressão ativa).
class GCodePreviewCard extends ConsumerWidget {
  const GCodePreviewCard({super.key, required this.machineUUID});

  final String machineUUID;

  static Widget preview() => const _Preview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (machineUUID == 'preview') return const _Preview();
    final printerAsync = ref.watch(printerProvider(machineUUID));
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: switch (printerAsync) {
        AsyncData(:final value) => _PrinterPreviewBody(machineUUID: machineUUID, printer: value),
        AsyncError(:final error) => _MessageBody(
            icon: Icons.error_outline,
            message: 'components.gcode_preview.parsing.error.title'.tr() + '\n$error',
          ),
        _ => const _LoadingBody(),
      },
    );
  }
}

class _PrinterPreviewBody extends HookConsumerWidget {
  const _PrinterPreviewBody({required this.machineUUID, required this.printer});

  final String machineUUID;
  final Printer printer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configFile = printer.configFile;
    final print = printer.print;
    final printing = print.state == PrintState.printing || print.state == PrintState.paused;
    final filename = print.filename;
    final started = useState(false);

    Widget body;
    final kinematics = configFile.configPrinter?.kinematics;
    if (kinematics == 'none') {
      body = _MessageBody(
        icon: Icons.warning_amber_rounded,
        message: 'pages.dashboard.control.gcode_preview_card.kinematic_not_supported'.tr(),
      );
    } else if (!printing || filename.isEmpty) {
      body = _MessageBody(
        icon: Icons.view_in_ar_outlined,
        message: 'pages.dashboard.control.gcode_preview_card.start_preview.hint'.tr(),
      );
    } else if (!started.value) {
      body = _StartPreviewBody(onStart: () => started.value = true);
    } else {
      final file = _fileFromFilename(filename);
      final structureAsync = ref.watch(gcodeStructureProvider(machineUUID, file));
      body = switch (structureAsync) {
        AsyncData(:final value) => _LivePreviewBody(
            machineUUID: machineUUID,
            file: file,
            structure: value,
            printer: printer,
          ),
        AsyncError(:final error) => _MessageBody(
            icon: Icons.error_outline,
            message: 'components.gcode_preview.parsing.error.title'.tr() + '\n$error',
          ),
        AsyncLoading(:final progress) => _ProgressBody(progress: progress?.toDouble()),
      };
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          dense: true,
          leading: const Icon(Icons.view_in_ar_outlined),
          title: Text('pages.dashboard.control.gcode_preview_card.title', style: Theme.of(context).textTheme.titleMedium).tr(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: body,
        ),
      ],
    );
  }
}

class _LivePreviewBody extends HookConsumerWidget {
  const _LivePreviewBody({
    required this.machineUUID,
    required this.file,
    required this.structure,
    required this.printer,
  });

  final String machineUUID;
  final GCodeFile file;
  final GCodeStructure structure;
  final Printer printer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filePos = ref.watch(
      printerProvider(machineUUID).selectRequireValue((data) => data.virtualSdCard?.filePosition ?? 0),
    );
    final renderer = useMemoized(() => GCodeLayerRenderer(structure), [structure]);
    final renderData = useMemoized(() => renderer.createRenderDataForFilePosition(filePos), [renderer, filePos]);
    final configFile = printer.configFile;
    final metaData = renderData.metaData;
    final layerText = '${metaData.layer + 1}/${structure.maxLayer}';
    final moveText = '${metaData.currentMove - metaData.moveStart}/${metaData.moveEnd - metaData.moveStart}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GCodeLayerVisualizer(printerConfig: configFile, currentLayer: renderData),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                '${'components.gcode_preview.layer.one'.tr()}: $layerText'
                '   ${'components.gcode_preview.move.one'.tr()}: $moveText',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TextButton.icon(
              onPressed: () => _openLivePreview(ref),
              icon: const Icon(Icons.open_in_full, size: 16),
              label: Text('pages.dashboard.control.gcode_preview_card.follow'.tr()),
            ),
          ],
        ),
      ],
    );
  }

  void _openLivePreview(WidgetRef ref) {
    ref.read(goRouterProvider).pushNamed(
      ProRoutes.fileManager_exlorer_gcodePreview.name,
      pathParameters: {'path': file.parentPath},
      queryParameters: {'machineUUID': machineUUID, 'live': 'true'},
      extra: file,
    );
  }
}

class _StartPreviewBody extends StatelessWidget {
  const _StartPreviewBody({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'pages.dashboard.control.gcode_preview_card.start_preview.hint'.tr(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow),
          label: Text('pages.dashboard.control.gcode_preview_card.start_preview.btn'.tr()),
        ),
      ],
    );
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({required this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = progress == null
        ? 'components.gcode_preview.loading.cache'
        : (progress! < 0.5
            ? 'components.gcode_preview.downloading.progress'
            : 'components.gcode_preview.parsing.progress');
    final value = progress == null ? null : (progress! < 0.5 ? progress! * 2 : (progress! - 0.5) * 2);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label.tr(args: value == null ? [] : ['${(value * 100).toStringAsFixed(0)}%']),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: value),
      ],
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(12),
      child: LinearProgressIndicator(),
    );
  }
}

/// Prévia estática usada no seletor de cards do dashboard.
class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final structure = _demoStructure();
    final renderData = GCodeLayerRenderer(structure).createRenderDataForLayer(layerIndex: 1);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.view_in_ar_outlined),
            title: Text('pages.dashboard.control.gcode_preview_card.title', style: theme.textTheme.titleMedium).tr(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: GCodeLayerPainter(
                  bedSize: const Size(220, 220),
                  data: renderData,
                  options: const VisualizerOptions(),
                  theme: theme,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

GCodeFile _fileFromFilename(String filename) {
  final idx = filename.lastIndexOf('/');
  if (idx < 0) {
    return GCodeFile(name: filename, parentPath: '', modified: 0, size: 0);
  }
  return GCodeFile(
    name: filename.substring(idx + 1),
    parentPath: '/${filename.substring(0, idx)}',
    modified: 0,
    size: 0,
  );
}

GCodeStructure _demoStructure() {
  const center = 110.0;
  final layers = <Layer>[];
  for (var layer = 0; layer < 3; layer++) {
    final size = 30.0 + layer * 12;
    final moves = <Move>[];
    var filePos = layer * 100000;
    var fromX = center - size;
    var fromY = center - size;
    final corners = <(double, double)>[
      (center + size, center - size),
      (center + size, center + size),
      (center - size, center + size),
      (center - size, center - size),
    ];
    for (final corner in corners) {
      moves.add(Move(
        startX: fromX,
        startY: fromY,
        endX: corner.$1,
        endY: corner.$2,
        extrusion: 1,
        filePos: filePos,
      ));
      filePos += 10;
      fromX = corner.$1;
      fromY = corner.$2;
    }
    const radius = 14.0;
    const circleX = center - 42;
    const circleY = center - 42;
    for (var k = 0; k < 48; k++) {
      final a0 = 2 * math.pi * (k / 48);
      final a1 = 2 * math.pi * ((k + 1) / 48);
      moves.add(Move(
        startX: circleX + radius * math.cos(a0),
        startY: circleY + radius * math.sin(a0),
        endX: circleX + radius * math.cos(a1),
        endY: circleY + radius * math.sin(a1),
        extrusion: 0.3,
        filePos: filePos + k,
      ));
    }
    moves.add(Move(
      startX: fromX,
      startY: fromY,
      endX: circleX,
      endY: circleY,
      extrusion: 0,
      filePos: filePos + 60,
    ));
    layers.add(Layer(
      index: layer,
      z: 0.2 + layer * 0.2,
      moves: moves,
      filePosStart: layer * 100000,
      filePosEnd: layer * 100000 + 70,
    ));
  }
  return GCodeStructure(layers: layers, maxLayer: layers.length);
}
