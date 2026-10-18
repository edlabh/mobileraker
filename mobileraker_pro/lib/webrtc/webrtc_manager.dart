/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:async';
import 'dart:convert';

import 'package:common/data/enums/webcam_service_type.dart';
import 'package:common/util/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'data/webrtc_connection_event.dart';

part 'camerastreamer_manager.dart';
part 'creality_rtc_manager.dart';
part 'go2rtc_manager.dart';
part 'mediamtx_manager.dart';

/// Gerenciador WebRTC de uma câmera (por tipo de serviço).
abstract class WebRtcManager {
  /// Cria o gerenciador adequado para o tipo de câmera.
  static WebRtcManager forService({
    required WebcamServiceType service,
    required Uri camUri,
    required Dio dio,
    Map<String, String> headers = const {},
  }) {
    return switch (service) {
      WebcamServiceType.webRtcGo2Rtc => Go2RtcManager(camUri: camUri, dio: dio, headers: headers),
      WebcamServiceType.webRtcCamStreamer => CameraStreamerManager(camUri: camUri, dio: dio, headers: headers),
      WebcamServiceType.webRtcMediaMtx => MediaMtxWebRtcManager(camUri: camUri, dio: dio, headers: headers),
      WebcamServiceType.webRtcCreality => CrealityRtcManager(camUri: camUri, dio: dio, headers: headers),
      _ => throw ArgumentError('Service $service is not a WebRTC service'),
    };
  }

  /// Eventos de estado da conexão.
  Stream<WebRtcConnectionEvent> get connectionEvents;

  /// Renderer de vídeo (usado pelo `RTCVideoView`).
  RTCVideoRenderer get renderer;

  Future<void> initialize();

  Future<void> dispose();
}

/// Base comum dos gerenciadores: PeerConnection, renderer, eventos e os
/// utilitários do protocolo WHEP (oferta/resposta e trickle ICE).
abstract class WebRtcManagerBase implements WebRtcManager {
  WebRtcManagerBase({required this.camUri, required this.dio, this.headers = const {}});

  final Uri camUri;
  final Dio dio;
  final Map<String, String> headers;

