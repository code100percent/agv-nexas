import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../domain/telemetry_model.dart';

/// Production-ready WebSocket client for real-time robot telemetry streaming.
/// Features subscription multiplexing, exponential reconnect backoff, and heartbeat monitoring.
class TelemetryWebSocketClient {
  final String wsBaseUrl;
  final String? authToken;
  final String? initialRobotId;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  final _telemetryController = StreamController<TelemetryModel>.broadcast();
  final Set<String> _subscribedRobots = {};

  bool _isDisposed = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectBackoffSeconds = 16;

  TelemetryWebSocketClient({
    required this.wsBaseUrl,
    this.authToken,
    this.initialRobotId,
  }) {
    if (initialRobotId != null) {
      _subscribedRobots.add(initialRobotId!);
    }
    _connect();
  }

  Stream<TelemetryModel> get telemetryStream => _telemetryController.stream;

  void subscribeToRobot(String robotId) {
    _subscribedRobots.add(robotId);
    if (_channel != null) {
      _sendJson({'action': 'subscribe', 'robot_id': robotId});
    }
  }

  void unsubscribeFromRobot(String robotId) {
    _subscribedRobots.remove(robotId);
    if (_channel != null) {
      _sendJson({'action': 'unsubscribe', 'robot_id': robotId});
    }
  }

  void _connect() {
    if (_isDisposed) return;

    try {
      final uri = Uri.parse(wsBaseUrl).replace(
        queryParameters: {
          if (authToken != null) 'token': authToken,
          if (_subscribedRobots.isNotEmpty) 'robot_id': _subscribedRobots.first,
        },
      );

      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        _onMessageReceived,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: true,
      );

      _reconnectAttempts = 0;
      _startHeartbeat();

      // Resubscribe to all tracked robots
      for (final r in _subscribedRobots) {
        _sendJson({'action': 'subscribe', 'robot_id': r});
      }

      debugPrint('[TelemetryWS] Connected to $uri');
    } catch (e) {
      debugPrint('[TelemetryWS] Connection error: $e');
      _scheduleReconnect();
    }
  }

  void _onMessageReceived(dynamic message) {
    try {
      final data = json.decode(message as String) as Map<String, dynamic>;
      final event = data['event'] as String?;

      if (event == 'robot.telemetry' && data['payload'] != null) {
        final payload = data['payload'] as Map<String, dynamic>;
        final telem = TelemetryModel.fromJson(payload);
        _telemetryController.add(telem);
      } else if (event == 'heartbeat') {
        // Pong received from gateway
      }
    } catch (e) {
      debugPrint('[TelemetryWS] Failed to parse message: $e');
    }
  }

  void _onError(dynamic error) {
    debugPrint('[TelemetryWS] Error: $error');
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[TelemetryWS] Connection closed');
    _scheduleReconnect();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_channel != null && !_isDisposed) {
        _sendJson({'action': 'ping'});
      }
    });
  }

  void _sendJson(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(json.encode(data));
    } catch (e) {
      debugPrint('[TelemetryWS] Send error: $e');
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;

    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    _channel = null;

    final delaySeconds = (_reconnectAttempts < 5)
        ? (1 << _reconnectAttempts)
        : _maxReconnectBackoffSeconds;
    _reconnectAttempts++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isDisposed) {
        _connect();
      }
    });
  }

  void dispose() {
    _isDisposed = true;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _telemetryController.close();
  }
}
