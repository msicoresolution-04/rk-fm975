import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rkfm_broadcast/core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool pulse;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          if (pulse)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 6),
                ],
              ),
            ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class AudioMeterWidget extends StatelessWidget {
  final double leftLevel;
  final double rightLevel;

  const AudioMeterWidget({
    super.key,
    required this.leftLevel,
    required this.rightLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _channelMeter('L', leftLevel),
        const SizedBox(width: 8),
        _channelMeter('R', rightLevel),
      ],
    );
  }

  Widget _channelMeter(String label, double db) {
    final normalized = ((db + 60) / 60).clamp(0.0, 1.0);
    final color = db > -3
        ? AppColors.recording
        : db > -12
            ? AppColors.warning
            : AppColors.live;

    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Container(
          width: 12,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 10,
              height: 56 * normalized,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class BroadcastControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isActive;

  const BroadcastControlButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? (isActive ? AppColors.live : AppColors.primary);
    return Material(
      color: isActive ? btnColor.withValues(alpha: 0.2) : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 110,
          height: 72,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? btnColor : AppColors.border,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: btnColor, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: btnColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgramCardWidget extends StatelessWidget {
  final String name;
  final String description;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const ProgramCardWidget({
    super.key,
    required this.name,
    required this.description,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.live_tv, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: color, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class TemplateOverlayPreview extends StatelessWidget {
  final List<dynamic> elements;
  final String? programTitle;
  final String? subtitle;
  final String? ticker;

  const TemplateOverlayPreview({
    super.key,
    required this.elements,
    this.programTitle,
    this.subtitle,
    this.ticker,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.4),
              ],
            ),
          ),
        ),
        ...elements.map((e) {
          final map = e is Map<String, dynamic> ? e : <String, dynamic>{};
          final type = map['type'] as String? ?? 'text';
          var content = map['content'] as String? ?? '';
          if (type == 'lowerThird' && programTitle != null) content = programTitle!;
          if (type == 'text' && subtitle != null && content.isEmpty) content = subtitle!;
          if (type == 'ticker' && ticker != null) content = ticker!;

          return Positioned(
            left: (map['x'] as num?)?.toDouble() ?? 0,
            top: (map['y'] as num?)?.toDouble() ?? 0,
            child: _buildElement(type, content, map),
          );
        }),
      ],
    );
  }

  Widget _buildElement(String type, String content, Map<String, dynamic> map) {
    final fontSize = (map['fontSize'] as num?)?.toDouble() ?? 20;
    final color = Color(map['color'] as int? ?? 0xFFFFFFFF);

    switch (type) {
      case 'logo':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        );
      case 'lowerThird':
        return Container(
          width: (map['width'] as num?)?.toDouble() ?? 400,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case 'ticker':
        return Container(
          width: 800,
          color: Colors.black.withValues(alpha: 0.7),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            content,
            style: TextStyle(color: color, fontSize: fontSize),
            overflow: TextOverflow.ellipsis,
          ),
        );
      case 'clock':
        return Text(
          DateFormat('h:mm a').format(DateTime.now()),
          style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold),
        );
      case 'date':
        return Text(
          DateFormat('EEEE, MMM d').format(DateTime.now()),
          style: TextStyle(color: color, fontSize: fontSize),
        );
      default:
        return Text(
          content,
          style: TextStyle(color: color, fontSize: fontSize),
        );
    }
  }
}
