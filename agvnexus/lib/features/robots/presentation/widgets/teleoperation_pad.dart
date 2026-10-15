import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/industrial_card.dart';
import '../robots_controller.dart';

class TeleoperationPad extends ConsumerStatefulWidget {
  final String robotId;

  const TeleoperationPad({super.key, required this.robotId});

  @override
  ConsumerState<TeleoperationPad> createState() => _TeleoperationPadState();
}

class _TeleoperationPadState extends ConsumerState<TeleoperationPad> {
  double _linearSpeed = 0.35; // m/s
  final double _angularSpeed = 0.50; // rad/s
  String _activeCommand = 'IDLE';

  Future<void> _sendCommand(double linear, double angular, String label) async {
    setState(() => _activeCommand = label);
    final repo = ref.read(gatewayRobotRepositoryProvider);
    await repo.sendTeleopCommand(widget.robotId, linear, angular);
  }

  Future<void> _stop() async {
    await _sendCommand(0.0, 0.0, 'STOPPED');
  }

  @override
  Widget build(BuildContext context) {
    return IndustrialCard(
      title: 'MOBILE / MANUAL TELEOPERATION',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _activeCommand == 'STOPPED'
              ? AppColors.error.withAlpha(40)
              : _activeCommand != 'IDLE'
              ? AppColors.primary.withAlpha(40)
              : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _activeCommand != 'IDLE' && _activeCommand != 'STOPPED'
                ? AppColors.primary
                : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          'CMD: $_activeCommand',
          style: AppTypography.labelSmall.copyWith(
            color: _activeCommand == 'STOPPED'
                ? AppColors.error
                : AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: Column(
        children: [
          // Speed Presets
          Row(
            children: [
              Text(
                'Speed Scale: ',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Slow (0.2 m/s)'),
                selected: _linearSpeed == 0.2,
                onSelected: (val) {
                  if (val) setState(() => _linearSpeed = 0.2);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Normal (0.35 m/s)'),
                selected: _linearSpeed == 0.35,
                onSelected: (val) {
                  if (val) setState(() => _linearSpeed = 0.35);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Fast (0.6 m/s)'),
                selected: _linearSpeed == 0.6,
                onSelected: (val) {
                  if (val) setState(() => _linearSpeed = 0.6);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Directional D-Pad Layout
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // FORWARD
                  Positioned(
                    top: 0,
                    child: _buildPadButton(
                      icon: Icons.arrow_upward_rounded,
                      label: 'FWD',
                      onPressed: () =>
                          _sendCommand(_linearSpeed, 0.0, 'FORWARD'),
                    ),
                  ),
                  // LEFT
                  Positioned(
                    left: 0,
                    child: _buildPadButton(
                      icon: Icons.arrow_back_rounded,
                      label: 'LEFT',
                      onPressed: () =>
                          _sendCommand(0.0, _angularSpeed, 'TURN LEFT'),
                    ),
                  ),
                  // CENTER STOP
                  Positioned(
                    child: GestureDetector(
                      onTap: _stop,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(30),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.error, width: 2),
                        ),
                        child: const Center(
                          child: Text(
                            'STOP',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // RIGHT
                  Positioned(
                    right: 0,
                    child: _buildPadButton(
                      icon: Icons.arrow_forward_rounded,
                      label: 'RIGHT',
                      onPressed: () =>
                          _sendCommand(0.0, -_angularSpeed, 'TURN RIGHT'),
                    ),
                  ),
                  // REVERSE
                  Positioned(
                    bottom: 0,
                    child: _buildPadButton(
                      icon: Icons.arrow_downward_rounded,
                      label: 'REV',
                      onPressed: () =>
                          _sendCommand(-_linearSpeed * 0.7, 0.0, 'REVERSE'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Touch or tap directional controls to drive the differential robot. Releases automatically into standstill.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPadButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 60,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceRaised,
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            side: const BorderSide(color: AppColors.borderSubtle),
          ),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            Text(
              label,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
