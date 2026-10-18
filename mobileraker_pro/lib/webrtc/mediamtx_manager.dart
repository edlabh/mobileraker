/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

part of 'webrtc_manager.dart';

/// Oferta gerada pelo mediaMTX (SDP + URL da sessão para o trickle).
class MediamtxOffer {
  const MediamtxOffer({required this.sdp, required this.location});

  final String sdp;
  final String? location;
}

/// mediaMTX — WHEP com oferta gerada pelo servidor:
/// `POST <path>/whep` (sem corpo) → oferta + header `Location`;
/// a resposta é enviada para o `Location` e os candidatos via PATCH
/// (`application/trickle-ice-sdpfrag`).
class MediaMtxWebRtcManager extends WebRtcManagerBase {
  MediaMtxWebRtcManager({required super.camUri, required super.dio, super.headers});

  String? _sessionUrl;

  Uri get _whepUri {
    final path = camUri.path.endsWith('/whep') ? camUri.path : '${camUri.path}/whep';
    return camUri.replace(path: path, query: '');
  }

  @override
  Future<void> _setupPeerConnection() async {
    talker.info('$_logTag Setting up PeerConnection for MediaMtx');
    final pc = await createPeerConnection(_linkToIceServers());
    _peerConnection = pc;
    pc.onTrack = _onTrack;
    pc.onConnectionState = _onConnectionState;
    pc.onSignalingState = _onSignalingState;
    pc.onIceCandidate = _onIceCandidate;
    await pc.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );
    await _requestOffer();
  }

  /// Solicita a oferta ao mediaMTX (WHEP com oferta do servidor).
  Future<void> _requestOffer() async {
    final response = await dio.postUri<String>(
      _whepUri,
      options: Options(
        headers: headers,
        responseType: ResponseType.plain,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    final location = response.headers.value('location');
    if (location == null || location.isEmpty) {
      const message = 'MediaMTX failed to return a location header for the session';
      talker.error('$_logTag $message');
      _connectionState = const WebRtcConnectionEventFailed(message);
      return;
    }
    _sessionUrl = _whepUri.resolve(location).toString();
    final offer = MediamtxOffer(sdp: response.data ?? '', location: _sessionUrl);
    await _parseOffer(RTCSessionDescription(offer.sdp, 'offer'));
    await _sendAnswer();
  }

  /// Cria e envia a resposta para o `Location` da sessão.
  Future<void> _sendAnswer() async {
    final sessionUrl = _sessionUrl;
    if (sessionUrl == null) return;
    final pc = _peerConnection;
    if (pc == null) return;
    final answer = await pc.createAnswer({});
    await pc.setLocalDescription(answer);
    final localDescription = await pc.getLocalDescription();
    await dio.postUri<String>(
      Uri.parse(sessionUrl),
      data: localDescription?.sdp ?? answer.sdp,
      options: Options(
        headers: {...headers, 'Content-Type': 'application/sdp'},
        responseType: ResponseType.plain,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
  }

  /// Candidatos locais vão por PATCH (trickle) para a sessão.
  void _onIceCandidate(RTCIceCandidate candidate) {
    final sessionUrl = _sessionUrl;
    if (sessionUrl == null) return;
    _sendLocalCandidates(sessionUrl, candidate);
  }

  @override
  Future<void> dispose() async {
    final sessionUrl = _sessionUrl;
    if (sessionUrl != null) {
      try {
        await dio.deleteUri(Uri.parse(sessionUrl));
      } catch (_) {
        // sessão já encerrada no servidor
      }
    }
    _sessionUrl = null;
    await super.dispose();
  }
}
