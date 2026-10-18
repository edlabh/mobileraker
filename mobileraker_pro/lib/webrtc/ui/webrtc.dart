/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/data/enums/webcam_service_type.dart';
import 'package:common/util/logger.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show listEquals, mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/webrtc_connection_event.dart';
import '../webrtc_manager.dart';

typedef ImageBuilder = Widget Function(BuildContext context, Widget image);

/// Configuração do player WebRTC (chave do controller).
class WebRtcConfig {
  const WebRtcConfig({
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebRtcConfig &&
          runtimeType == other.runtimeType &&
          camUri == other.camUri &&
          identical(dio, other.dio) &&
          service == other.service &&
          mapEquals(headers, other.headers) &&
          rotation == other.rotation &&
          identical(transform, other.transform) &&
          listEquals(stackContent, other.stackContent) &&
          identical(imageBuilder, other.imageBuilder) &&
          identical(onHidePressed, other.onHidePressed);

  @override
  int get hashCode => Object.hash(camUri, service, rotation, transform, imageBuilder, onHidePressed);

  @override
  String toString() => 'WebRtcConfig(camUri: $camUri, service: $service, rotation: $rotation)';
}

class _WebRtcController {
  _WebRtcController(this.config);

  final WebRtcConfig config;

  WebRtcManager? _manager;

  WebRtcManager get manager => _manager ??= WebRtcManager.forService(
        service: config.service,
        camUri: config.camUri,
        dio: config.dio,
        headers: config.headers,
      );

  Stream<WebRtcConnectionEvent> get connectionEvents => manager.connectionEvents;

  Future<void> initialize() => manager.initialize();

  /// Recria o manager do zero (botão "Reconectar").
  Future<void> retry() async {
    talker.info('[WebRtcController] retrying WebRTC connection...');
    await _manager?.dispose();
    _manager = null;
    await initialize();
  }

  Future<void> dispose() async {
    await _manager?.dispose();
    _manager = null;
  }
}

class _WebRtcControllerFamily {
  Provider<_WebRtcController> call(WebRtcConfig config) => _family(config);

  static final _family = Provider.autoDispose.family<_WebRtcController, WebRtcConfig>((ref, config) {
    final controller = _WebRtcController(config);
    ref.onDispose(controller.dispose);
    return controller;
  });
}

final _webRtcControllerProvider = _WebRtcControllerFamily();

/// Player WebRTC do webcam (go2rtc / mediaMTX / camera-streamer / creality).
class WebRtc extends StatelessWidget {
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
  final int rotation;
  final Matrix4? transform;
  final List<Widget> stackContent;
  final ImageBuilder? imageBuilder;
  final VoidCallback? onHidePressed;

  @override
  Widget build(BuildContext context) {
    return _WebRtc(
      config: WebRtcConfig(
        camUri: camUri,
        dio: dio,
        service: service,
        headers: headers,
        rotation: rotation,
        transform: transform,
        stackContent: stackContent,
        imageBuilder: imageBuilder,
        onHidePressed: onHidePressed,
      ),
    );
  }
}

/// Dados de renderização do player (loading / conectado / erro).
sealed class _WebRtcData {
  const _WebRtcData();
}

class _WebRtcLoading extends _WebRtcData {
  const _WebRtcLoading();
}

class _WebRtcConnected extends _WebRtcData {
  const _WebRtcConnected();
}

class _WebRtcError extends _WebRtcData {
  const _WebRtcError(this.error);

  final Object error;
}

class _WebRtc extends HookConsumerWidget {
  const _WebRtc({required this.config});

  final WebRtcConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(_webRtcControllerProvider(config));
    final data = useState<_WebRtcData>(const _WebRtcLoading());

    useEffect(() {
      final subscription = controller.connectionEvents.listen((event) {
        data.value = switch (event) {
          WebRtcConnectionEventConnected() => const _WebRtcConnected(),
          WebRtcConnectionEventNew() || WebRtcConnectionEventConnecting() => const _WebRtcLoading(),
          WebRtcConnectionEventFailed(:final error) => _WebRtcError(error),
          WebRtcConnectionEventDisconnected() => const _WebRtcError('Conexão WebRTC interrompida'),
          WebRtcConnectionEventClosed() => const _WebRtcError('Conexão WebRTC encerrada'),
        };
      });
      controller.initialize();
      return subscription.cancel;
    }, [controller]);

    final content = AspectRatio(
      aspectRatio: _videoAspectRatio(controller.manager),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.black, child: _buildBody(controller, data)),
          ...config.stackContent,
          if (config.onHidePressed != null)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: config.onHidePressed,
                icon: const Icon(Icons.visibility_off_outlined, color: Colors.white),
              ),
            ),
        ],
      ),
    );

    final builder = config.imageBuilder;
    return builder != null ? builder(context, content) : content;
  }

  Widget _buildBody(_WebRtcController controller, ValueNotifier<_WebRtcData> data) {
    return switch (data.value) {
      _WebRtcConnected() => _RtcRenderer(
          renderer: controller.manager.renderer,
          rotation: config.rotation,
          transform: config.transform,
        ),
      _WebRtcError(:final error) => _RtcStateDisplay.error(
          error: error,
          onRetry: () async {
            data.value = const _WebRtcLoading();
            await controller.retry();
          },
        ),
      _WebRtcLoading() => const _RtcStateDisplay.loading(),
    };
  }

  double _videoAspectRatio(WebRtcManager manager) {
    final renderer = manager.renderer;
    final width = renderer.videoWidth;
    final height = renderer.videoHeight;
    if (width > 0 && height > 0) return width / height;
    return 4 / 3;
  }
}

/// Renderer do vídeo (com o aviso quando o renderer não está disponível).
class _RtcRenderer extends StatelessWidget {
  const _RtcRenderer({required this.renderer, this.rotation = 0, this.transform});

  final RTCVideoRenderer renderer;
  final int rotation;
  final Matrix4? transform;

  @override
  Widget build(BuildContext context) {
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
  }
}

/// Aplica rotação (graus) e transformação à imagem do vídeo.
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

/// Estado da conexão (carregando / erro) com o botão de reconectar.
class _RtcStateDisplay extends StatelessWidget {
  const _RtcStateDisplay({required this.icon, this.message, this.error, this.onRetry, this.showSpinner = false});

  const _RtcStateDisplay.loading()
      : this(
          icon: Icons.videocam_outlined,
          message: 'components.connection_watcher.trying_connect',
          showSpinner: true,
        );

  const _RtcStateDisplay.error({required Object error, required VoidCallback onRetry})
      : this(
          icon: Icons.videocam_off_outlined,
          error: error,
          onRetry: onRetry,
        );

  final IconData icon;
  final String? message;
  final Object? error;
  final VoidCallback? onRetry;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final displayText = message != null ? message!.tr() : '$error';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner) const CircularProgressIndicator() else Icon(icon, color: Colors.white70, size: 36),
            const SizedBox(height: 12),
            Text(displayText, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
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
      label: Text('components.connection_watcher.reconnect'.tr()),
    );
  }
}
