# 97.5 RKFM Broadcast Automation & Facebook Live Streaming Platform

**Powered By: MSiCore Solution**

Enterprise-grade Android/iOS tablet-first radio broadcast automation and Facebook Live streaming platform.

## Quick Start

```powershell
cd "D:\MSiCore Files\Radio Station Live\RK-FM 97.5"
flutter pub get
flutter run
```

### Build (Windows path fix)

If build fails due to spaces in the project path, use the build script:

```powershell
.\scripts\build.ps1
```

This creates a junction at `D:\RKFM-Build` and builds from there.

## Login Accounts

| Role | Username | Password |
|------|----------|----------|
| Super Admin | `superadmin` | `RKFM@Super2026!` |
| IT Admin | `itadmin` | `RKFM@IT2026!` |
| Operators 1-15 | `operator01` - `operator15` | `RKFM@User2026!` |

**Emergency PIN:** `9750`

## Facebook Live Setup

1. Login as `superadmin` or `itadmin`
2. Go to **Settings → Facebook**
3. Tap **ADD PAGE** or edit an existing page
4. Enter:
   - **Page Name**: e.g. `RKFM Official Page`
   - **RTMP URL**: `rtmps://live-api-s.facebook.com:443/rtmp/`
   - **Stream Key**: From Facebook Creator Studio → Go Live → Use Stream Key
5. Tap **TEST** to verify connection
6. Tap **SAVE**

Stream keys are encrypted and stored securely. No manual copy-paste during broadcast.

## Broadcast Flow

1. **Login** with operator credentials
2. **Select Program Card** (left panel)
3. Tap **START LIVE** → Confirm destination
4. **10-second countdown** — camera, audio, overlays, RTMP auto-load
5. **Automatic go-live** — no additional clicks
6. **Monitor** viewers, duration, Facebook status, recording
7. **Stop** with PIN verification (`9750` by default)

## Features Completed

- Role-based access (Super Admin, IT Admin, 15 Operators)
- 10 program cards with templates, cameras, audio profiles
- 56 built-in broadcast templates + custom template editor
- CameraX live preview (native Android PlatformView)
- H.264 hardware encoding + RTMP streaming engine
- Simultaneous MP4 recording (pause/resume/snapshot)
- Facebook destination manager (add/edit/delete/test)
- User management (create, enable/disable)
- Backup export/import (file + clipboard)
- Audit logging with CSV export
- AES encryption + secure storage for stream keys
- Landscape tablet UI with RKFM branding

## Deploy to Tablet

```powershell
# Connect tablet via USB, enable Developer Mode + USB Debugging
flutter devices
flutter run -d <device-id>

# Or install APK directly
flutter build apk --release
adb install build\app\outputs\flutter-apk\app-release.apk
```

## Project Structure

```
lib/
├── core/           # DI, theme, crypto, permissions, native bridge
├── data/           # SQLite, models, repositories, seed data
└── presentation/   # ViewModels, screens, widgets

android/.../kotlin/
├── CameraXPlugin.kt       # Camera preview + snapshot
├── CameraPreviewFactory.kt # Flutter PlatformView
├── RecordingPlugin.kt     # MP4 recording
├── RtmpStreamPlugin.kt    # RTMP + MediaCodec
├── AudioEnginePlugin.kt   # Audio meters
└── SystemMonitorPlugin.kt # CPU/memory
```

## License

Proprietary — MSiCore Solution © 2026
