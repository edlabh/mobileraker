/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'data/webrtc_connection_event.dart';
import 'webrtc_manager.dart';

/// Câmeras WebRTC proprietárias da Creality.
///
/// O protocolo de sinalização da Creality não é reproduzido neste build local
/// (reconstrução a partir do pacote oficial); o gerenciador emite um evento de
/// falha com mensagem clara em vez de tentar uma conexão inválida.
class CrealityRtcManager extends WebRTCManagerBase {
  CrealityRtcManager({required super.camUri, required super.dio, super.headers});

  @override
  Future<void> connect(RTCPeerConnection pc) async {
    emitEvent(const WebRTCConnectionEvent(
      state: WebRTCConnectionState.failed,
      message: 'Câmeras WebRTC da Creality não são suportadas neste build local',
    ));
  }
}
