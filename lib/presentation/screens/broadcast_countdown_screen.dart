import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rkfm_broadcast/core/theme/app_theme.dart';
import 'package:rkfm_broadcast/presentation/screens/live_broadcast_screen.dart';
import 'package:rkfm_broadcast/presentation/viewmodels/broadcast_viewmodel.dart';

class BroadcastCountdownScreen extends StatefulWidget {
  const BroadcastCountdownScreen({super.key});

  @override
  State<BroadcastCountdownScreen> createState() => _BroadcastCountdownScreenState();
}

class _BroadcastCountdownScreenState extends State<BroadcastCountdownScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BroadcastViewModel>().startCountdown();
    });
  }

  @override
  Widget build(BuildContext context) {
    final broadcast = context.watch<BroadcastViewModel>();

    if (broadcast.isLive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LiveBroadcastScreen()),
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Color(broadcast.program?.cardColorValue ?? AppColors.primary.value).withValues(alpha: 0.3),
                  Colors.black,
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  broadcast.program?.name ?? 'BROADCAST',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  '${broadcast.countdown}',
                  style: TextStyle(
                    fontSize: 200,
                    fontWeight: FontWeight.bold,
                    color: Color(broadcast.program?.cardColorValue ?? AppColors.live.value),
                    height: 1,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'GOING LIVE...',
                  style: TextStyle(fontSize: 18, letterSpacing: 6, color: AppColors.textMuted),
                ),
                const SizedBox(height: 48),
                _LoadingIndicator(label: 'Loading Camera & Audio'),
                const SizedBox(height: 12),
                _LoadingIndicator(label: 'Loading Template & Overlays'),
                const SizedBox(height: 12),
                _LoadingIndicator(label: 'Connecting Facebook RTMP'),
              ],
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  broadcast.abortCountdown();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close, color: AppColors.recording),
                label: const Text('ABORT', style: TextStyle(color: AppColors.recording)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.recording),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  final String label;

  const _LoadingIndicator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.live),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ],
    );
  }
}
