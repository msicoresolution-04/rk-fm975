import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rkfm_broadcast/core/constants/app_constants.dart';
import 'package:rkfm_broadcast/data/models/program_models.dart';
import 'package:rkfm_broadcast/core/services/permission_service.dart';
import 'package:rkfm_broadcast/core/theme/app_theme.dart';
import 'package:rkfm_broadcast/presentation/screens/template_editor_screen.dart';
import 'package:rkfm_broadcast/presentation/viewmodels/auth_viewmodel.dart';
import 'package:rkfm_broadcast/presentation/viewmodels/settings_viewmodel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthViewModel>();
      context.read<SettingsViewModel>().load(auth.currentUser!.role);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final settings = context.watch<SettingsViewModel>();
    final canManageUsers = PermissionService.canManageUsers(auth.currentUser!.role);
    final canAccessLogs = PermissionService.canAccessLogs(auth.currentUser!.role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'GENERAL'),
            Tab(text: 'STREAMING'),
            Tab(text: 'TEMPLATES'),
            Tab(text: 'FACEBOOK'),
            Tab(text: 'SECURITY'),
          ],
        ),
      ),
      body: settings.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _GeneralTab(settings: settings, auth: auth),
                _StreamingTab(settings: settings, auth: auth),
                _TemplatesTab(settings: settings),
                _FacebookTab(settings: settings, auth: auth),
                _SecurityTab(settings: settings, auth: auth, canAccessLogs: canAccessLogs, canManageUsers: canManageUsers),
              ],
            ),
    );
  }
}

class _GeneralTab extends StatefulWidget {
  final SettingsViewModel settings;
  final AuthViewModel auth;

  const _GeneralTab({required this.settings, required this.auth});

  @override
  State<_GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends State<_GeneralTab> {
  final _importController = TextEditingController();

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings.settings;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _SectionTitle('General'),
        ListTile(
          title: const Text('Countdown Duration'),
          subtitle: Text('${s.countdownDuration} seconds'),
          trailing: DropdownButton<int>(
            value: s.countdownDuration,
            items: [5, 10, 15, 20].map((v) => DropdownMenuItem(value: v, child: Text('$v sec'))).toList(),
            onChanged: (v) {
              if (v != null) {
                widget.settings.saveSettings(
                  s.copyWith(countdownDuration: v),
                  widget.auth.currentUser!.username,
                  widget.auth.currentUser!.id,
                );
              }
            },
          ),
        ),
        SwitchListTile(
          title: const Text('Auto Record'),
          value: s.autoRecord,
          onChanged: (v) => widget.settings.saveSettings(
            s.copyWith(autoRecord: v),
            widget.auth.currentUser!.username,
            widget.auth.currentUser!.id,
          ),
        ),
        const Divider(),
        const _SectionTitle('Backup & Export'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final path = await widget.settings.exportBackupToFile();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Backup saved: $path')),
                  );
                }
              },
              icon: const Icon(Icons.backup),
              label: const Text('EXPORT TO FILE'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final data = await widget.settings.exportBackup();
                await Clipboard.setData(ClipboardData(text: data));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup copied to clipboard')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('COPY BACKUP'),
            ),
            if (PermissionService.canManageUsers(widget.auth.currentUser!.role))
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Import Backup'),
                      content: TextField(
                        controller: _importController,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          hintText: 'Paste backup JSON here...',
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('RESTORE')),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    final success = await widget.settings.importBackupFromJson(
                      _importController.text,
                      widget.auth.currentUser!.username,
                      widget.auth.currentUser!.id,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'Restore complete' : 'Restore failed')),
                    );
                  }
                },
                icon: const Icon(Icons.restore),
                label: const Text('IMPORT BACKUP'),
              ),
            if (PermissionService.canAccessLogs(widget.auth.currentUser!.role))
              OutlinedButton.icon(
                onPressed: () async {
                  final path = await widget.settings.exportLogsToFile();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logs saved: $path')),
                    );
                  }
                },
                icon: const Icon(Icons.description),
                label: const Text('EXPORT LOGS'),
              ),
          ],
        ),
      ],
    );
  }
}

class _StreamingTab extends StatelessWidget {
  final SettingsViewModel settings;
  final AuthViewModel auth;

