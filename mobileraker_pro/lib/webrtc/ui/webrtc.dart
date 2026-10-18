/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/data/enums/webcam_service_type.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../data/webrtc_connection_event.dart';
import '../webrtc_manager.dart';

typedef ImageBuilder = Widget Function(BuildContext context, Widget image);

/// Player WebRTC do webcam (go2rtc / mediaMTX / camera-streamer).
class WebRtc extends HookWidget {
  const WebRtc({
    super.key,
    required this.camUri,
    required this.dio,
    required this.service,
    this.headers = const {},
    this.rotation = 0,
    this.transform,
    this.stackContent = const [],
    this.imageBuilder,
    this.onHidePressed,
  });

  final Uri camUri;
  final Dio dio;
  final WebcamServiceType service;
  final Map<String, String> headers;

  /// Rotação em graus (0/90/180/270), como no widget MJPEG.
  final int rotation;
  final Matrix4? transform;
  final List<Widget> stackContent;
  final ImageBuilder? imageBuilder;
  final VoidCallback? onHidePressed;

  @override
  Widget build(BuildContext context) {
    final attempt = useState(0);
    final manager = useMemoized(
      () => WebRTCManager.forService(service: service, camUri: camUri, dio: dio, headers: headers),
      [camUri, service, attempt.value],
    );
    final event = useState(const WebRTCConnectionEvent(state: WebRTCConnectionState.connecting));

    useEffect(() {
      final subscription = manager.connectionEvents.listen((value) => event.value = value);
      () async {
        try {
          await manager.initialize();
        } catch (_) {
          // falhas são reportadas pelos connectionEvents
        }
      }();
      return () {
        subscription.cancel();
        manager.dispose();
      };
    }, [manager]);

    final content = AspectRatio(
      aspectRatio: _videoAspectRatio(manager),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.black, child: _buildVideo(manager, event.value, attempt)),
          ...stackContent,
          if (onHidePressed != null)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: onHidePressed,
                icon: const Icon(Icons.visibility_off_outlined, color: Colors.white),
              ),
            ),
        ],
      ),
    );

    final builder = imageBuilder;
    return builder != null ? builder(context, content) : content;
  }

  double _videoAspectRatio(WebRTCManager manager) {
    final renderer = manager.renderer;
    final width = renderer.videoWidth;
    final height = renderer.videoHeight;
    if (width > 0 && height > 0) return width / height;
    return 4 / 3;
  }

  Widget _buildVideo(WebRTCManager manager, WebRTCConnectionEvent event, ValueNotifier<int> attempt) {
    switch (event.state) {
      case WebRTCConnectionState.connected:
        final renderer = manager.renderer;
        if (renderer.textureId == null) {
          return Center(
            child: Text(
              'components.web_rtc.renderer_missing'.tr(),
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          );
        }
        return _TransformedVideo(
          rotation: rotation,
          transform: transform,
          child: RTCVideoView(
            renderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        );
      case WebRTCConnectionState.failed:
      case WebRTCConnectionState.disconnected:
      case WebRTCConnectionState.closed:
        return _RtcStateDisplay(
          icon: Icons.videocam_off_outlined,
          message: event.message ?? 'WebRTC: falha na conexão',
          error: event.error,
          onRetry: () => attempt.value++,
        );
      case WebRTCConnectionState.connecting:
        return const Center(child: CircularProgressIndicator());
    }
  }
}

class _TransformedVideo extends StatelessWidget {
  const _TransformedVideo({required this.rotation, this.transform, required this.child});

  final int rotation;
  final Matrix4? transform;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget result = child;
    final matrix = transform;
    if (matrix != null) {
      result = Transform(transform: matrix, child: result);
    }
    final quarterTurns = (rotation ~/ 90) % 4;
    if (quarterTurns != 0) {
      result = RotatedBox(quarterTurns: quarterTurns, child: result);
    }
    return result;
  }
}

class _RtcStateDisplay extends StatelessWidget {
  const _RtcStateDisplay({required this.icon, required this.message, this.error, this.onRetry});

  final IconData icon;
  final String message;
  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 36),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              _ReconnectButton(onPressed: onRetry!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReconnectButton extends StatelessWidget {
  const _ReconnectButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: const Icon(Icons.refresh),
      label: Text('general.reconnect'.tr()),
    );
  }
}
