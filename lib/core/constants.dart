/// Global tuning-engine constants.
///
/// Pure Dart: this file must not import Flutter so that it can be used from
/// the audio isolate and from fast unit tests.
library;

/// Audio capture sample rate, Hz.
const int kSampleRate = 44100;

/// Analysis window, samples (~93 ms at 44.1 kHz).
const int kBufferSize = 4096;

/// Hop between consecutive analyses, samples (50% overlap, ~21 fps).
const int kHopSize = 2048;

/// Lowest detectable fundamental, Hz (below bass drop tunings).
const double kMinFrequency = 25.0;

/// Highest detectable fundamental, Hz.
const double kMaxFrequency = 1400.0;

/// YIN cumulative-mean-normalized-difference threshold.
const double kYinThreshold = 0.12;

/// Results with confidence below this are treated as "no tone".
const double kMinConfidence = 0.6;

/// Default "in tune" window, cents. User-configurable (1 / 3 / 5).
const double kInTuneCentsDefault = 3.0;

/// Cents gauge range: the needle clamps at +/- this value.
const double kGaugeRangeCents = 50.0;

/// A4 calibration bounds, Hz.
const double kA4Min = 435.0;
const double kA4Max = 445.0;
const double kA4Default = 440.0;
const double kA4Step = 0.5;

/// Exponential smoothing factor for the displayed frequency.
const double kSmoothingAlpha = 0.25;

/// Median filter length over the last valid frequency readings.
const int kMedianWindow = 3;

/// Consecutive in-tune frames required to mark a string as "tuned".
const int kTunedFramesRequired = 8;

/// Metronome bounds.
const int kBpmMin = 30;
const int kBpmMax = 300;

/// RMS noise-gate thresholds by sensitivity (low / medium / high).
/// "High sensitivity" means quieter signals are accepted.
const double kGateRmsLow = 0.020;
const double kGateRmsMedium = 0.008;
const double kGateRmsHigh = 0.003;
