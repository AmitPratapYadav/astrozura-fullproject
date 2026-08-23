import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/contants/api_constants.dart';
import '../../../core/services/astrologer_service.dart';
import '../../live/native_live_session_screen.dart';

class HomeLiveSessionSection extends StatefulWidget {
  const HomeLiveSessionSection({super.key});

  @override
  State<HomeLiveSessionSection> createState() => _HomeLiveSessionSectionState();
}

class _HomeLiveSessionSectionState extends State<HomeLiveSessionSection> {
  static const _navy = Color(0xFF1E3557);
  static const _gold = Color(0xFFD7AF4B);
  static const _goldLight = Color(0xFFFFF6D9);

  Map<String, dynamic>? _session;
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadLiveSession();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadLiveSession(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLiveSession({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _loading = true);
    }

    try {
      final response = await AstrologerService.getCurrentLiveSession();
      final rawSession = response['session'] ?? response['data'];
      final session = rawSession is Map
          ? Map<String, dynamic>.from(rawSession)
          : <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _session = session.isEmpty ? null : session;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _session = null;
        _loading = false;
      });
    }
  }

  void _openLive() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NativeLiveSessionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final astrologer = session?['astrologer'] is Map
        ? Map<String, dynamic>.from(session!['astrologer'])
        : <String, dynamic>{};
    final astrologerName = _text(astrologer['name'], fallback: 'AstroZura');
    final title = _text(session?['title'], fallback: 'Live astrology session');
    final image = _text(astrologer['profile_image']);
    final isLive = session != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLive
                ? const [Color(0xFF1E3557), Color(0xFF254E7E)]
                : const [Color(0xFFFFFBF2), Color(0xFFFFF4D0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isLive
                ? _gold.withValues(alpha: 0.6)
                : _gold.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: isLive ? 0.18 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LiveAvatar(imageUrl: image, isLive: isLive),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isLive
                                ? Colors.redAccent.withValues(alpha: 0.95)
                                : _gold.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isLive ? 'LIVE NOW' : 'LIVE SESSIONS',
                            style: TextStyle(
                              color: isLive ? Colors.white : _navy,
                              fontSize: 10,
                              height: 1,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (_loading) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isLive ? Colors.white : _navy,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isLive ? title : 'Watch astrologers live',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isLive ? Colors.white : _navy,
                        fontSize: 18,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isLive
                          ? '$astrologerName is live now'
                          : 'Join upcoming AstroZura live guidance sessions.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isLive
                            ? Colors.white.withValues(alpha: 0.82)
                            : _navy.withValues(alpha: 0.68),
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _openLive,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLive ? _gold : _navy,
                  foregroundColor: isLive ? _navy : Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isLive ? 'Watch' : 'Open',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

class _LiveAvatar extends StatelessWidget {
  final String imageUrl;
  final bool isLive;

  const _LiveAvatar({
    required this.imageUrl,
    required this.isLive,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.isNotEmpty;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: isLive
                ? Colors.white.withValues(alpha: 0.16)
                : _HomeLiveSessionSectionState._goldLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isLive
                  ? Colors.white.withValues(alpha: 0.5)
                  : _HomeLiveSessionSectionState._gold.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? Image.network(
                  ApiConstants.storageUrl(imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackIcon(),
                )
              : _fallbackIcon(),
        ),
        if (isLive)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallbackIcon() {
    return Icon(
      Icons.live_tv_rounded,
      color: isLive ? Colors.white : _HomeLiveSessionSectionState._navy,
      size: 28,
    );
  }
}
