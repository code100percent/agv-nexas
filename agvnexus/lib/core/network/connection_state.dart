import 'package:flutter/material.dart';

/// Connection health and integration state for live telemetry & backend services.
enum ConnectionStatus {
  disconnected,
  connecting,
  connectedLive,
  simulated,
  degraded,
  error;

  String get label {
    switch (this) {
      case ConnectionStatus.disconnected:
        return 'DISCONNECTED';
      case ConnectionStatus.connecting:
        return 'CONNECTING';
      case ConnectionStatus.connectedLive:
        return 'LIVE TELEMETRY';
      case ConnectionStatus.simulated:
        return 'SIMULATED / DEMO';
      case ConnectionStatus.degraded:
        return 'DEGRADED';
      case ConnectionStatus.error:
        return 'GATEWAY ERROR';
    }
  }

  Color get color {
    switch (this) {
      case ConnectionStatus.disconnected:
        return const Color(0xFF766B63); // mutedText
      case ConnectionStatus.connecting:
        return const Color(0xFF456B7D); // info
      case ConnectionStatus.connectedLive:
        return const Color(0xFF2E6347); // success
      case ConnectionStatus.simulated:
        return const Color(0xFF722E37); // deepBurgundy primary
      case ConnectionStatus.degraded:
        return const Color(0xFFB06500); // warning
      case ConnectionStatus.error:
        return const Color(0xFF9E2A2B); // error
    }
  }
}