  const _StreamingTab({required this.settings, required this.auth});

  @override
  Widget build(BuildContext context) {
    final s = settings.settings;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _SectionTitle('Video'),
        ListTile(
          title: const Text('Resolution'),
          trailing: DropdownButton<String>(
            value: s.resolution,
            items: ['1920x1080', '1280x720']
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                settings.updateStreamingSettings(
                  resolution: v,
                  bitrate: s.bitrate,
                  fps: s.fps,
                  username: auth.currentUser!.username,
                  userId: auth.currentUser!.id,
                );
              }
            },
          ),
        ),
        ListTile(
          title: const Text('Bitrate'),
          trailing: DropdownButton<int>(
            value: s.bitrate,
            items: [2500, 4000, 6000, 8000]
                .map((v) => DropdownMenuItem(value: v, child: Text('$v kbps')))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                settings.updateStreamingSettings(
                  resolution: s.resolution,
                  bitrate: v,
                  fps: s.fps,
                  username: auth.currentUser!.username,
                  userId: auth.currentUser!.id,
                );
              }
            },
          ),
        ),
        _settingTile('FPS', '${s.fps}'),
        _settingTile('Encoder', 'H.264 Hardware (MediaCodec)'),
        const Divider(),
        const _SectionTitle('Audio'),
        _settingTile('Input Source', s.audioInput),
        _settingTile('Gain', '${s.audioGain}x'),
        _settingTile('Codec', 'AAC 128/192 kbps'),
        const Divider(),
        const _SectionTitle('Recording'),
        _settingTile('Quality', s.recordingQuality),
        _settingTile('Path', s.recordingPath),
      ],
    );
  }
}

class _TemplatesTab extends StatelessWidget {
  final SettingsViewModel settings;

