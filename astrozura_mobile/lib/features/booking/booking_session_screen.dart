import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../core/contants/api_constants.dart';
import '../../core/services/booking_service.dart';

const _navy = Color(0xFF1E3557);
const _gold = Color(0xFFD7AF4B);
const _chatBg = Color(0xFFF6F0E4);

class BookingSessionScreen extends StatefulWidget {
  const BookingSessionScreen({super.key});

  @override
  State<BookingSessionScreen> createState() => _BookingSessionScreenState();
}

class _BookingSessionScreenState extends State<BookingSessionScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  Timer? _pollTimer;
  Timer? _typingDebounce;
  int? _bookingId;
  BookingModel? _booking;
  SessionPayload? _session;
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _uploading = false;
  bool _fullscreen = false;
  bool _otherTyping = false;
  bool _recording = false;
  bool _polling = false;
  bool _nearBottom = true;
  bool _showNewMessages = false;
  int _pollTicks = 0;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bookingId != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    final rawId = args is Map ? args['bookingId'] : args;
    _bookingId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _typingDebounce?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isCall =>
      (_booking?.consultationType ?? '').toLowerCase().contains('call');
  bool get _chatEnabled {
    final session = _session;
    return session != null && (session.isLive || session.canJoin);
  }

  Future<void> _load() async {
    final bookingId = _bookingId;
    if (bookingId == null) {
      setState(() {
        _loading = false;
        _error = 'Booking ID was not provided.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        BookingService.getSession(bookingId),
        BookingService.getMessages(bookingId),
      ]);
      if (!mounted) return;
      final sessionData = results[0] as Map<String, dynamic>;
      setState(() {
        _booking = sessionData['booking'] as BookingModel;
        _session = sessionData['session'] as SessionPayload;
        _messages = (results[1] as List<Map<String, dynamic>>);
        _loading = false;
      });
      await BookingService.markMessagesRead(bookingId).catchError((_) {});
      _startPolling();
      _scrollToBottom(force: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    final bookingId = _bookingId;
    if (bookingId == null || _polling) return;
    _polling = true;
    try {
      _pollTicks++;
      final futures = <Future<dynamic>>[
        BookingService.getMessages(bookingId),
        BookingService.getTypingStatus(bookingId),
      ];
      if (_pollTicks % 4 == 0) {
        futures.add(BookingService.getSession(bookingId));
      }
      final results = await Future.wait(futures);
      if (!mounted) return;

      final incoming = results[0] as List<Map<String, dynamic>>;
      final typing = results[1] as Map<String, dynamic>;
      final oldCount = _messages.length;
      final nextCount = incoming.length;
      final shouldScroll =
          _nearBottom || nextCount > oldCount && _lastIsMine(incoming);

      setState(() {
        _messages = incoming;
        _otherTyping = _isTypingPayloadActive(typing);
        if (results.length > 2) {
          final sessionData = results[2] as Map<String, dynamic>;
          _booking = sessionData['booking'] as BookingModel;
          _session = sessionData['session'] as SessionPayload;
        }
        _showNewMessages = nextCount > oldCount && !shouldScroll;
      });

      if (nextCount > oldCount) {
        await BookingService.markMessagesRead(bookingId).catchError((_) {});
      }
      if (shouldScroll) _scrollToBottom();
    } catch (_) {
      // Keep the screen usable; the next poll or manual refresh will retry.
    } finally {
      _polling = false;
    }
  }

  bool _isTypingPayloadActive(Map<String, dynamic> payload) {
    final data = payload['data'];
    final raw = payload['is_typing'] ??
        payload['typing'] ??
        payload['other_typing'] ??
        (data is Map ? data['is_typing'] : null);
    return raw == true || raw == 1 || raw?.toString() == 'true';
  }

  bool _lastIsMine(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) return false;
    return _isMine(messages.last);
  }

  bool _isMine(Map<String, dynamic> message) {
    if (message['is_mine'] is bool) return message['is_mine'] as bool;
    final viewer = _session?.viewer ?? {};
    final viewerRole = viewer['role']?.toString();
    final viewerId = viewer['id']?.toString() ?? viewer['user_id']?.toString();
    final senderRole = message['sender_role']?.toString();
    final sender = message['sender'];
    final senderId = message['sender_id']?.toString() ??
        (sender is Map ? sender['id']?.toString() : null);
    if (viewerId != null && senderId != null) return viewerId == senderId;
    if (viewerRole != null && senderRole != null) {
      return viewerRole == senderRole;
    }
    return senderRole == 'user';
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    final near = max - current < 120;
    if (near != _nearBottom) {
      setState(() {
        _nearBottom = near;
        if (near) _showNewMessages = false;
      });
    }
  }

  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: force ? 120 : 260),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final bookingId = _bookingId;
    final text = _messageController.text.trim();
    if (bookingId == null || text.isEmpty || _sending || !_chatEnabled) return;

    setState(() => _sending = true);
    try {
      final message = await BookingService.sendTextMessage(bookingId, text);
      _messageController.clear();
      await BookingService.sendTyping(bookingId, false).catchError((_) {});
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, message];
        _sending = false;
      });
      _scrollToBottom(force: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _onTextChanged(String value) {
    final bookingId = _bookingId;
    if (bookingId == null || !_chatEnabled) return;
    BookingService.sendTyping(bookingId, value.trim().isNotEmpty)
        .catchError((_) {});
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      BookingService.sendTyping(bookingId, false).catchError((_) {});
    });
  }

  Future<void> _startIfNeeded() async {
    final bookingId = _bookingId;
    final session = _session;
    if (bookingId == null || session == null || !session.canStart) return;

    try {
      final data = await BookingService.startSession(bookingId);
      if (!mounted) return;
      setState(() {
        _booking = data['booking'] as BookingModel;
        _session = data['session'] as SessionPayload;
      });
      _showSnack('Session started.');
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openCall() async {
    await _startIfNeeded();
    if (!mounted) return;

    final session = _session;
    final zego = session?.zegoCall;
    final room = session?.rooms['call']?.toString();
    if (session == null || zego == null || room == null || room.isEmpty) {
      _showSnack('Call room is not ready yet.');
      return;
    }

    final appId = int.tryParse(zego['app_id']?.toString() ?? '') ?? 0;
    final token = zego['token']?.toString() ?? '';
    final appSign = zego['app_sign']?.toString() ?? '';
    if (appId <= 0 || (token.isEmpty && appSign.isEmpty)) {
      _showSnack('Voice call credentials are not configured for this session.');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ZegoUIKitPrebuiltCall(
          appID: appId,
          appSign: token.isEmpty ? appSign : '',
          token: token,
          userID: zego['user_id']?.toString() ?? 'astrozura-user',
          userName: zego['user_name']?.toString() ?? 'Astrozura User',
          callID: room,
          config: ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (picked == null) return;
    await _sendFile(picked.path, picked.name, 'image');
  }

  Future<void> _pickAndSendVideo(ImageSource source) async {
    final picked = await _imagePicker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 3),
    );
    if (picked == null) return;
    await _sendFile(picked.path, picked.name, 'video');
  }

  Future<void> _pickAndSendPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    final file = result?.files.single;
    if (file?.path == null) return;
    await _sendFile(file!.path!, file.name, 'pdf');
  }

  Future<void> _toggleRecording() async {
    _showSnack('Voice notes need recorder support in the next app build.');
  }

  Future<void> _cancelRecording() async {
    setState(() => _recording = false);
  }

  Future<void> _sendFile(String path, String fileName, String type) async {
    final bookingId = _bookingId;
    if (bookingId == null || _uploading || !_chatEnabled) return;

    setState(() => _uploading = true);
    try {
      final upload = await BookingService.uploadChatAttachment(
        filePath: path,
        fileName: fileName,
      );
      final message = await BookingService.sendAttachmentMessage(
        bookingId: bookingId,
        messageType: type,
        attachment: upload,
      );
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, message];
        _uploading = false;
      });
      _scrollToBottom(force: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showAttachmentSheet() {
    if (!_chatEnabled) {
      _showSnack('Chat opens after the session is started.');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _AttachmentAction(
                icon: Icons.photo_camera_outlined,
                label: 'Camera',
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
              _AttachmentAction(
                icon: Icons.image_outlined,
                label: 'Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
              _AttachmentAction(
                icon: Icons.videocam_outlined,
                label: 'Video',
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendVideo(ImageSource.gallery);
                },
              ),
              _AttachmentAction(
                icon: Icons.picture_as_pdf_outlined,
                label: 'PDF',
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendPdf();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    final session = _session;
    final body = _loading
        ? const Center(child: CircularProgressIndicator(color: _gold))
        : _error != null
            ? _ErrorState(message: _error!, onRetry: _load)
            : _ChatBody(
                booking: booking!,
                session: session!,
                messages: _messages,
                controller: _messageController,
                scrollController: _scrollController,
                fullscreen: _fullscreen,
                sending: _sending,
                uploading: _uploading,
                recording: _recording,
                otherTyping: _otherTyping,
                chatEnabled: _chatEnabled,
                isCall: _isCall,
                showNewMessages: _showNewMessages,
                isMine: _isMine,
                onScroll: _handleScroll,
                onRefresh: _load,
                onStart: session.canStart ? _startIfNeeded : null,
                onCall: _isCall && _chatEnabled ? _openCall : null,
                onToggleFullscreen: () =>
                    setState(() => _fullscreen = !_fullscreen),
                onAttach: _showAttachmentSheet,
                onRecord: _toggleRecording,
                onCancelRecord: _cancelRecording,
                onTextChanged: _onTextChanged,
                onSend: _sendMessage,
                onJumpBottom: () {
                  setState(() => _showNewMessages = false);
                  _scrollToBottom(force: true);
                },
              );

    return WillPopScope(
      onWillPop: () async {
        if (_fullscreen) {
          setState(() => _fullscreen = false);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: _chatBg,
        appBar: _fullscreen
            ? null
            : AppBar(
                title: Text(booking?.bookingReference ?? 'Booking Session'),
                actions: [
                  IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
        body: SafeArea(child: body),
      ),
    );
  }
}

class _ChatBody extends StatelessWidget {
  final BookingModel booking;
  final SessionPayload session;
  final List<Map<String, dynamic>> messages;
  final TextEditingController controller;
  final ScrollController scrollController;
  final bool fullscreen;
  final bool sending;
  final bool uploading;
  final bool recording;
  final bool otherTyping;
  final bool chatEnabled;
  final bool isCall;
  final bool showNewMessages;
  final bool Function(Map<String, dynamic>) isMine;
  final VoidCallback onScroll;
  final VoidCallback onRefresh;
  final VoidCallback? onStart;
  final VoidCallback? onCall;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onAttach;
  final VoidCallback onRecord;
  final VoidCallback onCancelRecord;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onSend;
  final VoidCallback onJumpBottom;

  const _ChatBody({
    required this.booking,
    required this.session,
    required this.messages,
    required this.controller,
    required this.scrollController,
    required this.fullscreen,
    required this.sending,
    required this.uploading,
    required this.recording,
    required this.otherTyping,
    required this.chatEnabled,
    required this.isCall,
    required this.showNewMessages,
    required this.isMine,
    required this.onScroll,
    required this.onRefresh,
    required this.onStart,
    required this.onCall,
    required this.onToggleFullscreen,
    required this.onAttach,
    required this.onRecord,
    required this.onCancelRecord,
    required this.onTextChanged,
    required this.onSend,
    required this.onJumpBottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: _chatBg),
      child: Column(
        children: [
          _SessionHeader(
            booking: booking,
            session: session,
            fullscreen: fullscreen,
            onStart: onStart,
            onCall: isCall ? onCall : null,
            onRefresh: onRefresh,
            onToggleFullscreen: onToggleFullscreen,
          ),
          Expanded(
            child: Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: (_) {
                    onScroll();
                    return false;
                  },
                  child: messages.isEmpty
                      ? const Center(
                          child: Text(
                            'No messages yet.',
                            style: TextStyle(color: Color(0xFF667085)),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 86),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return _MessageBubble(
                              message: message,
                              mine: isMine(message),
                            );
                          },
                        ),
                ),
                if (showNewMessages)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 14,
                    child: Center(
                      child: TextButton.icon(
                        onPressed: onJumpBottom,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        label: const Text('New messages'),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _navy,
                          elevation: 2,
                          shadowColor: Colors.black26,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (otherTyping)
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 6),
                child: Text(
                  'typing...',
                  style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                ),
              ),
            ),
          if (!chatEnabled)
            _SessionNotice(
              text: session.canStart
                  ? 'Start the session to unlock chat.'
                  : 'Chat will unlock when the astrologer starts the session.',
            ),
          _Composer(
            controller: controller,
            enabled: chatEnabled,
            sending: sending,
            uploading: uploading,
            recording: recording,
            onAttach: onAttach,
            onRecord: onRecord,
            onCancelRecord: onCancelRecord,
            onTextChanged: onTextChanged,
            onSend: onSend,
          ),
        ],
      ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  final BookingModel booking;
  final SessionPayload session;
  final bool fullscreen;
  final VoidCallback? onStart;
  final VoidCallback? onCall;
  final VoidCallback onRefresh;
  final VoidCallback onToggleFullscreen;

  const _SessionHeader({
    required this.booking,
    required this.session,
    required this.fullscreen,
    required this.onStart,
    required this.onCall,
    required this.onRefresh,
    required this.onToggleFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    final state = session.state.replaceAll('_', ' ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: const BoxDecoration(
        color: _navy,
        boxShadow: [
          BoxShadow(
              color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: Text(
              booking.astrologerName.isEmpty
                  ? 'AZ'
                  : booking.astrologerName.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: _navy, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.astrologerName.isEmpty
                      ? 'AstroZura Consultation'
                      : booking.astrologerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${booking.consultationType.toUpperCase()} - $state',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
              ],
            ),
          ),
          if (onStart != null)
            TextButton(
              onPressed: onStart,
              style: TextButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: _navy,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              child: const Text(
                'Start',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          if (onCall != null)
            IconButton(
              onPressed: onCall,
              color: Colors.white,
              icon: const Icon(Icons.call_rounded),
              tooltip: 'Connect call',
            ),
          IconButton(
            onPressed: onToggleFullscreen,
            color: Colors.white,
            icon: Icon(fullscreen
                ? Icons.close_fullscreen_rounded
                : Icons.open_in_full_rounded),
            tooltip: fullscreen ? 'Exit full screen' : 'Full screen',
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool mine;

  const _MessageBubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    final type = message['message_type']?.toString() ?? 'text';
    final timestamp = _formatTime(
      message['created_at']?.toString() ?? message['sent_at']?.toString(),
    );
    final read = message['read_at'] != null;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.fromLTRB(12, 9, 10, 7),
          decoration: BoxDecoration(
            color: mine ? const Color(0xFFE7F6DA) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 3),
              bottomRight: Radius.circular(mine ? 3 : 16),
            ),
            border: Border.all(
              color: mine ? const Color(0xFFC8E6B6) : const Color(0xFFE5DED0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MessageContent(message: message, type: type),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timestamp,
                    style: TextStyle(fontSize: 10.5, color: Colors.grey[600]),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      read ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 15,
                      color: read ? Colors.blueAccent : Colors.grey,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}

class _MessageContent extends StatelessWidget {
  final Map<String, dynamic> message;
  final String type;

  const _MessageContent({required this.message, required this.type});

  @override
  Widget build(BuildContext context) {
    final text = (message['text'] ?? message['body'] ?? '').toString();
    final mediaUrl = _mediaUrl(message);
    if (type == 'image' && mediaUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          mediaUrl,
          width: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _FileChip(type: type, url: mediaUrl),
        ),
      );
    }
    if (mediaUrl != null && type != 'text') {
      return _FileChip(type: type, url: mediaUrl);
    }
    return Text(
      text.isEmpty ? '-' : text,
      style: const TextStyle(fontSize: 14.5, height: 1.35, color: _navy),
    );
  }

  String? _mediaUrl(Map<String, dynamic> message) {
    final raw = message['media_url'] ??
        message['attachment_url'] ??
        message['url'] ??
        message['file_url'];
    if (raw == null || raw.toString().trim().isEmpty) return null;
    return ApiConstants.storageUrl(raw.toString());
  }
}

class _FileChip extends StatelessWidget {
  final String type;
  final String url;

  const _FileChip({required this.type, required this.url});

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'audio' => Icons.mic_none_rounded,
      'video' => Icons.play_circle_outline_rounded,
      _ => Icons.attach_file_rounded,
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5DED0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _navy),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              type == 'audio' ? 'Voice note' : '${type.toUpperCase()} file',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool sending;
  final bool uploading;
  final bool recording;
  final VoidCallback onAttach;
  final VoidCallback onRecord;
  final VoidCallback onCancelRecord;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.enabled,
    required this.sending,
    required this.uploading,
    required this.recording,
    required this.onAttach,
    required this.onRecord,
    required this.onCancelRecord,
    required this.onTextChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        6,
        8,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5DED0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: enabled && !uploading ? onAttach : null,
                    icon: uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.attach_file_rounded),
                  ),
                  Expanded(
                    child: recording
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              children: [
                                const Icon(Icons.fiber_manual_record,
                                    color: Colors.red, size: 14),
                                const SizedBox(width: 8),
                                const Expanded(child: Text('Recording...')),
                                TextButton(
                                  onPressed: onCancelRecord,
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                          )
                        : TextField(
                            controller: controller,
                            enabled: enabled && !sending,
                            minLines: 1,
                            maxLines: 4,
                            onChanged: onTextChanged,
                            decoration: const InputDecoration(
                              hintText: 'Message',
                              border: InputBorder.none,
                            ),
                          ),
                  ),
                  IconButton(
                    onPressed: enabled && !uploading ? onRecord : null,
                    icon: Icon(recording
                        ? Icons.stop_circle_outlined
                        : Icons.mic_none_rounded),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),
          IconButton.filled(
            onPressed: enabled && !sending && !recording ? onSend : null,
            style: IconButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}

class _AttachmentAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _gold.withOpacity(0.18),
                child: Icon(icon, color: _navy),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionNotice extends StatelessWidget {
  final String text;

  const _SessionNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withOpacity(0.45)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _navy, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
