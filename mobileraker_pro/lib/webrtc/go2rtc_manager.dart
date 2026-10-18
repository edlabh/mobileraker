/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

part of 'webrtc_manager.dart';

/// go2rtc — sinalização pela WebSocket API (`/api/ws?src=<stream>`).
class Go2RtcManager extends WebRtcManagerBase {
  Go2RtcManager({required super.camUri, required super.dio, super.headers});

  WebSocketChannel? _channel;
  bool _resetting = false;

  /// Transforma a URL da câmera na URL da API do go2rtc.
  Uri get _go2RtcApiUri {
    final src = camUri.queryParameters['src'] ?? camUri.queryParameters['name'] ?? 'camera';
    final apiUri = camUri.replace(
      scheme: camUri.scheme == 'https' ? 'wss' : 'ws',
      path: '/api/ws',
      queryParameters: {'src': src},
    );
    talker.info('$_logTag Transformed camUri to apiUri: $apiUri');
    return apiUri;
  }

  @override
  Future<void> _setupPeerConnection() async {
    talker.info('$_logTag Setting up PeerConnection for Go2Rtc');
    final pc = await createPeerConnection(_linkToIceServers());
    _peerConnection = pc;
    pc.onTrack = _onTrack;
    pc.onConnectionState = _onConnectionState;
    pc.onSignalingState = _onSignalingState;
    pc.onIceCandidate = _onLocalIceCandidate;
    await pc.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );
    await _setupWebSocket();
  }

  Future<void> _setupWebSocket() async {
    talker.info('$_logTag Setting up WebSocket for Go2Rtc');
    final channel = WebSocketChannel.connect(_go2RtcApiUri);
    _channel = channel;
    channel.stream.listen(
      _onChannelMessage,
      onError: _onChannelError,
      onDone: _onChannelDone,
      cancelOnError: false,
    );
    await channel.ready;
    talker.info('$_logTag Go2Rtc WebSocket connected: ${_go2RtcApiUri}');
    await _sendOffer();
  }

  Future<void> _sendOffer() async {
    talker.info('$_logTag Sending offer to Go2Rtc api');
    final pc = _peerConnection;
    if (pc == null) return;
    final offer = await pc.createOffer({});
    await pc.setLocalDescription(offer);
    final localDescription = await pc.getLocalDescription();
    _sendToServer({'type': 'webrtc/offer', 'value': localDescription?.sdp ?? offer.sdp});
  }

  void _sendToServer(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  void _onChannelMessage(dynamic message) {
    if (message is! String) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(message);
    } catch (_) {
      return;
    }
    if (decoded is! Map) return;
    switch (decoded['type']) {
      case 'webrtc/answer':
        final sdp = decoded['value'];
        if (sdp is String && sdp.isNotEmpty) {
          _onRemoteAnswer(RTCSessionDescription(sdp, 'answer'));
        }
      case 'webrtc/candidate':
        final value = (decoded['value'] as String?)?.trim() ?? '';
        if (value.isNotEmpty) {
          _onIceCandidate(RTCIceCandidate(value.startsWith('a=') ? value.substring(2) : value, '0', 0));
        }
      case 'error':
        _connectionState = WebRtcConnectionEventFailed('${decoded['value']}');
    }
  }

  void _onChannelError(Object error, [StackTrace? stackTrace]) {
    talker.error('$_logTag Go2Rtc WebSocket error', error, stackTrace);
    _connectionState = WebRtcConnectionEventFailed(error);
    _reset();
  }

  void _onChannelDone() {
    talker.info('$_logTag Go2Rtc WebSocket closed');
    if (!_disposed) {
      _connectionState = const WebRtcConnectionEventClosed();
      _reset();
    }
  }

  /// Candidato remoto recebido do go2rtc.
  void _onIceCandidate(RTCIceCandidate candidate) {
    talker.info('$_logTag Received a new ICE candidate from Go2Rtc');
    _peerConnection?.addCandidate(candidate);
  }

  /// Envia candidatos locais ao go2rtc pela WebSocket.
  void _onLocalIceCandidate(RTCIceCandidate candidate) {
    final value = candidate.candidate;
    if (value == null || value.isEmpty) return;
    _sendToServer({'type': 'webrtc/candidate', 'value': value});
  }

  /// Recria a conexão (WebSocket + PeerConnection) do zero.
  Future<void> _reset() async {
    if (_resetting || _disposed) return;
    _resetting = true;
    talker.info('$_logTag Resetting go2rtc manager');
    try {
      await _channel?.sink.close();
      _channel = null;
      await _peerConnection?.close();
      _peerConnection = null;
      if (!_disposed) {
        _connectionState = const WebRtcConnectionEventConnecting();
        await _setupPeerConnection();
      }
    } catch (error) {
      talker.error('$_logTag Reset failed', error);
    } finally {
      _resetting = false;
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _channel?.sink.close();
    } catch (_) {
      // socket já encerrado
    }
    _channel = null;
    await super.dispose();
  }
}
