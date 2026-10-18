/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:async';

import 'package:common/data/enums/webcam_service_type.dart';
import 'package:common/util/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show protected;
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'camerastreamer_manager.dart';
import 'creality_rtc_manager.dart';
import 'data/webrtc_connection_event.dart';
import 'go2rtc_manager.dart';
import 'mediamtx_manager.dart';

/// Gerenciador WebRTC de uma câmera (por tipo de serviço).
abstract class WebRTCManager {
  /// Cria o gerenciador adequado para o tipo de câmera.
  static WebRTCManager forService({
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
  Stream<WebRTCConnectionEvent> get connectionEvents;

  /// Renderer de vídeo (usado pelo `RTCVideoView`).
  RTCVideoRenderer get renderer;

  bool get isInitialized;

  Future<void> initialize();

  Future<void> dispose();
}

/// Base comum dos gerenciadores: PeerConnection, ICE, renderer e eventos.
abstract class WebRTCManagerBase implements WebRTCManager {
  WebRTCManagerBase({required this.camUri, required this.dio, this.headers = const {}});

  final Uri camUri;
  final Dio dio;
  final Map<String, String> headers;

  /// Servidores STUN usados pelo pacote oficial.
  static const List<Map<String, dynamic>> iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
    {'urls': 'stun:stun3.l.google.com:19302'},
    {'urls': 'stun:stun4.l.google.com:19302'},
  ];

  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  final StreamController<WebRTCConnectionEvent> _events = StreamController<WebRTCConnectionEvent>.broadcast();

  RTCPeerConnection? _peerConnection;
  bool _initialized = false;

  @override
  Stream<WebRTCConnectionEvent> get connectionEvents => _events.stream;

  @override
  RTCVideoRenderer get renderer => _renderer;

  @override
  bool get isInitialized => _initialized;

  @protected
  RTCPeerConnection? get peerConnection => _peerConnection;

  @protected
  void emitEvent(WebRTCConnectionEvent event) {
    talker.info('WebRTC[$runtimeType]: $event');
    if (!_events.isClosed) _events.add(event);
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    talker.info('WebRTC[$runtimeType]: inicializando (camUri=$camUri)...');
    emitEvent(const WebRTCConnectionEvent(state: WebRTCConnectionState.connecting));
    try {
      await _renderer.initialize();
      talker.info('WebRTC[$runtimeType]: renderer inicializado');
      final pc = await createPeerConnection({
        'iceServers': iceServers,
        'sdpSemantics': 'unified-plan',
      });
      talker.info('WebRTC[$runtimeType]: peer connection criada');
      _peerConnection = pc;
      pc.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _renderer.srcObject = event.streams.first;
          emitEvent(const WebRTCConnectionEvent(state: WebRTCConnectionState.connected));
        }
      };
      pc.onConnectionState = (RTCPeerConnectionState state) {
        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            emitEvent(const WebRTCConnectionEvent(state: WebRTCConnectionState.connected));
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            emitEvent(const WebRTCConnectionEvent(
              state: WebRTCConnectionState.failed,
              message: 'Falha na conexão WebRTC',
            ));
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            emitEvent(const WebRTCConnectionEvent(
              state: WebRTCConnectionState.disconnected,
              message: 'Conexão WebRTC interrompida',
            ));
          case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
            emitEvent(const WebRTCConnectionEvent(state: WebRTCConnectionState.closed));
          default:
            break;
        }
      };
      pc.onIceCandidate = (RTCIceCandidate? candidate) => onLocalCandidate(candidate);
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      await connect(pc);
    } catch (error) {
      talker.error('WebRTC[$runtimeType]: falha ao iniciar', error);
      emitEvent(WebRTCConnectionEvent(
        state: WebRTCConnectionState.failed,
        message: 'Não foi possível iniciar a câmera WebRTC',
        error: error,
      ));
    }
  }

  /// Implementado por cada backend (sinalização do offer/resposta).
  @protected
  Future<void> connect(RTCPeerConnection pc);

  /// Chamado quando um candidato ICE local é descoberto (trickle).
  @protected
  Future<void> onLocalCandidate(RTCIceCandidate? candidate) async {}

  @protected
  Future<RTCSessionDescription> createOffer(RTCPeerConnection pc) async {
    final offer = await pc.createOffer({'offerToReceiveVideo': true});
    await pc.setLocalDescription(offer);
    return await pc.getLocalDescription() ?? offer;
  }

  @protected
  Future<void> applyAnswer(RTCSessionDescription answer) async {
    await _peerConnection?.setRemoteDescription(answer);
  }

  @protected
  Future<void> addRemoteCandidate(RTCIceCandidate candidate) async {
    await _peerConnection?.addCandidate(candidate);
  }

  /// Espera a coleta de ICE terminar (backends sem trickle, como mediaMTX).
  @protected
  Future<void> waitForIceGathering(RTCPeerConnection pc, {Duration timeout = const Duration(seconds: 3)}) async {
    if (pc.iceGatheringState == RTCIceGatheringState.RTCIceGatheringStateComplete) return;
    final completer = Completer<void>();
    pc.onIceGatheringState = (state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete && !completer.isCompleted) {
        completer.complete();
      }
    };
    await completer.future.timeout(timeout, onTimeout: () {});
  }

  @override
  Future<void> dispose() async {
    await _peerConnection?.close();
    _peerConnection = null;
    _initialized = false;
    try {
      await _renderer.dispose();
    } catch (_) {
      // renderer já liberado
    }
    await _events.close();
  }
}
