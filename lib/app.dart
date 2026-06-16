import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:rkfm_broadcast/core/constants/app_constants.dart';
import 'package:rkfm_broadcast/core/di/injection.dart';
import 'package:rkfm_broadcast/core/services/permission_request_service.dart';
import 'package:rkfm_broadcast/core/theme/app_theme.dart';
import 'package:rkfm_broadcast/presentation/screens/dashboard_screen.dart';
import 'package:rkfm_broadcast/presentation/screens/login_screen.dart';
import 'package:rkfm_broadcast/presentation/viewmodels/auth_viewmodel.dart';
import 'package:rkfm_broadcast/presentation/viewmodels/broadcast_viewmodel.dart';
import 'package:rkfm_broadcast/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:rkfm_broadcast/presentation/viewmodels/settings_viewmodel.dart';
import 'package:rkfm_broadcast/presentation/widgets/branding_widgets.dart';

class RkfmBroadcastApp extends StatelessWidget {
  const RkfmBroadcastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<AuthViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<DashboardViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<BroadcastViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<SettingsViewModel>()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _AppInitializer(),
      ),
    );
  }
}

class _AppInitializer extends StatefulWidget {
  const _AppInitializer();

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await PermissionRequestService.requestBroadcastPermissions();

    final auth = getIt<AuthViewModel>();
    final hasSession = await auth.tryRestoreSession();

    if (mounted) {
      setState(() => _initialized = true);
      if (hasSession) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            SvgPicture.asset(
              'assets/images/splash_bg.svg',
              fit: BoxFit.cover,
            ),
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RkfmLogo(size: 120, showTagline: true),
                  SizedBox(height: 32),
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Initializing Broadcast Console...', style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return const LoginScreen();
  }
}
