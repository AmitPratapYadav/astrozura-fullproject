import 'dart:async' as async;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:videosdk/videosdk.dart' as vsk;

import '../../core/contants/api_constants.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/services/astrologer_service.dart';

class NativeLiveSessionScreen extends StatefulWidget {
  const NativeLiveSessionScreen({super.key});

  @override
  State<NativeLiveSessionScreen> createState() =>
      _NativeLiveSessionScreenState();
}

class _NativeLiveSessionScreenState extends State<NativeLiveSessionScreen> {
  static const _navy = Color(0xFF1E3557);
  static const _gold = Color(0xFFD7AF4B);
  static const _pageBg = Color(0xFFFBF7EF);

  final TextEditingController _commentController = TextEditingController();

  Map<String, dynamic>? _session;
  Map<String, dynamic> _astrologer = {};
  List<Map<String, dynamic>> _comments = [];
  vsk.Room? _room;
  vsk.Stream? _hostVideoStream;
  vsk.Participant? _hostParticipant;
  async.Timer? _commentsTimer;

  bool _loading = true;
  bool _joining = false;
  bool _joined = false;
  bool _sendingComment = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAndJoin();
  }

  @override
  void dispose() {
    _commentsTimer?.cancel();
    _commentController.dispose();
    _room?.leave();
    super.dispose();
  }

  Future<void> _loadAndJoin() async {
    setState(() {
      _loading = true;
      _joining = false;
      _joined = false;
      _error = null;
      _hostVideoStream = null;
    });

    try {
      final response = await AstrologerService.getLiveSessionViewer();
      final session = _asMap(response['session']);
      final viewer = _asMap(response['viewer']);
      final provider = _asMap(_asMap(viewer['provider'])['videosdk']);

      if (session.isEmpty || provider.isEmpty) {
        throw Exception('No live broadcast is active right now.');
      }

      setState(() {
        _session = session;
        _astrologer = _asMap(session['astrologer']);
        _loading = false;
        _joining = true;
      });

      await _loadComments();
      _commentsTimer?.cancel();
      _commentsTimer = async.Timer.periodic(
        const Duration(seconds: 8),
        (_) => _loadComments(silent: true),
      );

      _joinVideoSdk(provider);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _joining = false;
        _error = _friendlyError(error);
      });
    }
  }

  void _joinVideoSdk(Map<String, dynamic> provider) {
    final roomId = _text(provider['room_id']);
    final token = _text(provider['token']);
    final participantId = _text(provider['participant_id']);
    final profile = context.read<ProfileProvider>();
    final displayName = profile.name.trim().isNotEmpty
        ? profile.name.trim()
        : 'AstroZura Viewer';

    if (roomId.isEmpty || token.isEmpty) {
      setState(() {
        _joining = false;
        _error = 'Live room is not ready yet. Please try again.';
      });
      return;
    }

    vsk.VideoSDK.on(vsk.Events.error, (error) {
      if (!mounted) return;
      final message = error is Map ? error['message'] : error?.toString();
      setState(() {
        _error =
            _text(message, fallback: 'Unable to connect to the live session.');
      });
    });

    final room = vsk.VideoSDK.createRoom(
      roomId: roomId,
      token: token,
      displayName: displayName,
      participantId: participantId,
      micEnabled: false,
      camEnabled: false,
      mode: vsk.Mode.RECV_ONLY,
      maxResolution: 'hd',
      debugMode: false,
    );

    _registerRoomEvents(room);
    _room = room;
    room.join();
  }

  void _registerRoomEvents(vsk.Room room) {
    room.on(vsk.Events.roomJoined, () {
      if (!mounted) return;
      setState(() {
        _joined = true;
        _joining = false;
      });
      for (final participant in room.participants.values) {
        _attachParticipant(participant);
      }
    });

    room.on(vsk.Events.participantJoined, (vsk.Participant participant) {
      _attachParticipant(participant);
    });

    room.on(vsk.Events.participantLeft, (_) {
      if (!mounted) return;
      setState(() {
        _hostParticipant = null;
        _hostVideoStream = null;
      });
    });

    room.on(vsk.Events.roomLeft, (_) {
      if (!mounted) return;
      setState(() {
        _joined = false;
        _joining = false;
        _hostParticipant = null;
        _hostVideoStream = null;
      });
    });
  }

  void _attachParticipant(vsk.Participant participant) {
    if (_isLocalViewer(participant)) return;

    _hostParticipant = participant;
    for (final stream in participant.streams.values) {
      _handleStream(participant, stream);
    }

    participant.on(vsk.Events.streamEnabled, (vsk.Stream stream) {
      _handleStream(participant, stream);
    });

    participant.on(vsk.Events.streamDisabled, (vsk.Stream stream) {
      if (stream.kind == 'video' && mounted) {
        setState(() => _hostVideoStream = null);
      }
    });
  }

  void _handleStream(vsk.Participant participant, vsk.Stream stream) {
    if (stream.kind != 'video') return;
    if (!mounted) return;
    setState(() {
      _hostParticipant = participant;
      _hostVideoStream = stream;
    });
  }

  bool _isLocalViewer(vsk.Participant participant) {
    return participant.id == _room?.localParticipant.id;
  }

  Future<void> _loadComments({bool silent = false}) async {
    final sessionId = _asInt(_session?['id']);
    if (sessionId <= 0) return;
    try {
      final comments = await AstrologerService.getLiveComments(sessionId);
      if (!mounted) return;
      setState(() => _comments = comments);
    } catch (_) {
      if (!silent && mounted) {
        setState(() => _comments = []);
      }
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    final sessionId = _asInt(_session?['id']);
    if (text.isEmpty || sessionId <= 0 || _sendingComment) return;

    setState(() => _sendingComment = true);
    try {
      await AstrologerService.postLiveComment(sessionId, text);
      _commentController.clear();
      await _loadComments();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(error))),
      );
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _text(_session?['title'], fallback: 'AstroZura Live');
    final astrologerName = _text(_astrologer['name'], fallback: 'Astrologer');

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: _navy,
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Live Session',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadAndJoin,
                    icon: const Icon(Icons.refresh_rounded),
                    color: _navy,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _gold),
                    )
                  : _error != null
                      ? _buildEmptyState(_error!)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          children: [
                            _buildVideoCard(title, astrologerName),
                            const SizedBox(height: 14),
                            _buildCommentsPanel(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(String title, String astrologerName) {
    return Container(
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 9 / 14,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_hostVideoStream != null)
                  vsk.RTCVideoView(
                    _hostVideoStream!.renderer as vsk.RTCVideoRenderer,
                    objectFit:
                        vsk.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                else
                  _buildVideoWaiting(),
                Positioned(
                  left: 14,
                  top: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                if (_joining)
                  const Positioned(
                    right: 16,
                    top: 16,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                _buildAstrologerAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        astrologerName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.76),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoWaiting() {
    return Container(
      color: const Color(0xFF13243F),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: _gold.withValues(alpha: 0.6)),
              ),
              child: const Icon(
                Icons.live_tv_rounded,
                color: _gold,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _joined
                  ? 'Waiting for astrologer video'
                  : 'Joining live session...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAstrologerAvatar() {
    final image = _text(_astrologer['profile_image']);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: image.isNotEmpty
          ? Image.network(
              ApiConstants.storageUrl(image),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _avatarFallback(),
            )
          : _avatarFallback(),
    );
  }

  Widget _avatarFallback() {
    return const Icon(Icons.person_rounded, color: _gold);
  }

  Widget _buildCommentsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _gold.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Live Comments',
              style: TextStyle(
                color: _navy,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (_comments.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 18),
              child: Text(
                'No comments yet. Be the first to join the conversation.',
                style: TextStyle(
                  color: Color(0xFF667085),
                  height: 1.35,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length > 12 ? 12 : _comments.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final comment = _comments[_comments.length - 1 - index];
                final user = _asMap(comment['user']);
                return ListTile(
                  dense: true,
                  title: Text(
                    _text(user['name'], fallback: 'Viewer'),
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    _text(comment['message']),
                    style: const TextStyle(
                      color: Color(0xFF475467),
                      height: 1.35,
                    ),
                  ),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Write a comment',
                      filled: true,
                      fillColor: const Color(0xFFFAF7EF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: _gold.withValues(alpha: 0.35)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: _gold.withValues(alpha: 0.35)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _gold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _sendingComment ? null : _sendComment,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: _gold,
                      foregroundColor: _navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _sendingComment
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _gold.withValues(alpha: 0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.live_tv_rounded, color: _gold, size: 46),
              const SizedBox(height: 12),
              const Text(
                'No Live Session',
                style: TextStyle(
                  color: _navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF667085),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAndJoin,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Check Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _friendlyError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.contains('Not authenticated')) {
      return 'Please login to watch live sessions.';
    }
    if (raw.contains('404') || raw.toLowerCase().contains('no live')) {
      return 'No astrologer is live right now. Please check again shortly.';
    }
    return raw.isEmpty ? 'Unable to open the live session.' : raw;
  }
}
