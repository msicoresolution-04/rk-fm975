import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rkfm_broadcast/core/services/install_service.dart';
import 'package:rkfm_broadcast/core/services/install_service_impl.dart';
import 'package:rkfm_broadcast/core/theme/app_theme.dart';

class InstallBanner extends StatefulWidget {
  final Widget child;

  const InstallBanner({super.key, required this.child});

  @override
  State<InstallBanner> createState() => _InstallBannerState();
}

class _InstallBannerState extends State<InstallBanner> {
  late final InstallService _installService;
  bool _installing = false;
  bool _showOnNative = false;

  @override
  void initState() {
    super.initState();
    _installService = createInstallService();
    if (kIsWeb) {
      _installService.checkInstallState().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _handleInstall() async {
    setState(() => _installing = true);
    try {
      await _installService.install();
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }

  bool get _showBanner {
    if (kIsWeb) return _installService.canInstall && !_installService.isInstalled;
    return _showOnNative;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_showBanner) _buildInstallBar(),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildInstallBar() {
    final label = _installService.platformLabel;
    return Material(
      color: AppColors.primary,
      elevation: 4,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.radio, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '97.5 RKFM Broadcast Console',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(width: 12),
              _installing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _handleInstall,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('INSTALL'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.live,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