  /// Servidores STUN usados pelo pacote oficial.
  static const List<Map<String, dynamic>> _stunServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
    {'urls': 'stun:stun3.l.google.com:19302'},
    {'urls': 'stun:stun4.l.google.com:19302'},
  ];

  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  final StreamController<WebRtcConnectionEvent> _events = StreamController<WebRtcConnectionEvent>.broadcast();

  RTCPeerConnection? _peerConnection;
  bool _disposed = false;

  String? _remoteIceUfrag;
  String? _remoteIcePwd;

  @override
  Stream<WebRtcConnectionEvent> get connectionEvents => _events.stream;

  @override
  RTCVideoRenderer get renderer => _renderer;

  String get _logTag => '[${runtimeType}#${identityHashCode(this)})]';

  /// Estado atual da conexão; ao mudar, emite o evento correspondente.
  set _connectionState(WebRtcConnectionEvent event) {
    talker.info('$_logTag $event');
    if (!_events.isClosed) _events.add(event);
  }

  /// Configuração da PeerConnection (unified-plan + STUNs do Google).
  Map<String, dynamic> _linkToIceServers() => {
        'iceServers': _stunServers,
        'sdpSemantics': 'unified-plan',
      };

  @override
  Future<void> initialize() async {
    if (_disposed) return;
    _connectionState = const WebRtcConnectionEventConnecting();
    try {
      await _loadStream();
      await _setupPeerConnection();
    } catch (error) {
      _connectionState = WebRtcConnectionEventFailed(error);
    }
  }

  /// Inicializa o renderer de vídeo.
  Future<void> _loadStream() async {
    await _renderer.initialize();
  }

  /// Configura a PeerConnection e inicia a sinalização do backend.
  Future<void> _setupPeerConnection();

  // ── Handlers compartilhados ──────────────────────────────────────────────

  void _onTrack(RTCTrackEvent event) {
    talker.info('$_logTag Received RTCTrackEvent');
    if (event.streams.isNotEmpty) {
      _renderer.srcObject = event.streams.first;
      _connectionState = const WebRtcConnectionEventConnected();
    }
  }

  void _onConnectionState(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        _connectionState = const WebRtcConnectionEventConnected();
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        _connectionState = const WebRtcConnectionEventDisconnected();
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        _connectionState = const WebRtcConnectionEventFailed('Peer connection failed');
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        _connectionState = const WebRtcConnectionEventClosed();
      default:
        break;
    }
  }

  void _onSignalingState(RTCSignalingState state) {
    talker.debug('$_logTag signaling state: $state');
  }

  // ── Utilitários WHEP / trickle ICE ───────────────────────────────────────

  /// Aplica a oferta remota e guarda as credenciais ICE (para o trickle).
  Future<void> _parseOffer(RTCSessionDescription offer) async {
    _remoteIceUfrag = _extractIceValue(offer.sdp, 'a=ice-ufrag:');
    _remoteIcePwd = _extractIceValue(offer.sdp, 'a=ice-pwd:');
    await _peerConnection?.setRemoteDescription(offer);
  }

  /// Aplica a resposta remota (fluxo "client offer").
  Future<void> _onRemoteAnswer(RTCSessionDescription answer) async {
    await _peerConnection?.setRemoteDescription(answer);
  }

  /// Endpoint do fluxo "client offer" (usado por camera-streamer).
  Uri get _offerUri => camUri.replace(query: '');

  /// Cria a oferta e envia via POST (fluxo "client offer" — camera-streamer).
  Future<void> _sendOffer() async {
    final pc = _peerConnection;
    if (pc == null) return;
    final offer = await pc.createOffer({});
    await pc.setLocalDescription(offer);
    await _waitForIceGathering(pc);
    final localDescription = await pc.getLocalDescription();
    final response = await dio.postUri<String>(
      _offerUri,
      data: localDescription?.sdp ?? offer.sdp,
      options: Options(
        headers: {...headers, 'Content-Type': 'application/sdp'},
        responseType: ResponseType.plain,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    final answer = response.data;
    if (answer is String && answer.isNotEmpty) {
      await _onRemoteAnswer(RTCSessionDescription(answer, 'answer'));
    }
  }

  /// Envia um candidato local como fragmento SDP (trickle WHEP).
  Future<void> _sendLocalCandidates(String sessionUrl, RTCIceCandidate candidate) async {
    try {
      final fragment = _generateSdpFragment(candidate);
      if (fragment == null) return;
      await dio.patchUri(
        Uri.parse(sessionUrl),
        data: fragment,
        options: Options(headers: {'Content-Type': 'application/trickle-ice-sdpfrag'}),
      );
    } catch (error) {
      talker.error('$_logTag Error sending ICE candidates', error);
    }
  }

  /// Gera o fragmento SDP (trickle) para um candidato local.
  String? _generateSdpFragment(RTCIceCandidate candidate) {
    final ufrag = _remoteIceUfrag;
    final pwd = _remoteIcePwd;
    final sdpMid = candidate.sdpMid;
    final value = candidate.candidate;
    if (ufrag == null || pwd == null || sdpMid == null || value == null) return null;
    final buffer = StringBuffer()
      ..write('a=ice-ufrag:${_unquoteCredential(ufrag)}\r\n')
      ..write('a=ice-pwd:${_unquoteCredential(pwd)}\r\n')
      ..write('m=video 9 UDP/TLS/RTP/SAVPF 96\r\n')
      ..write('a=mid:$sdpMid\r\n')
      ..write('a=$value\r\n');
    return buffer.toString();
  }

  /// Remove as aspas de um valor de credencial ICE.
  String _unquoteCredential(String? value) => (value ?? '').replaceAll('"', '').trim();

  Future<void> _waitForIceGathering(
    RTCPeerConnection pc, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (pc.iceGatheringState == RTCIceGatheringState.RTCIceGatheringStateComplete) return;
    final completer = Completer<void>();
    pc.onIceGatheringState = (state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete && !completer.isCompleted) {
        completer.complete();
      }
    };
    await completer.future.timeout(timeout, onTimeout: () {});
  }

  static String? _extractIceValue(String? sdp, String prefix) {
    if (sdp == null) return null;
    for (final line in sdp.split('\r\n')) {
      if (line.startsWith(prefix)) {
        return line.substring(prefix.length);
      }
    }
    return null;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _peerConnection?.close();
    _peerConnection = null;
    try {
      await _renderer.dispose();
    } catch (_) {
      // renderer já liberado
    }
    await _events.close();
  }
}
