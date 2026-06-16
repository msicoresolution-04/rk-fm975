import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rkfm_broadcast/core/services/permission_service.dart';
import 'package:rkfm_broadcast/core/theme/app_theme.dart';
import 'package:rkfm_broadcast/presentation/screens/broadcast_countdown_screen.dart';
import 'package:rkfm_broadcast/presentation/screens/login_screen.dart';
import 'package:rkfm_broadcast/presentation/screens/settings_screen.dart';
import 'package:rkfm_broadcast/presentation/viewmodels/auth_viewmodel.dart';
import 'package:rkfm_broadcast/presentation/viewmodels/broadcast_viewmodel.dart';
import 'package:rkfm_broadcast/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:rkfm_broadcast/presentation/widgets/branding_widgets.dart';
import 'package:rkfm_broadcast/presentation/widgets/broadcast_widgets.dart';
import 'package:rkfm_broadcast/presentation/widgets/camera_preview_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().initialize();
    });
  }

  Future<void> _confirmGoLive() async {
    final dashboard = context.read<DashboardViewModel>();
    final program = dashboard.selectedProgram;
    if (program == null) return;

    final destination = dashboard.selectedDestination?.pageName ?? 'Facebook Live';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('START LIVESTREAM?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Program:', style: Theme.of(ctx).textTheme.labelLarge),
            Text(program.name, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Destination:', style: Theme.of(ctx).textTheme.labelLarge),
            Text(destination, style: Theme.of(ctx).textTheme.titleMedium),
          ],
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.live),
            child: const Text('CONTINUE'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final auth = context.read<AuthViewModel>();
    final broadcast = context.read<BroadcastViewModel>();
    await broadcast.prepareBroadcast(program, auth.currentUser!);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BroadcastCountdownScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final dashboard = context.watch<DashboardViewModel>();
    final now = DateTime.now();

    return Scaffold(
      body: Column(
        children: [
          _TopStatusBar(
            programName: dashboard.selectedProgram?.name ?? 'Select Program',
            now: now,
            isConnected: dashboard.isConnected,
            cpuUsage: dashboard.cpuUsage,
            memoryUsage: dashboard.memoryUsage,
            audioLeft: dashboard.audioLeft,
            audioRight: dashboard.audioRight,
            onLogout: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            onSettings: PermissionService.canAccessSettings(auth.currentUser!.role)
                ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))
                : null,
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 320,
                  child: _ProgramPanel(dashboard: dashboard),
                ),
                Expanded(child: _PreviewPanel(dashboard: dashboard)),
                SizedBox(
                  width: 280,
                  child: _StatusPanel(dashboard: dashboard),
                ),
              ],
            ),
          ),
          _BottomControlBar(
            canStart: dashboard.selectedProgram != null,
            onStartLive: _confirmGoLive,
            onSettings: PermissionService.canAccessSettings(auth.currentUser!.role)
                ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))
                : null,
          ),
        ],
      ),
    );
  }
}

class _TopStatusBar extends StatelessWidget {
  final String programName;
  final DateTime now;
  final bool isConnected;
  final int cpuUsage;
  final int memoryUsage;
  final double audioLeft;
  final double audioRight;
  final VoidCallback onLogout;
  final VoidCallback? onSettings;

  const _TopStatusBar({
    required this.programName,
    required this.now,
    required this.isConnected,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.audioLeft,
    required this.audioRight,
    required this.onLogout,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const BrandedHeader(subtitle: 'Broadcast Console'),
          const SizedBox(width: 24),
          StatusBadge(label: programName, color: AppColors.info, icon: Icons.live_tv),
          const Spacer(),
          Text(DateFormat('EEEE, MMM d, yyyy').format(now)),
          const SizedBox(width: 16),
          Text(DateFormat('h:mm:ss a').format(now), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 24),
          StatusBadge(
            label: isConnected ? 'ONLINE' : 'OFFLINE',
            color: isConnected ? AppColors.live : AppColors.recording,
            icon: Icons.wifi,
          ),
          const SizedBox(width: 12),
          Text('CPU $cpuUsage%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Text('MEM $memoryUsage%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 16),
          AudioMeterWidget(leftLevel: audioLeft, rightLevel: audioRight),
          const SizedBox(width: 16),
          if (onSettings != null)
            IconButton(icon: const Icon(Icons.settings), onPressed: onSettings, tooltip: 'Settings'),
          IconButton(icon: const Icon(Icons.logout), onPressed: onLogout, tooltip: 'Logout'),
        ],
      ),
    );
  }
}

class _ProgramPanel extends StatelessWidget {
  final DashboardViewModel dashboard;

  const _ProgramPanel({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('PROGRAM CARDS', style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(
            child: dashboard.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: dashboard.programs.length,
                    itemBuilder: (ctx, i) {
                      final program = dashboard.programs[i];
                      return ProgramCardWidget(
                        name: program.name,
                        description: program.description,
                        color: Color(program.cardColorValue),
                        isSelected: dashboard.selectedProgram?.id == program.id,
                        onTap: () => dashboard.selectProgram(program),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  final DashboardViewModel dashboard;

  const _PreviewPanel({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final program = dashboard.selectedProgram;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CameraPreviewWidget(),
            if (program != null)
              TemplateOverlayPreview(
                elements: const [],
                programTitle: program.programTitle,
                subtitle: program.subtitle,
                ticker: program.tickerText,
              ),
            Positioned(
              top: 16,
              left: 16,
              child: StatusBadge(
                label: 'PREVIEW',
                color: AppColors.warning,
                icon: Icons.visibility,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final DashboardViewModel dashboard;

  const _StatusPanel({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final program = dashboard.selectedProgram;
    final destination = dashboard.selectedDestination;

    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SYSTEM STATUS', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 16),
          _statusRow('Program', program?.name ?? '—'),
          _statusRow('Destination', destination?.pageName ?? '—'),
          _statusRow('Bitrate', program != null ? '${program.bitrate} kbps' : '—'),
          _statusRow('Resolution', '1920x1080'),
          _statusRow('FPS', '30'),
          _statusRow('Encoder', 'H.264 HW'),
          _statusRow('Audio', 'AAC 128kbps'),
          const Divider(height: 32),
          Text('FACEBOOK', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          StatusBadge(
            label: destination != null ? 'READY' : 'NOT SET',
            color: destination != null ? AppColors.live : AppColors.warning,
          ),
          const Spacer(),
          if (program?.isOutdoor == true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cell_tower, color: AppColors.warning, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Outdoor Live Module\nAdaptive Bitrate Enabled',
                      style: TextStyle(fontSize: 12, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}

class _BottomControlBar extends StatelessWidget {
  final bool canStart;
  final VoidCallback onStartLive;
  final VoidCallback? onSettings;

  const _BottomControlBar({
    required this.canStart,
    required this.onStartLive,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BroadcastControlButton(
            label: 'START LIVE',
            icon: Icons.play_circle_filled,
            color: AppColors.live,
            onPressed: canStart ? onStartLive : null,
          ),
          const SizedBox(width: 16),
          BroadcastControlButton(label: 'RECORD', icon: Icons.fiber_manual_record, color: AppColors.recording),
          const SizedBox(width: 16),
          BroadcastControlButton(label: 'MUTE', icon: Icons.mic_off),
          const SizedBox(width: 16),
          BroadcastControlButton(label: 'SNAPSHOT', icon: Icons.camera_alt),
          if (onSettings != null) ...[
            const SizedBox(width: 16),
            BroadcastControlButton(label: 'SETTINGS', icon: Icons.settings, onPressed: onSettings),
          ],
        ],
      ),
    );
  }
}
