/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

part of 'webrtc_manager.dart';

/// camera-streamer (dw-0) — WebRTC via `POST /webrtc` com SDP
/// (fluxo "client offer" da classe base).
class CameraStreamerManager extends WebRtcManagerBase {
  CameraStreamerManager({required super.camUri, required super.dio, super.headers});

  @override
  Uri get _offerUri {
    final path = (camUri.path.isEmpty || camUri.path == '/') ? '/webrtc' : camUri.path;
    return camUri.replace(path: path, query: '');
  }

  @override
  Future<void> _setupPeerConnection() async {
    talker.info('$_logTag Setting up PeerConnection for CameraStreamer');
    final pc = await createPeerConnection(_linkToIceServers());
    _peerConnection = pc;
    pc.onTrack = _onTrack;
    pc.onConnectionState = _onConnectionState;
    pc.onSignalingState = _onSignalingState;
    await pc.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );
    await _sendOffer();
  }
}
