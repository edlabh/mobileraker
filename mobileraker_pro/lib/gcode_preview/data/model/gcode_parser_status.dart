/*
 * Copyright (c) 2024-2026. Patrick Schmidt.
 * All rights reserved.
 */

/// Fase da análise do G-code.
enum GCodeParserPhase { idle, downloading, parsing, done, error }

/// Estado da análise do G-code (progresso para a UI).
class GCodeParserStatus {
  const GCodeParserStatus({required this.phase, required this.progress});

  final GCodeParserPhase phase;

  /// Progresso entre 0 e 1.
  final double progress;
}
