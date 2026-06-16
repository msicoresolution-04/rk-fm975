import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rkfm_broadcast/core/theme/app_theme.dart';
import 'package:rkfm_broadcast/presentation/screens/dashboard_screen.dart';
import 'package:rkfm_broadcast/presentation/viewmodels/auth_viewmodel.dart';
import 'package:rkfm_broadcast/presentation/viewmodels/broadcast_viewmodel.dart';
import 'package:rkfm_broadcast/presentation/widgets/broadcast_widgets.dart';
import 'package:rkfm_broadcast/presentation/widgets/camera_preview_widget.dart';

class LiveBroadcastScreen extends StatefulWidget {
  const LiveBroadcastScreen({super.key});

  @override
  State<LiveBroadcastScreen> createState() => _LiveBroadcastScreenState();
}

class _LiveBroadcastScreenState extends State<LiveBroadcastScreen> {
  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _emergencyEnd() async {
    final pinController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('EMERGENCY END'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter PIN to end broadcast immediately.'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'PIN'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.recording),
            child: const Text('END BROADCAST'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final auth = context.read<AuthViewModel>();
    final broadcast = context.read<BroadcastViewModel>();
    final success = await broadcast.stopBroadcast(
      username: auth.currentUser!.username,
      userId: auth.currentUser!.id,
      pin: pinController.text,
    );

    pinController.dispose();

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid PIN. Broadcast not ended.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final broadcast = context.watch<BroadcastViewModel>();
    final program = broadcast.program;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: AppColors.surface,
            child: Row(
              children: [
                StatusBadge(label: 'LIVE', color: AppColors.live, pulse: true),
                const SizedBox(width: 16),
                Text(
                  program?.programTitle ?? 'Broadcast',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 16),
                Text(
                  _formatDuration(broadcast.liveDuration),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                StatusBadge(
                  label: '${broadcast.viewerCount} viewers',
                  color: AppColors.info,
                  icon: Icons.people,
                ),
                const Spacer(),
                if (broadcast.isRecording)
                  StatusBadge(
                    label: broadcast.recordingPaused ? 'REC PAUSED' : 'RECORDING',
                    color: AppColors.recording,
                    icon: Icons.fiber_manual_record,
                  ),
                const SizedBox(width: 12),
                StatusBadge(
                  label: broadcast.facebookConnected ? 'FACEBOOK LIVE' : 'FB DISCONNECTED',
                  color: broadcast.facebookConnected ? AppColors.live : AppColors.warning,
                ),
                const SizedBox(width: 12),
                Text('${broadcast.bitrate ~/ 1000} kbps', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CameraPreviewWidget(),
                if (broadcast.template != null)
                  TemplateOverlayPreview(
                    elements: broadcast.template!.elements.map((e) => e.toMap()).toList(),
                    programTitle: program?.programTitle,
                    subtitle: program?.subtitle,
                    ticker: program?.tickerText,
                  ),
              ],
            ),
          ),
          Container(
            height: 96,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BroadcastControlButton(
                  label: 'STOP LIVE',
                  icon: Icons.stop_circle,
                  color: AppColors.recording,
                  onPressed: _emergencyEnd,
                ),
                const SizedBox(width: 12),
                BroadcastControlButton(
                  label: broadcast.isMuted ? 'UNMUTE' : 'MUTE',
                  icon: broadcast.isMuted ? Icons.mic_off : Icons.mic,
                  isActive: broadcast.isMuted,
                  onPressed: () => broadcast.toggleMute(),
                ),
                const SizedBox(width: 12),
                BroadcastControlButton(
                  label: broadcast.recordingPaused ? 'RESUME REC' : 'PAUSE REC',
                  icon: broadcast.recordingPaused ? Icons.play_arrow : Icons.pause,
                  onPressed: () => broadcast.toggleRecordingPause(),
                ),
                const SizedBox(width: 12),
                BroadcastControlButton(
                  label: 'SNAPSHOT',
                  icon: Icons.camera_alt,
                  onPressed: () async {
                    final path = await broadcast.takeSnapshot();
                    if (context.mounted && path != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Snapshot saved: $path')),
                      );
                    }
                  },
                ),
                const SizedBox(width: 12),
                BroadcastControlButton(
                  label: 'SWITCH CAM',
                  icon: Icons.flip_camera_ios,
                  onPressed: () => broadcast.switchCamera(),
                ),
                const SizedBox(width: 12),
                BroadcastControlButton(
                  label: 'EMERGENCY',
                  icon: Icons.warning_amber,
                  color: AppColors.recording,
                  onPressed: _emergencyEnd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
