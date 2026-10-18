/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:dio/dio.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'webrtc_manager.dart';

/// camera-streamer (dw-0) — WebRTC via `POST /webrtc` com SDP.
class CameraStreamerManager extends WebRTCManagerBase {
  CameraStreamerManager({required super.camUri, required super.dio, super.headers});

  Uri get _webrtcUri {
    final path = (camUri.path.isEmpty || camUri.path == '/') ? '/webrtc' : camUri.path;
    return camUri.replace(path: path, query: '');
  }

  @override
  Future<void> connect(RTCPeerConnection pc) async {
    final offer = await createOffer(pc);
    await waitForIceGathering(pc);
    final response = await dio.postUri<String>(
      _webrtcUri,
      data: offer.sdp,
      options: Options(
        headers: {...headers, 'Content-Type': 'application/sdp'},
        responseType: ResponseType.plain,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    final answer = response.data;
    if (answer is String && answer.isNotEmpty) {
      await applyAnswer(RTCSessionDescription(answer, 'answer'));
    }
  }
}
