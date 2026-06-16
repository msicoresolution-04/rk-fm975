import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:rkfm_broadcast/core/constants/app_constants.dart';
import 'package:rkfm_broadcast/core/services/crypto_service.dart';
import 'package:rkfm_broadcast/core/theme/app_theme.dart';
import 'package:rkfm_broadcast/data/database/app_database.dart';

class DatabaseSeeder {
  final AppDatabase _db;
  final _uuid = const Uuid();

  DatabaseSeeder(this._db);

  Future<void> seedIfNeeded() async {
    final db = await _db.database;
    final users = await db.query('users', limit: 1);
    if (users.isNotEmpty) return;

    await _seedUsers(db);
    await _seedFacebookDestinations(db);
    await _seedProfiles(db);
    await _seedTemplates(db);
    await _seedPrograms(db);
    await _seedSettings(db);
  }

  Future<void> _seedUsers(dynamic db) async {
    final now = DateTime.now().toIso8601String();

    Future<void> insertUser(String username, String password, String role, String displayName, {bool mustChange = false}) async {
      final salt = CryptoService.generateSalt();
      await db.insert('users', {
        'id': _uuid.v4(),
        'username': username,
        'password_hash': CryptoService.hashPassword(password, salt),
        'salt': salt,
        'role': role,
        'display_name': displayName,
        'is_active': 1,
        'must_change_password': mustChange ? 1 : 0,
        'failed_login_attempts': 0,
        'created_at': now,
      });
    }

    await insertUser('superadmin', 'RKFM@Super2026!', UserRole.superAdmin.name, 'Super Administrator');
    await insertUser('itadmin', 'RKFM@IT2026!', UserRole.admin.name, 'IT Administrator');

    for (var i = 1; i <= 15; i++) {
      await insertUser(
        'operator${i.toString().padLeft(2, '0')}',
        'RKFM@User2026!',
        UserRole.user.name,
        'Broadcast Operator $i',
        mustChange: i == 1,
      );
    }
  }

  Future<void> _seedFacebookDestinations(dynamic db) async {
    final destinations = [
      ('RKFM Official Page', 'rtmps://live-api-s.facebook.com:443/rtmp/', 'RKFM_MAIN_KEY_PLACEHOLDER'),
      ('RKFM News Page', 'rtmps://live-api-s.facebook.com:443/rtmp/', 'RKFM_NEWS_KEY_PLACEHOLDER'),
      ('RKFM Events Page', 'rtmps://live-api-s.facebook.com:443/rtmp/', 'RKFM_EVENTS_KEY_PLACEHOLDER'),
      ('RKFM Remote Broadcast', 'rtmps://live-api-s.facebook.com:443/rtmp/', 'RKFM_REMOTE_KEY_PLACEHOLDER'),
    ];

    for (final (name, url, key) in destinations) {
      await db.insert('facebook_destinations', {
        'id': _uuid.v4(),
        'page_name': name,
        'rtmp_url': url,
        'stream_key': key,
        'is_active': 1,
      });
    }
  }

  Future<void> _seedProfiles(dynamic db) async {
    final cameraProfiles = [
      'Studio Main Camera',
      'Interview Camera',
      'Outdoor Mobile Camera',
      'Podcast Camera',
      'News Desk Camera',
    ];
    for (final name in cameraProfiles) {
      await db.insert('camera_profiles', {
        'id': _uuid.v4(),
        'name': name,
        'camera_facing': name.contains('Outdoor') ? 'rear' : 'front',
        'zoom': 1.0,
        'filter': name.contains('Podcast') ? 'podcast' : name.contains('News') ? 'news' : 'none',
        'fps': 30,
        'background_blur': name.contains('Podcast') ? 1 : 0,
        'face_enhancement': 1,
      });
    }

    final audioProfiles = [
      'Studio Mixer',
      'USB Interface',
      'Built-in Mic',
      'Bluetooth Audio',
      'Outdoor Portable',
    ];
    for (final name in audioProfiles) {
      await db.insert('audio_profiles', {
        'id': _uuid.v4(),
        'name': name,
        'input_source': name.contains('USB') ? 'usb' : name.contains('Bluetooth') ? 'bluetooth' : 'builtin',
        'gain': 1.0,
        'noise_gate': 1,
        'compressor': 1,
        'limiter': 1,
      });
    }
  }

