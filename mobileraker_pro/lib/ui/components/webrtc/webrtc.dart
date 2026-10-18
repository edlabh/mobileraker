/*
 * Copyright (c) 2023-2026. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/data/enums/webcam_service_type.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

typedef ImageBuilder = Widget Function(BuildContext context, Widget image);

/// Player WebRTC do webcam.
///
/// Stub local: exibe um placeholder — os serviços de WebRTC do pacote PRO
/// não estão disponíveis neste build.
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
    return ColoredBox(
      color: Colors.black26,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.videocam_off, color: Colors.white70, size: 36),
            SizedBox(height: 8),
            Text(
              'WebRTC indisponível neste build local (pro)',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
