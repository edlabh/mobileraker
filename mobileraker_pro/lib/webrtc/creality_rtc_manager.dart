/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

part of 'webrtc_manager.dart';

/// Câmeras WebRTC proprietárias da Creality.
///
/// Fluxo: cria a oferta (aguardando o ICE gathering completo), envia para a
/// câmera e aplica a resposta — com o ajuste conhecido do SDP da Creality
/// ([_fixCrealitySDP]).
class CrealityRtcManager extends WebRtcManagerBase {
  CrealityRtcManager({required super.camUri, required super.dio, super.headers});

  @override
  Future<void> _setupPeerConnection() async {
    talker.info('$_logTag Setting up PeerConnection for CrealityRtc');
    final pc = await createPeerConnection(_linkToIceServers());
    _peerConnection = pc;
    pc.onTrack = _onTrack;
    pc.onConnectionState = _onConnectionState;
    pc.onSignalingState = _onSignalingState;
    pc.onIceCandidate = _onIceCandidate;
    pc.onIceGatheringState = _onIceGathering;
    await pc.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );
    await _sendOffer();
  }

  Future<void> _sendOffer() async {
    talker.info('$_logTag Sending offer to Creality RTC');
    final pc = _peerConnection;
    if (pc == null) return;
    final offer = await pc.createOffer({});
    await pc.setLocalDescription(offer);
    await _waitForIceGathering(pc);
    final localDescription = await pc.getLocalDescription();
    final response = await dio.postUri<String>(
      camUri.replace(query: ''),
      data: localDescription?.sdp ?? offer.sdp,
      options: Options(
        headers: {...headers, 'Content-Type': 'application/sdp'},
        responseType: ResponseType.plain,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    await _handleAnswer(response.data);
  }

  /// Interpreta a resposta da câmera (SDP puro ou JSON com `answer`/`sdp`).
  Future<void> _handleAnswer(dynamic data) async {
    final raw = switch (data) {
      String value => value,
      Map value => (value['answer'] ?? value['sdp'] ?? value['value']) as String? ?? '',
      _ => '',
    };
    if (raw.isEmpty) {
      _connectionState = const WebRtcConnectionEventFailed('Resposta inválida da câmera Creality');
      return;
    }
    final answer = _fixCrealitySDP(raw);
    await _onRemoteAnswer(RTCSessionDescription(answer, 'answer'));
  }

  /// Correção conhecida do SDP das câmeras Creality: garante que o lado do
  /// app seja o iniciador do DTLS (`a=setup:active`), necessário porque o
  /// anúncio da câmera vem como `actpass` e não é negociado corretamente.
  String _fixCrealitySDP(String sdp) {
    return sdp.replaceAll('a=setup:actpass', 'a=setup:active');
  }

  void _onIceCandidate(RTCIceCandidate candidate) {
    talker.debug('$_logTag ICE candidate: ${candidate.candidate}');
  }

  void _onIceGathering(RTCIceGatheringState state) {
    talker.debug('$_logTag ICE gathering state: $state');
  }
}
