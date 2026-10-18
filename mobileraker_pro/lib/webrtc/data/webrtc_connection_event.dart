/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

/// Estado de uma conexão WebRTC de webcam.
enum WebRTCConnectionState { connecting, connected, disconnected, failed, closed }

/// Evento de conexão WebRTC (estado + mensagem/erro opcionais).
class WebRTCConnectionEvent {
  const WebRTCConnectionEvent({required this.state, this.message, this.error});

  final WebRTCConnectionState state;
  final String? message;
  final Object? error;

  @override
  String toString() => 'WebRTCConnectionEvent(state: $state, message: $message, error: $error)';
}
