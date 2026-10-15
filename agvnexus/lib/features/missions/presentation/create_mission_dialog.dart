import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/config/constants.dart';
import '../../maps/presentation/live_map_screen.dart';
import '../../robots/presentation/robots_controller.dart';
import '../domain/mission_model.dart';
import 'missions_controller.dart';

class CreateMissionDialog extends ConsumerStatefulWidget {
  const CreateMissionDialog({super.key});

  @override
  ConsumerState<CreateMissionDialog> createState() =>
      _CreateMissionDialogState();
}

class _CreateMissionDialogState extends ConsumerState<CreateMissionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(
    text: 'Pallet Dispatch to Assembly',
  );
  final _weightController = TextEditingController(text: '120.0');

  String? _selectedSourceStationId = 'STN-WH-A';
  String? _selectedDestinationStationId = 'STN-ASSY-1';
  MissionPriority _selectedPriority = MissionPriority.normal;
  String? _selectedRobotId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submitMission() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSourceStationId == _selectedDestinationStationId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Source and Destination stations cannot be the same.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final map = await ref.read(mapRepositoryProvider).getActiveMap();
      if (map.stations.isEmpty) {
        throw StateError('No factory stations are configured on this map.');
      }
      final source = map.stations.firstWhere(
        (s) => s.id == _selectedSourceStationId,
        orElse: () => map.stations.first,
      );
      final dest = map.stations.firstWhere(
        (s) => s.id == _selectedDestinationStationId,
        orElse: () => map.stations.length > 1 ? map.stations[1] : map.stations.first,
      );


      await ref
          .read(missionRepositoryProvider)
          .createMission(
            name: _nameController.text.trim(),
            sourceStationId: source.id,
            sourceStationName: source.name,
            destinationStationId: dest.id,
            destinationStationName: dest.name,
            priority: _selectedPriority,
            payloadWeightKg: double.tryParse(_weightController.text) ?? 100.0,
            assignedRobotId: _selectedRobotId,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Mission successfully queued in deterministic dispatcher.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to queue mission: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapAsync = ref.watch(activeMapFutureProvider);
    final robotsAsync = ref.watch(robotsStreamProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceRaised,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusSm,
                          ),
                          border: Border.all(color: AppColors.primaryGlow),
                        ),
                        child: const Icon(
                          Icons.add_task_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DISPATCH NEW AMR MISSION',
                              style: AppTypography.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Point-to-point logistics payload transport',
                              style: AppTypography.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: AppColors.borderSubtle),
                  const SizedBox(height: 18),

                  // Mission Title
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Mission Title',
                      prefixIcon: Icon(Icons.label_outline_rounded, size: 18),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter mission name'
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // Source & Destination Station Selectors
                  mapAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error loading stations'),
                    data: (map) {
                      final hasValidSource = map.stations.any((s) => s.id == _selectedSourceStationId);
                      final effectiveSourceId = hasValidSource
                          ? _selectedSourceStationId
                          : (map.stations.isNotEmpty ? map.stations.first.id : null);

                      final hasValidDest = map.stations.any((s) => s.id == _selectedDestinationStationId);
                      final effectiveDestId = hasValidDest
                          ? _selectedDestinationStationId
                          : (map.stations.length > 1 ? map.stations[1].id : (map.stations.isNotEmpty ? map.stations.first.id : null));

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 420;

                          final pickupField = DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: effectiveSourceId,
                            decoration: const InputDecoration(
                              labelText: 'Pickup Station',
                              prefixIcon: Icon(
                                Icons.outbox_rounded,
                                size: 18,
                              ),
                            ),
                            items: map.stations
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(
                                      s.name,
                                      style: AppTypography.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedSourceStationId = v),
                          );

                          final deliveryField = DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: effectiveDestId,
                            decoration: const InputDecoration(
                              labelText: 'Delivery Station',
                              prefixIcon: Icon(
                                Icons.move_to_inbox_rounded,
                                size: 18,
                              ),
                            ),
                            items: map.stations
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(
                                      s.name,
                                      style: AppTypography.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(
                              () => _selectedDestinationStationId = v,
                            ),
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                pickupField,
                                const SizedBox(height: 14),
                                deliveryField,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: pickupField),
                              const SizedBox(width: 12),
                              Expanded(child: deliveryField),
                            ],
                          );
                        },
                      );
                    },

                  ),

                  const SizedBox(height: 16),

                  // Priority and Payload Weight (Responsive layout prevents 27px overflow)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 420;

                      final priorityField =
                          DropdownButtonFormField<MissionPriority>(
                        isExpanded: true,
                        initialValue: _selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Priority Level',
                          prefixIcon: Icon(Icons.flag_outlined, size: 18),
                        ),
                        items: MissionPriority.values
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  p.label,
                                  style: AppTypography.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedPriority = v!),
                      );

                      final weightField = TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Payload Weight (kg)',
                          prefixIcon: Icon(Icons.scale_outlined, size: 18),
                        ),
                        validator: (v) {
                          final w = double.tryParse(v ?? '');
                          if (w == null || w <= 0) return 'Valid weight > 0';
                          if (w > 500) return 'Max payload 500kg';
                          return null;
                        },
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            priorityField,
                            const SizedBox(height: 14),
                            weightField,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: priorityField),
                          const SizedBox(width: 12),
                          Expanded(child: weightField),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // AMR Assignment Dropdown
                  robotsAsync.maybeWhen(
                    data: (robots) {
                      return DropdownButtonFormField<String?>(
                        isExpanded: true,
                        initialValue: _selectedRobotId,
                        decoration: const InputDecoration(
                          labelText: 'Assigned AMR (Optional / Auto-Queue)',
                          prefixIcon: Icon(Icons.smart_toy_outlined, size: 18),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Auto-Assign Nearest Available AMR',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...robots.map(
                            (r) => DropdownMenuItem<String?>(
                              value: r.id,
                              child: Text(
                                '${r.name} (${r.mode.displayName})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedRobotId = v),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 24),

                  // Actions
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('CANCEL'),
                      ),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitMission,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('DISPATCH MISSION'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
