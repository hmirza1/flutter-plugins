library noise_meter;

import 'dart:core';
import 'dart:math';

import 'package:audio_streamer/audio_streamer.dart';

// Implements the proper methods outlined in https://github.com/cph-cachet/flutter-plugins/issues/559 by mcourteaux

/// Holds a decibel value for a noise level reading using proper RMS calculation.
class NoiseReading {
  late double _rmsDecibel;
  late double _peakDecibel;

  // Reference pressure level (20 µPa)
  static const double _referenceLevel = 20e-6;

  NoiseReading(List<double> waveform) {
    _calculateLevels(waveform);
  }

  void _calculateLevels(List<double> waveform) {
    // Calculate RMS (Root Mean Square)
    double sumSquares = 0.0;
    double peakAmplitude = 0.0;

    for (var sample in waveform) {
      sumSquares += sample * sample;
      // Track peak amplitude for peak level calculation
      double absValue = sample.abs();
      if (absValue > peakAmplitude) {
        peakAmplitude = absValue;
      }
    }

    // Calculate RMS value
    double rms = sqrt(sumSquares / waveform.length);

    // Convert to decibels using the standard formula: dB = 20 * log10(p/p0)
    // where p is the measured pressure (RMS) and p0 is the reference pressure (20 µPa)
    _rmsDecibel = 20 * log(rms / _referenceLevel) / ln10;
    _peakDecibel = 20 * log(peakAmplitude / _referenceLevel) / ln10;
  }

  /// RMS (Root Mean Square) decibel level - this is the standard measure
  /// for continuous sounds
  double get rmsDecibel => _rmsDecibel;

  /// Peak decibel level - useful for impulsive sounds
  double get peakDecibel => _peakDecibel;

  /// Returns non-negative decibel values, setting any negative values to 0
  /// This can be useful for display purposes where negative values aren't meaningful
  double get normalizedRmsDecibel => max(0, _rmsDecibel);

  @override
  String toString() =>
      '$runtimeType - RMS (dB): $rmsDecibel, Peak (dB): $peakDecibel';
}

/// A [NoiseMeter] provides continuous access to noise reading via the [noise]
/// stream.
class NoiseMeter {
  Stream<NoiseReading>? _stream;

  /// Create a [NoiseMeter].
  NoiseMeter();

  /// The actual sampling rate.
  Future<int> get sampleRate => AudioStreamer().actualSampleRate;

  /// The stream of noise readings.
  ///
  /// Remember to obtain permission to use the microphone **BEFORE**
  /// using this stream.
  Stream<NoiseReading> get noise => _stream ??=
      AudioStreamer().audioStream.map((buffer) => NoiseReading(buffer));
}
