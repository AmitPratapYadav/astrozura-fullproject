import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../contants/api_constants.dart';

typedef ReverbMessageCallback = void Function(Map<String, dynamic> message);
typedef ReverbPayloadCallback = void Function(Map<String, dynamic> payload);
typedef ReverbStateCallback = void Function(bool connected);
typedef ReverbErrorCallback = void Function(Object error);

class ReverbBookingChatService {
  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  int? _bookingId;
  Map<String, dynamic> _chatConfig = {};
  ReverbMessageCallback? _onMessage;
  ReverbPayloadCallback? _onTyping;
  ReverbPayloadCallback? _onSessionChanged;
  ReverbStateCallback? _onConnectionChanged;
  ReverbErrorCallback? _onError;

  String? _channelName;
  bool _manuallyClosed = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;

  Future<void> connect({
    required int bookingId,
    required Map<String, dynamic> chatConfig,
    required ReverbMessageCallback onMessage,
    required ReverbPayloadCallback onTyping,
    required ReverbPayloadCallback onSessionChanged,
    required ReverbStateCallback onConnectionChanged,
    ReverbErrorCallback? onError,
  }) async {
    final nextChannel =
        _text(chatConfig['channel'], fallback: 'private-booking.$bookingId');
    final sameConnection = _socket != null &&
        _bookingId == bookingId &&
        _channelName == nextChannel &&
        _socket?.readyState == WebSocket.open;

    _bookingId = bookingId;
    _chatConfig = Map<String, dynamic>.from(chatConfig);
    _channelName = nextChannel;
    _onMessage = onMessage;
    _onTyping = onTyping;
    _onSessionChanged = onSessionChanged;
    _onConnectionChanged = onConnectionChanged;
    _onError = onError;
    _manuallyClosed = false;

    if (sameConnection || _isConnecting) return;

    await _open();
  }

  Future<void> disconnect() async {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    await _socket?.close();
    _socket = null;
    _onConnectionChanged?.call(false);
  }

  Future<void> _open() async {
    if (_isConnecting) return;
    _isConnecting = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();

    try {
      final uri = _webSocketUri(_chatConfig);
      final socket = await WebSocket.connect(uri.toString());
      _socket = socket;
      _reconnectAttempts = 0;
      _subscription = socket.listen(
        _handleFrame,
        onError: (error) {
          _onError?.call(error);
          _handleDisconnect();
        },
        onDone: _handleDisconnect,
        cancelOnError: true,
      );
    } catch (error) {
      _onConnectionChanged?.call(false);
      _onError?.call(error);
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _handleFrame(dynamic frame) async {
    try {
      final payload = _decodeMap(frame);
      final event = _text(payload['event']);
      final data = _decodeMap(payload['data']);

      switch (event) {
        case 'pusher:connection_established':
          _startPing(data['activity_timeout']);
          await _authorizeAndSubscribe(data['socket_id']?.toString());
          break;
        case 'pusher:ping':
          _send({'event': 'pusher:pong', 'data': <String, dynamic>{}});
          break;
        case 'pusher:subscription_succeeded':
        case 'pusher_internal:subscription_succeeded':
          _onConnectionChanged?.call(true);
          break;
        case 'booking.message.created':
        case '.booking.message.created':
          final message = _decodeMap(data['message']);
          if (message.isNotEmpty) _onMessage?.call(message);
          break;
        case 'booking.typing':
        case '.booking.typing':
          _onTyping?.call(data);
          break;
        case 'booking.session.changed':
        case '.booking.session.changed':
          _onSessionChanged?.call(data);
          break;
        case 'pusher:error':
          _onError?.call(data.isEmpty ? payload : data);
          break;
      }
    } catch (error) {
      _onError?.call(error);
      _handleDisconnect();
    }
  }

  Future<void> _authorizeAndSubscribe(String? socketId) async {
    final channelName = _channelName;
    if (socketId == null || socketId.isEmpty || channelName == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated for chat websocket.');
    }

    final response = await http
        .post(
          _authUri(_chatConfig),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'socket_id': socketId,
            'channel_name': channelName,
          }),
        )
        .timeout(const Duration(seconds: 12));

    final body = _decodeMap(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body['message']?.toString() ??
            'Chat channel auth failed (${response.statusCode}).',
      );
    }

    final data = <String, dynamic>{
      'auth': body['auth'],
      'channel': channelName,
      if (body['channel_data'] != null) 'channel_data': body['channel_data'],
      if (body['shared_secret'] != null) 'shared_secret': body['shared_secret'],
    };
    _send({'event': 'pusher:subscribe', 'data': data});
  }

  void _startPing(dynamic timeoutValue) {
    final seconds = int.tryParse(timeoutValue?.toString() ?? '') ?? 30;
    final interval = Duration(seconds: seconds.clamp(15, 120));
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(interval, (_) {
      _send({'event': 'pusher:ping', 'data': <String, dynamic>{}});
    });
  }

  void _handleDisconnect() {
    _pingTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _socket = null;
    _onConnectionChanged?.call(false);
    if (!_manuallyClosed) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manuallyClosed || _bookingId == null || _chatConfig.isEmpty) return;
    _reconnectTimer?.cancel();
    _reconnectAttempts += 1;
    final seconds = _reconnectAttempts < 6 ? _reconnectAttempts * 2 : 15;
    _reconnectTimer = Timer(Duration(seconds: seconds), _open);
  }

  void _send(Map<String, dynamic> payload) {
    final socket = _socket;
    if (socket == null || socket.readyState != WebSocket.open) return;
    socket.add(jsonEncode(payload));
  }

  Uri _webSocketUri(Map<String, dynamic> config) {
    final appKey = _text(config['app_key'], fallback: 'astrozura-local-key');
    final scheme =
        _text(config['scheme'], fallback: 'https').toLowerCase().trim() ==
                'https'
            ? 'wss'
            : 'ws';
    final host = _normalizedHost(_text(config['host']));
    final port = int.tryParse(config['port']?.toString() ?? '');
    final path = '/app/${Uri.encodeComponent(appKey)}';

    return Uri(
      scheme: scheme,
      host: host,
      port: _shouldIncludePort(scheme, port) ? port! : 0,
      path: path,
      queryParameters: const {
        'protocol': '7',
        'client': 'astrozura-flutter',
        'version': '1.0.0',
        'flash': 'false',
      },
    );
  }

  Uri _authUri(Map<String, dynamic> config) {
    final raw = _text(config['auth_endpoint'], fallback: '/broadcasting/auth');
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return Uri.parse(raw);
    }

    final normalized = raw.startsWith('/') ? raw.substring(1) : raw;
    final apiPath =
        normalized.startsWith('api/') ? normalized.substring(4) : normalized;
    return Uri.parse(ApiConstants.endpoint(apiPath));
  }

  bool _shouldIncludePort(String scheme, int? port) {
    if (port == null || port <= 0) return false;
    return !((scheme == 'wss' && port == 443) ||
        (scheme == 'ws' && port == 80));
  }

  String _normalizedHost(String rawHost) {
    var host = rawHost.trim();
    if (host.startsWith('http://') || host.startsWith('https://')) {
      host = Uri.parse(host).host;
    }
    if (host == '127.0.0.1' ||
        host == '0.0.0.0' ||
        host == 'localhost' ||
        host.isEmpty) {
      return Uri.parse(ApiConstants.webBaseUrl).host;
    }
    return host;
  }

  Map<String, dynamic> _decodeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return {};
      }
    }
    return {};
  }

  String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
