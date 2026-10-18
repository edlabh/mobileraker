/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

/// Evento de conexão WebRTC (union selada — variantes com os mesmos nomes do
/// pacote oficial, reconstruídos a partir do binário 2.9.14).
sealed class WebRtcConnectionEvent {
  const WebRtcConnectionEvent();
}

/// Uma nova conexão foi iniciada (manager recriado).
class WebRtcConnectionEventNew extends WebRtcConnectionEvent {
  const WebRtcConnectionEventNew();

  @override
  String toString() => 'WebRtcConnectionEventNew';
}

/// Conectando (peer connection/sinalização em andamento).
class WebRtcConnectionEventConnecting extends WebRtcConnectionEvent {
  const WebRtcConnectionEventConnecting();

  @override
  String toString() => 'WebRtcConnectionEventConnecting';
}

/// Conectado (track de vídeo recebido).
class WebRtcConnectionEventConnected extends WebRtcConnectionEvent {
  const WebRtcConnectionEventConnected();

  @override
  String toString() => 'WebRtcConnectionEventConnected';
}

/// Conexão interrompida (pode reconectar).
class WebRtcConnectionEventDisconnected extends WebRtcConnectionEvent {
  const WebRtcConnectionEventDisconnected();

  @override
  String toString() => 'WebRtcConnectionEventDisconnected';
}

/// Conexão encerrada.
class WebRtcConnectionEventClosed extends WebRtcConnectionEvent {
  const WebRtcConnectionEventClosed();

  @override
  String toString() => 'WebRtcConnectionEventClosed';
}

/// Falha na conexão, com o erro original.
class WebRtcConnectionEventFailed extends WebRtcConnectionEvent {
  const WebRtcConnectionEventFailed(this.error);

  final Object error;

  @override
  String toString() => 'WebRtcConnectionEventFailed{error: $error}';
}
