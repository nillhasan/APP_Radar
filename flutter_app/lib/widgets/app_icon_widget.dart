import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Renders an app icon with support for network URLs (from App Store / Google Play),
/// automatic CORS-safe proxy fallback on web, and category emoji fallback.
class AppIconWidget extends StatefulWidget {
  final String? iconUrl;
  final String iconEmoji;
  final double size;
  final double borderRadius;
  final double fontSize;

  const AppIconWidget({
    super.key,
    this.iconUrl,
    required this.iconEmoji,
    this.size = 48,
    this.borderRadius = 12,
    this.fontSize = 24,
  });

  @override
  State<AppIconWidget> createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends State<AppIconWidget> {
  bool _useProxy = false;
  bool _hasFailed = false;

  @override
  void didUpdateWidget(covariant AppIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iconUrl != widget.iconUrl) {
      _useProxy = false;
      _hasFailed = false;
    }
  }

  String? get _resolvedUrl {
    final raw = widget.iconUrl?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (!raw.startsWith('http://') && !raw.startsWith('https://')) return null;

    if (_useProxy) {
      final safeW = (widget.size * 2).round().clamp(64, 256);
      return 'https://images.weserv.nl/?url=${Uri.encodeComponent(raw)}&w=$safeW&h=$safeW&fit=cover';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl;

    if (url != null && !_hasFailed) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          url,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          // IMPORTANT: Do NOT specify cacheWidth / cacheHeight on Web!
          // Flutter Web's CanvasKit ResizeImage throws UnsupportedError on web.
          cacheWidth: kIsWeb ? null : (widget.size * 2).round().clamp(32, 256),
          cacheHeight: kIsWeb ? null : (widget.size * 2).round().clamp(32, 256),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: AppColors.surfaceSecondary,
              alignment: Alignment.center,
              child: SizedBox(
                width: widget.size * 0.4,
                height: widget.size * 0.4,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // If direct URL failed and we haven't tried proxy yet, try proxy!
            if (!_useProxy) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _useProxy = true;
                  });
                }
              });
              return Container(color: AppColors.surfaceSecondary);
            }
            // If proxy also failed, fallback to emoji
            return _buildEmojiFallback();
          },
        ),
      );
    }

    return _buildEmojiFallback();
  }

  Widget _buildEmojiFallback() {
    return Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        widget.iconEmoji,
        style: TextStyle(fontSize: widget.fontSize),
      ),
    );
  }
}