  const _TemplatesTab({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('${settings.templates.length} Templates', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TemplateEditorScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('NEW TEMPLATE'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: settings.templates.length,
            itemBuilder: (ctx, i) {
              final t = settings.templates[i];
              return ListTile(
                leading: Icon(
                  t.isBuiltIn ? Icons.layers : Icons.edit,
                  color: AppColors.primary,
                ),
                title: Text(t.name),
                subtitle: Text('${t.category.name} • ${t.isBuiltIn ? 'Built-in' : 'Custom'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TemplateEditorScreen(template: t)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FacebookTab extends StatelessWidget {
  final SettingsViewModel settings;
  final AuthViewModel auth;

  const _FacebookTab({required this.settings, required this.auth});

  Future<void> _showDestinationDialog(BuildContext context, {FacebookDestinationModel? existing}) async {
    final pageController = TextEditingController(text: existing?.pageName ?? '');
    final keyController = TextEditingController(text: existing?.streamKey ?? '');
    final urlController = TextEditingController(text: existing?.rtmpUrl ?? AppConstants.facebookRtmpUrl);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Facebook Page' : 'Edit Facebook Page'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pageController,
                decoration: const InputDecoration(labelText: 'Page Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'RTMP URL'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Stream Key',
                  helperText: 'From Facebook Creator Studio → Go Live → Streaming Software',
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () async {
                await settings.deleteFacebookDestination(
                  existing.id,
                  auth.currentUser!.username,
                  auth.currentUser!.id,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('DELETE', style: TextStyle(color: AppColors.recording)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              await settings.saveFacebookDestination(
                id: existing?.id,
                pageName: pageController.text,
                streamKey: keyController.text,
                rtmpUrl: urlController.text,
                username: auth.currentUser!.username,
                userId: auth.currentUser!.id,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('SAVE'),
          ),
          OutlinedButton(
            onPressed: () async {
              final ok = await settings.testFacebookConnection(urlController.text, keyController.text);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(ok ? 'Connection test passed' : 'Connection test failed')),
                );
              }
            },
            child: const Text('TEST'),
          ),
        ],
      ),
    );
    pageController.dispose();
    keyController.dispose();
    urlController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.facebook, color: AppColors.info),
              const SizedBox(width: 8),
              Text('${settings.destinations.length} Facebook Pages',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showDestinationDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('ADD PAGE'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: settings.destinations.length,
            itemBuilder: (ctx, i) {
              final d = settings.destinations[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.facebook, color: AppColors.info, size: 32),
                  title: Text(d.pageName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'RTMP: ${d.rtmpUrl}\nStream Key: ${'*' * 12}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showDestinationDialog(context, existing: d),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SecurityTab extends StatelessWidget {
  final SettingsViewModel settings;
  final AuthViewModel auth;
  final bool canAccessLogs;
  final bool canManageUsers;

  const _SecurityTab({
    required this.settings,
    required this.auth,
    required this.canAccessLogs,
    required this.canManageUsers,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _SectionTitle('Security'),
        _settingTile('Session Timeout', '${settings.settings.sessionTimeoutMinutes} min'),
        _settingTile('Auto Logout', settings.settings.autoLogout ? 'Enabled' : 'Disabled'),
        _settingTile('PIN Protection', 'Enabled (default: ${AppConstants.defaultPin})'),
        ListTile(
          title: const Text('Change Emergency PIN'),
          trailing: const Icon(Icons.edit),
          onTap: () async {
            final pinController = TextEditingController();
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Change PIN'),
                content: TextField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: 'New PIN'),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SAVE')),
                ],
              ),
            );
            if (ok == true && pinController.text.length >= 4) {
              await settings.updatePin(pinController.text, auth.currentUser!.username, auth.currentUser!.id);
            }
            pinController.dispose();
          },
        ),
        if (canManageUsers) ...[
          const Divider(),
          Row(
            children: [
              _SectionTitle('Users (${settings.users.length})'),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  final userCtrl = TextEditingController();
                  final passCtrl = TextEditingController();
                  final nameCtrl = TextEditingController();
                  var role = UserRole.user;
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => StatefulBuilder(
                      builder: (ctx, setState) => AlertDialog(
                        title: const Text('Create User'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username')),
                            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Display Name')),
                            DropdownButtonFormField<UserRole>(
                              initialValue: role,
                              items: UserRole.values
                                  .where((r) => auth.currentUser!.role == UserRole.superAdmin || r != UserRole.superAdmin)
                                  .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                                  .toList(),
                              onChanged: (v) { if (v != null) setState(() => role = v); },
                              decoration: const InputDecoration(labelText: 'Role'),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('CREATE')),
                        ],
                      ),
                    ),
                  );
                  if (ok == true) {
                    await settings.createUser(
                      username: userCtrl.text,
                      password: passCtrl.text,
                      role: role,
                      displayName: nameCtrl.text,
                      adminUsername: auth.currentUser!.username,
                      adminUserId: auth.currentUser!.id,
                    );
                  }
                  userCtrl.dispose();
                  passCtrl.dispose();
                  nameCtrl.dispose();
                },
                icon: const Icon(Icons.person_add),
                label: const Text('ADD USER'),
              ),
            ],
          ),
          ...settings.users.map((u) => ListTile(
                title: Text(u.displayName),
                subtitle: Text('${u.username} • ${u.role.name}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      u.isActive ? Icons.check_circle : Icons.block,
                      color: u.isActive ? AppColors.live : AppColors.recording,
                      size: 20,
                    ),
                    if (u.role != UserRole.superAdmin)
                      IconButton(
                        icon: const Icon(Icons.toggle_off),
                        onPressed: () => settings.toggleUserActive(
                          u, auth.currentUser!.username, auth.currentUser!.id,
                        ),
                      ),
                  ],
                ),
              )),
        ],
        if (canAccessLogs) ...[
          const Divider(),
          _SectionTitle('Audit Logs (${settings.logs.length})'),
          ...settings.logs.take(20).map((log) => ListTile(
                dense: true,
                title: Text(log.action, style: const TextStyle(fontSize: 13)),
                subtitle: Text('${log.username} • ${log.timestamp}'),
                leading: Icon(
                  log.level == LogLevel.error ? Icons.error : Icons.info,
                  size: 16,
                  color: log.level == LogLevel.error ? AppColors.recording : AppColors.info,
                ),
              )),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

Widget _settingTile(String label, String value) {
  return ListTile(
    title: Text(label),
    trailing: Text(value, style: const TextStyle(color: AppColors.textSecondary)),
  );
}
