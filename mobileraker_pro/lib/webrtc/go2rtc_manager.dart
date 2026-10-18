/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:common/util/logger.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'data/webrtc_connection_event.dart';
import 'webrtc_manager.dart';

/// go2rtc — sinalização pela WebSocket API (`/api/ws?src=<stream>`).
class Go2RtcManager extends WebRTCManagerBase {
  Go2RtcManager({required super.camUri, required super.dio, super.headers});

  WebSocket? _socket;

  Uri get _go2RtcApiUri {
    final src = camUri.queryParameters['src'] ?? camUri.queryParameters['name'] ?? 'camera';
    return camUri.replace(
      scheme: camUri.scheme == 'https' ? 'wss' : 'ws',
      path: '/api/ws',
      queryParameters: {'src': src},
    );
  }

  @override
  Future<void> connect(RTCPeerConnection pc) async {
    talker.info('WebRTC[$runtimeType]: conectando ao WebSocket ${_go2RtcApiUri}...');
    final socket = await WebSocket.connect(_go2RtcApiUri.toString()).timeout(const Duration(seconds: 6));
    talker.info('WebRTC[$runtimeType]: WebSocket conectada');
    _socket = socket;
    socket.listen(
      (dynamic message) => _onMessage(message),
      onError: (Object error) => emitEvent(WebRTCConnectionEvent(
        state: WebRTCConnectionState.failed,
        message: 'Erro na conexão WebSocket do go2rtc',
        error: error,
      )),
      onDone: () {
        if (socket.closeCode != 1000) {
          emitEvent(const WebRTCConnectionEvent(
            state: WebRTCConnectionState.disconnected,
            message: 'WebSocket do go2rtc encerrada',
          ));
        }
      },
    );
    final offer = await createOffer(pc);
    socket.add(jsonEncode({'type': 'webrtc/offer', 'value': offer.sdp}));
    talker.info('WebRTC[$runtimeType]: offer enviado (${offer.sdp?.length} bytes)');
  }

  Future<void> _onMessage(dynamic message) async {
    if (message is! String) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(message);
    } catch (_) {
      return;
    }
    if (decoded is! Map) return;
    talker.info('WebRTC[$runtimeType]: msg do go2rtc: ${decoded['type']}');
    switch (decoded['type']) {
      case 'webrtc/answer':
        final sdp = decoded['value'];
        if (sdp is String && sdp.isNotEmpty) {
          await applyAnswer(RTCSessionDescription(sdp, 'answer'));
        }
      case 'webrtc/candidate':
        var value = (decoded['value'] as String?)?.trim() ?? '';
        if (value.startsWith('a=')) value = value.substring(2);
        if (value.isNotEmpty) {
          await addRemoteCandidate(RTCIceCandidate(value, '0', 0));
        }
      case 'error':
        emitEvent(WebRTCConnectionEvent(
          state: WebRTCConnectionState.failed,
          message: '${decoded['value']}',
        ));
    }
  }

  @override
  Future<void> onLocalCandidate(RTCIceCandidate? candidate) async {
    final socket = _socket;
    final value = candidate?.candidate;
    if (socket == null || value == null || value.isEmpty) return;
    socket.add(jsonEncode({'type': 'webrtc/candidate', 'value': value}));
  }

  @override
  Future<void> dispose() async {
    try {
      await _socket?.close();
    } catch (_) {
      // socket já encerrado
    }
    _socket = null;
    await super.dispose();
  }
}
