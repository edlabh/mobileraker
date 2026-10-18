/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:dio/dio.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'data/webrtc_connection_event.dart';
import 'webrtc_manager.dart';

/// mediaMTX — WHEP (`POST <path>/whep`, resposta com `Location` da sessão).
class MediaMtxWebRtcManager extends WebRTCManagerBase {
  MediaMtxWebRtcManager({required super.camUri, required super.dio, super.headers});

  String? _sessionUrl;

  Uri get _whepUri {
    final path = camUri.path.endsWith('/whep') ? camUri.path : '${camUri.path}/whep';
    return camUri.replace(path: path, query: '');
  }

  @override
  Future<void> connect(RTCPeerConnection pc) async {
    final offer = await createOffer(pc);
    await waitForIceGathering(pc);
    final response = await dio.postUri<String>(
      _whepUri,
      data: offer.sdp,
      options: Options(
        headers: {...headers, 'Content-Type': 'application/sdp'},
        responseType: ResponseType.plain,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    final location = response.headers.value('location');
    if (location == null || location.isEmpty) {
      // Mensagem equivalente à do pacote oficial:
      emitEvent(const WebRTCConnectionEvent(
        state: WebRTCConnectionState.failed,
        message: 'MediaMTX não retornou o header de localização da sessão',
      ));
      return;
    }
    _sessionUrl = _whepUri.resolve(location).toString();
    final answer = response.data;
    if (answer is String && answer.isNotEmpty) {
      await applyAnswer(RTCSessionDescription(answer, 'answer'));
    }
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
