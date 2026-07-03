import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../core/services/booking_service.dart';

class BookingSessionScreen extends StatefulWidget {
  const BookingSessionScreen({super.key});

  @override
  State<BookingSessionScreen> createState() => _BookingSessionScreenState();
}

class _BookingSessionScreenState extends State<BookingSessionScreen> {
  final _messageController = TextEditingController();

  int? _bookingId;
  BookingModel? _booking;
  SessionPayload? _session;
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
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
    _messageController.dispose();
    super.dispose();
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
      final sessionData = await BookingService.getSession(bookingId);
      final messages = await BookingService.getMessages(bookingId);
      if (!mounted) return;
      setState(() {
        _booking = sessionData['booking'] as BookingModel;
        _session = sessionData['session'] as SessionPayload;
        _messages = messages;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _sendMessage() async {
    final bookingId = _bookingId;
    final text = _messageController.text.trim();
    if (bookingId == null || text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final message = await BookingService.sendTextMessage(bookingId, text);
      _messageController.clear();
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, message];
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _startIfNeeded() async {
    final bookingId = _bookingId;
    final session = _session;
    if (bookingId == null || session == null || !session.canStart) return;

    final data = await BookingService.startSession(bookingId);
    if (!mounted) return;
    setState(() {
      _booking = data['booking'] as BookingModel;
      _session = data['session'] as SessionPayload;
    });
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
      _showSnack('Zego credentials are not configured for this session.');
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
          config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    final session = _session;
    final canOpenCall = booking?.consultationType == 'call' &&
        session != null &&
        (session.canJoin || session.canStart || session.isLive);

    return Scaffold(
      appBar: AppBar(
        title: Text(booking?.bookingReference ?? 'Booking Session'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorState(message: _error!, onRetry: _load)
                : Column(
                    children: [
                      _SessionHeader(
                        booking: booking!,
                        session: session!,
                        onOpenCall: canOpenCall ? _openCall : null,
                      ),
                      Expanded(
                        child: _messages.isEmpty
                            ? const Center(child: Text('No messages yet.'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  return _MessageBubble(message: message);
                                },
                              ),
                      ),
                      _Composer(
                        controller: _messageController,
                        sending: _sending,
                        onSend: _sendMessage,
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  final BookingModel booking;
  final SessionPayload session;
  final VoidCallback? onOpenCall;

  const _SessionHeader({
    required this.booking,
    required this.session,
    required this.onOpenCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.astrologerName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text('${booking.consultationType} • ${session.state}'),
              ],
            ),
          ),
          if (onOpenCall != null)
            IconButton.filled(
              onPressed: onOpenCall,
              icon: const Icon(Icons.video_call),
              tooltip: 'Join call',
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final role = message['sender_role']?.toString() ?? '';
    final isUser = role == 'user';
    final text = message['text']?.toString() ?? '';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2E2A72) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
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