  Future<void> _seedTemplates(dynamic db) async {
    final now = DateTime.now().toIso8601String();
    final templates = _generateBuiltInTemplates();

    for (final template in templates) {
      await db.insert('templates', {
        'id': _uuid.v4(),
        'name': template.$1,
        'category': template.$2.name,
        'is_built_in': 1,
        'elements_json': jsonEncode(_defaultElements(template.$1, template.$2)),
        'width': 1920,
        'height': 1080,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  List<(String, TemplateCategory)> _generateBuiltInTemplates() {
    final templates = <(String, TemplateCategory)>[];
    final categories = TemplateCategory.values;

    final namesByCategory = {
      TemplateCategory.news: ['Morning Headlines', 'Evening News', 'Top Stories', 'News Update'],
      TemplateCategory.breakingNews: ['Breaking Alert', 'Urgent Update', 'Flash Report', 'Live Breaking'],
      TemplateCategory.morningShow: ['Sunrise Show', 'Wake Up RKFM', 'Early Edition', 'Morning Vibes'],
      TemplateCategory.podcast: ['Podcast Studio', 'Deep Dive', 'Talk Track', 'Audio Focus'],
      TemplateCategory.interview: ['Guest Interview', 'One on One', 'Spotlight', 'Meet the Guest'],
      TemplateCategory.talkShow: ['Open Lines', 'Community Talk', 'Hot Topics', 'Panel Discussion'],
      TemplateCategory.musicProgram: ['Music Hour', 'Top Hits', 'Love Songs', 'Retro Mix'],
      TemplateCategory.communityProgram: ['Community Voice', 'Local Matters', 'Town Hall', 'Public Forum'],
      TemplateCategory.sportsUpdate: ['Sports Desk', 'Game Day', 'Scoreboard', 'Athlete Spotlight'],
      TemplateCategory.weatherReport: ['Weather Watch', 'Storm Tracker', 'Forecast Now', 'Climate Update'],
      TemplateCategory.electionCoverage: ['Election Night', 'Vote Count', 'Poll Results', 'Candidate Forum'],
      TemplateCategory.specialEvent: ['Special Event', 'Anniversary', 'Festival Live', 'Celebration'],
      TemplateCategory.emergencyBroadcast: ['Emergency Alert', 'Public Safety', 'Crisis Update', 'Evacuation Info'],
      TemplateCategory.outdoorBroadcast: ['Outdoor Live', 'Field Report', 'Remote Unit', 'On Location'],
    };

    for (final category in categories) {
      final names = namesByCategory[category] ?? ['Template'];
      for (var i = 0; i < names.length && templates.length < 56; i++) {
        templates.add((names[i], category));
      }
    }

    while (templates.length < 50) {
      templates.add(('RKFM Template ${templates.length + 1}', TemplateCategory.news));
    }

    return templates.take(56).toList();
  }

  List<Map<String, dynamic>> _defaultElements(String name, TemplateCategory category) {
    final accentColor = AppColors.programCardColors[category.index % AppColors.programCardColors.length].value;
    return [
      {
        'id': _uuid.v4(),
        'type': 'logo',
        'content': 'RKFM 97.5',
        'x': 60.0,
        'y': 40.0,
        'width': 180.0,
        'height': 80.0,
        'zIndex': 10,
        'opacity': 1.0,
        'animation': 'fade',
      },
      {
        'id': _uuid.v4(),
        'type': 'lowerThird',
        'content': name,
        'x': 60.0,
        'y': 880.0,
        'width': 700.0,
        'height': 120.0,
        'zIndex': 20,
        'fontSize': 36.0,
        'color': accentColor,
        'animation': 'slide',
      },
      {
        'id': _uuid.v4(),
        'type': 'text',
        'content': 'LIVE ON FACEBOOK',
        'x': 60.0,
        'y': 820.0,
        'width': 400.0,
        'height': 50.0,
        'zIndex': 15,
        'fontSize': 22.0,
        'color': 0xFF2EA043,
        'animation': 'none',
      },
      {
        'id': _uuid.v4(),
        'type': 'ticker',
        'content': '97.5 RKFM - Your Community Radio Station',
        'x': 0.0,
        'y': 1020.0,
        'width': 1920.0,
        'height': 60.0,
        'zIndex': 30,
        'fontSize': 24.0,
        'color': 0xFFFFFFFF,
        'animation': 'broadcast',
      },
      {
        'id': _uuid.v4(),
        'type': 'clock',
        'content': '',
        'x': 1700.0,
        'y': 40.0,
        'width': 160.0,
        'height': 50.0,
        'zIndex': 12,
        'fontSize': 28.0,
        'color': 0xFFFFFFFF,
        'animation': 'none',
      },
      {
        'id': _uuid.v4(),
        'type': 'date',
        'content': '',
        'x': 1700.0,
        'y': 90.0,
        'width': 200.0,
        'height': 40.0,
        'zIndex': 12,
        'fontSize': 18.0,
        'color': 0xFF8B949E,
        'animation': 'none',
      },
    ];
  }

  Future<void> _seedPrograms(dynamic db) async {
    final now = DateTime.now();
    final templates = await db.query('templates', limit: 10);
    final destinations = await db.query('facebook_destinations');
    final cameras = await db.query('camera_profiles');
    final audio = await db.query('audio_profiles');

    final programs = [
      ('Morning Express', 'Start your day with RKFM Morning Express', false),
      ('News Hour', 'In-depth news coverage and community updates', false),
      ('Midday Program', 'Midday music and community features', false),
      ('Love Songs Live', 'Romantic music and dedications', false),
      ('Evening Talk', 'Evening talk show with community voices', false),
      ('Special Coverage', 'Special event and breaking coverage', false),
      ('Outdoor Live', 'Mobile outdoor broadcast unit', true),
      ('Remote Broadcast', 'Remote location live streaming', true),
      ('Public Affairs', 'Public affairs and civic engagement', false),
      ('Community Bulletin', 'Community announcements and updates', false),
    ];

    for (var i = 0; i < programs.length; i++) {
      final (name, desc, outdoor) = programs[i];
      await db.insert('program_cards', {
        'id': _uuid.v4(),
        'name': name,
        'description': desc,
        'template_id': templates[i % templates.length]['id'],
        'facebook_destination_id': destinations[i % destinations.length]['id'],
        'program_title': name,
        'subtitle': '97.5 RKFM Radio',
        'ticker_text': 'LIVE NOW on 97.5 RKFM | Powered By MSiCore Solution',
        'camera_profile_id': cameras[i % cameras.length]['id'],
        'audio_profile_id': audio[i % audio.length]['id'],
        'bitrate': outdoor ? 2500 : 4000,
        'recording_profile_id': 'default',
        'overlay_profile_id': 'default',
        'countdown_duration': 10,
        'card_color': AppColors.programCardColors[i % AppColors.programCardColors.length].value,
        'recording_path': AppConstants.recordingsRoot,
        'is_archived': 0,
        'is_outdoor': outdoor ? 1 : 0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    }
  }

  Future<void> _seedSettings(dynamic db) async {
    await db.insert('app_settings', {
      'id': 'default',
      'countdown_duration': 10,
      'resolution': '1920x1080',
      'bitrate': 4000,
      'fps': 30,
      'audio_input': 'builtin',
      'audio_gain': 1.0,
      'recording_quality': '1080p',
      'recording_path': AppConstants.recordingsRoot,
      'auto_record': 1,
      'pin': AppConstants.defaultPin,
      'session_timeout': 30,
      'auto_logout': 1,
      'language': 'en',
    });
  }
}
