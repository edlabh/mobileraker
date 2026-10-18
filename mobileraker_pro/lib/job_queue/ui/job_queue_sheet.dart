/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/data/dto/job_queue/job_queue_status.dart';
import 'package:common/service/selected_machine_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../service/job_queue_service.dart';
import 'job_queue_sheet_controller.dart';

/// Bottom sheet da fila de impressão (Moonraker `server.job_queue.*`).
class JobQueueBottomSheet extends ConsumerWidget {
  const JobQueueBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machineUUID = ref.watch(selectedMachineProvider).value?.uuid;
    final statusAsync = machineUUID == null ? null : ref.watch(jobQueueProvider(machineUUID));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SafeArea(
        top: false,
        child: Material(
          type: MaterialType.transparency,
          child: switch (statusAsync) {
          AsyncData(:final value) => _QueueView(status: value),
          null => const _EmptyQueueBody(),
          AsyncError(:final error) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('$error'),
            ),
          _ => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        },
        ),
      ),
    );
  }
}

class _QueueView extends ConsumerWidget {
  const _QueueView({required this.status});

  final JobQueueStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = status.queuedJobs;
    if (jobs.isEmpty) {
      return const _EmptyQueueBody();
    }
    final controller = ref.watch(jobQueueSheetControllerProvider());
    final theme = Theme.of(context);
    final queueRunning = status.queueState == QueueState.starting || status.queueState == QueueState.paused;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'bottom_sheets.job_queue_sheet.next'.tr(),
            style: theme.textTheme.labelSmall,
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  child: Text('${index + 1}', style: theme.textTheme.labelSmall),
                ),
                title: Text(job.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'general.remove'.tr(),
                  onPressed: () => _run(context, () => controller.removeJob(job.jobId)),
                ),
              );
            },
          ),
        ),
        const Divider(height: 8),
        Row(
          children: [
            if (queueRunning)
              FilledButton.icon(
                onPressed: () => _run(context, () => controller.pauseQueue()),
                icon: const Icon(Icons.pause),
                label: Text('bottom_sheets.job_queue_sheet.pause_queue'.tr()),
              )
            else
              FilledButton.icon(
                onPressed: () => _run(context, () => controller.startQueue()),
                icon: const Icon(Icons.play_arrow),
                label: Text('bottom_sheets.job_queue_sheet.start_queue'.tr()),
              ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _removeAll(context, ref, controller),
              icon: const Icon(Icons.delete_sweep_outlined),
              label: Text('bottom_sheets.job_queue_sheet.remove_all'.tr()),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _removeAll(BuildContext context, WidgetRef ref, JobQueueSheetController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text('bottom_sheets.job_queue_sheet.remove_all_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('general.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('bottom_sheets.job_queue_sheet.remove_all'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final jobIds = status.queuedJobs.map((entry) => entry.jobId).toList();
    await _run(context, () => controller.removeJobs(jobIds));
  }

  Future<void> _run(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class _EmptyQueueBody extends StatelessWidget {
  const _EmptyQueueBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.queue_outlined, size: 36),
          const SizedBox(height: 8),
          Text(
            'bottom_sheets.job_queue_sheet.empty'.tr(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
