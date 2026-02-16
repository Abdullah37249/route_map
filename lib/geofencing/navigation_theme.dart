// lib/geofancing/navigation_theme.dart
import 'package:flutter/material.dart';

class NavigationTheme {
  // Color Scheme
  static const Color primaryColor = Color(0xFF6D28D9);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color secondaryColor = Color(0xFF8B5CF6);
  static const Color onRouteColor = Color(0xFF10B981);
  static const Color offRouteColor = Color(0xFFF59E0B);
  static const Color stoppedColor = Color(0xFF64748B);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF97316);

  // Gradient Presets
  static Gradient get primaryGradient => LinearGradient(
    colors: [primaryDark, primaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Gradient get onRouteGradient => LinearGradient(
    colors: [Color(0xFF059669), onRouteColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Gradient get offRouteGradient => LinearGradient(
    colors: [Color(0xFFD97706), offRouteColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Gradient get stoppedGradient => LinearGradient(
    colors: [Color(0xFF475569), stoppedColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static TextStyle get titleLarge => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get titleMedium => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static TextStyle get buttonText => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  // Box Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: primaryColor.withOpacity(0.3),
      blurRadius: 15,
      offset: Offset(0, 4),
    ),
  ];

  // Border Radius
  static BorderRadius get borderRadiusLarge => BorderRadius.circular(20);
  static BorderRadius get borderRadiusMedium => BorderRadius.circular(14);
  static BorderRadius get borderRadiusSmall => BorderRadius.circular(10);

  // Glassmorphism Effect
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: Colors.white.withOpacity(0.85),
    borderRadius: borderRadiusMedium,
    border: Border.all(color: Colors.white.withOpacity(0.3)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: Offset(0, 4),
      ),
    ],
  );
}

class RouteDurationTracker {
  Duration _totalOnRouteDuration = Duration.zero;
  Duration _totalOffRouteDuration = Duration.zero;
  DateTime? _lastStatusChangeTime;
  bool _lastOnRouteStatus = false;

  // Getter methods
  Duration get totalOnRouteDuration => _totalOnRouteDuration;
  Duration get totalOffRouteDuration => _totalOffRouteDuration;

  String get formattedOnRouteDuration {
    return _formatDuration(_totalOnRouteDuration);
  }

  String get formattedOffRouteDuration {
    return _formatDuration(_totalOffRouteDuration);
  }

  String get formattedTotalDuration {
    return _formatDuration(_totalOnRouteDuration + _totalOffRouteDuration);
  }

  // Update duration tracking
  void updateStatus(bool isOnRoute) {
    final now = DateTime.now();

    if (_lastStatusChangeTime != null) {
      final duration = now.difference(_lastStatusChangeTime!);

      if (_lastOnRouteStatus) {
        _totalOnRouteDuration += duration;
      } else {
        _totalOffRouteDuration += duration;
      }
    }

    _lastOnRouteStatus = isOnRoute;
    _lastStatusChangeTime = now;
  }

  // Reset all durations
  void reset() {
    _totalOnRouteDuration = Duration.zero;
    _totalOffRouteDuration = Duration.zero;
    _lastStatusChangeTime = null;
    _lastOnRouteStatus = false;
  }

  // Start tracking (call when navigation starts)
  void startTracking(bool initialStatus) {
    _lastStatusChangeTime = DateTime.now();
    _lastOnRouteStatus = initialStatus;
  }

  // Stop tracking (call when navigation stops)
  void stopTracking() {
    updateStatus(_lastOnRouteStatus);
  }

  // Get current status percentages
  double get onRoutePercentage {
    final total = _totalOnRouteDuration + _totalOffRouteDuration;
    if (total.inSeconds == 0) return 0.0;
    return _totalOnRouteDuration.inSeconds / total.inSeconds;
  }

  double get offRoutePercentage {
    return 1.0 - onRoutePercentage;
  }

  // Format duration to string
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Get statistics map
  Map<String, dynamic> getStatistics() {
    return {
      'on_route_duration': _totalOnRouteDuration.inSeconds,
      'off_route_duration': _totalOffRouteDuration.inSeconds,
      'total_duration': (_totalOnRouteDuration + _totalOffRouteDuration).inSeconds,
      'on_route_percentage': onRoutePercentage,
      'off_route_percentage': offRoutePercentage,
      'formatted_on_route': formattedOnRouteDuration,
      'formatted_off_route': formattedOffRouteDuration,
      'formatted_total': formattedTotalDuration,
    };
  }
}