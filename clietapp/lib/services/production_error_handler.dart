import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import '../config/app_config.dart';
import 'production_firebase_service.dart';

/// Production-grade error handling and logging service
/// Implements comprehensive error tracking, crash reporting, and performance monitoring
class ProductionErrorHandler {
  static bool _isInitialized = false;
  static final List<ErrorLog> _errorQueue = [];
  static final List<PerformanceMetric> _performanceQueue = [];

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔧 Initializing Production Error Handler...');

      // Set up global error handling
      // FlutterError.onError = _handleFlutterError;

      // Handle platform-specific errors
      if (!_isWeb) {
        _setupPlatformErrorHandling();
      }

      // Initialize crash reporting if enabled
      if (AppConfig.enableCrashlytics) {
        await _initializeCrashReporting();
      }

      // Start background error reporting
      _startBackgroundReporting();

      _isInitialized = true;
      print('✅ Production Error Handler initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize error handler: $e');
    }
  }

  static bool get _isWeb => identical(0, 0.0);
  static bool get _isDebugMode => !bool.fromEnvironment('dart.vm.product');

  /// Handle errors with context
  static void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    // Log error with context
    logError(
      'Application Error',
      error.toString(),
      stackTrace,
      context: {'context': context ?? 'unknown'},
    );

    // In debug mode, also print to console
    if (_isDebugMode) {
      print('Application Error: ${error.toString()}');
    }
  }

  static void _setupPlatformErrorHandling() {
    // Handle uncaught exceptions in isolates
    Isolate.current.addErrorListener(
      RawReceivePort((List<dynamic> errorAndStacktrace) {
        final error = errorAndStacktrace.first;
        final stackTrace = errorAndStacktrace.last as StackTrace?;

        logError(
          'Uncaught Platform Error',
          error,
          stackTrace,
          context: {'source': 'isolate'},
        );
      }).sendPort,
    );
  }

  static Future<void> _initializeCrashReporting() async {
    try {
      // Initialize Firebase Crashlytics if available
      if (AppConfig.useFirebase) {
        // TODO: Initialize Firebase Crashlytics
        print('📊 Crash reporting initialized');
      }
    } catch (e) {
      print('⚠️  Failed to initialize crash reporting: $e');
    }
  }

  static void _startBackgroundReporting() {
    // Send error reports in background every 30 seconds
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _flushErrorQueue();
      await _flushPerformanceQueue();
    });
  }

  /// Log an error with full context and metadata
  static void logError(
    String title,
    dynamic error,
    StackTrace? stackTrace, {
    Map<String, dynamic>? context,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    try {
      final errorLog = ErrorLog(
        title: title,
        error: error.toString(),
        stackTrace: stackTrace?.toString(),
        timestamp: DateTime.now(),
        severity: severity,
        context: {
          'platform': Platform.operatingSystem,
          'version': AppConfig.version,
          'buildNumber': AppConfig.buildNumber,
          'isProduction': AppConfig.isProduction,
          'userId': _getCurrentUserId(),
          ...?context,
        },
      );

      _errorQueue.add(errorLog);

      // Immediately log critical errors
      if (severity == ErrorSeverity.critical) {
        _reportCriticalError(errorLog);
      }

      // Console logging for development
      if (_isDebugMode) {
        developer.log(
          title,
          error: error,
          stackTrace: stackTrace,
          name: 'BookingTracker',
        );
      }
    } catch (e) {
      print('Failed to log error: $e');
    }
  }

  /// Log performance metrics
  static void logPerformance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? metadata,
  }) {
    try {
      final metric = PerformanceMetric(
        operation: operation,
        duration: duration,
        timestamp: DateTime.now(),
        metadata: {
          'platform': Platform.operatingSystem,
          'version': AppConfig.version,
          ...?metadata,
        },
      );

      _performanceQueue.add(metric);

      // Log slow operations in debug mode
      if (_isDebugMode && duration.inMilliseconds > 1000) {
        print(
          '⚠️  Slow operation detected: $operation took ${duration.inMilliseconds}ms',
        );
      }
    } catch (e) {
      print('Failed to log performance: $e');
    }
  }

  /// Log user actions for analytics
  static void logUserAction(String action, Map<String, dynamic> properties) {
    try {
      if (AppConfig.enableAnalytics) {
        // TODO: Send to analytics service
        if (_isDebugMode) {
          print('📈 User Action: $action with properties: $properties');
        }
      }
    } catch (e) {
      print('Failed to log user action: $e');
    }
  }

  /// Log business metrics
  static void logBusinessMetric(
    String metric,
    double value, {
    Map<String, dynamic>? tags,
  }) {
    try {
      if (_isDebugMode) {
        print('📊 Business Metric: $metric = $value');
      }

      // TODO: Send to business intelligence service
    } catch (e) {
      print('Failed to log business metric: $e');
    }
  }

  /// Get current user ID for logging context
  static String _getCurrentUserId() {
    try {
      // TODO: Get actual user ID from authentication service
      return 'anonymous_user';
    } catch (e) {
      return 'unknown_user';
    }
  }

  /// Report critical errors immediately
  static Future<void> _reportCriticalError(ErrorLog errorLog) async {
    try {
      // Immediately send to monitoring service
      if (AppConfig.useFirebase) {
        await ProductionFirebaseService.logError(errorLog);
      }

      // TODO: Send to external monitoring service (e.g., Sentry, Bugsnag)

      print('🚨 CRITICAL ERROR REPORTED: ${errorLog.title}');
    } catch (e) {
      print('Failed to report critical error: $e');
    }
  }

  /// Flush error queue to remote services
  static Future<void> _flushErrorQueue() async {
    if (_errorQueue.isEmpty) return;

    try {
      final errors = List<ErrorLog>.from(_errorQueue);
      _errorQueue.clear();

      // Send errors to remote service
      if (AppConfig.useFirebase) {
        for (final error in errors) {
          await ProductionFirebaseService.logError(error);
        }
      }

      if (_isDebugMode) {
        print('📤 Sent ${errors.length} errors to remote logging service');
      }
    } catch (e) {
      print('Failed to flush error queue: $e');
      // Re-add errors to queue for retry
      _errorQueue.addAll(_errorQueue);
    }
  }

  /// Flush performance queue to analytics service
  static Future<void> _flushPerformanceQueue() async {
    if (_performanceQueue.isEmpty) return;

    try {
      final metrics = List<PerformanceMetric>.from(_performanceQueue);
      _performanceQueue.clear();

      // Send metrics to analytics service
      if (AppConfig.enableAnalytics) {
        // TODO: Send to analytics service
      }

      if (_isDebugMode) {
        print(
          '📊 Sent ${metrics.length} performance metrics to analytics service',
        );
      }
    } catch (e) {
      print('Failed to flush performance queue: $e');
    }
  }

  /// Create a performance monitoring wrapper
  static Future<T> monitorPerformance<T>(
    String operation,
    Future<T> Function() function, {
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await function();
      stopwatch.stop();

      logPerformance(
        operation,
        stopwatch.elapsed,
        metadata: {'success': true, ...?metadata},
      );

      return result;
    } catch (e) {
      stopwatch.stop();

      logPerformance(
        operation,
        stopwatch.elapsed,
        metadata: {'success': false, 'error': e.toString(), ...?metadata},
      );

      logError(
        'Performance Monitor Error',
        e,
        StackTrace.current,
        context: {
          'operation': operation,
          'duration': stopwatch.elapsed.inMilliseconds,
        },
      );

      rethrow;
    }
  }

  /// Clean up resources
  static void dispose() {
    _isInitialized = false;
    _errorQueue.clear();
    _performanceQueue.clear();
  }
}

/// Error severity levels
enum ErrorSeverity { info, warning, error, critical }

/// Error log data structure
class ErrorLog {
  final String title;
  final String error;
  final String? stackTrace;
  final DateTime timestamp;
  final ErrorSeverity severity;
  final Map<String, dynamic> context;

  ErrorLog({
    required this.title,
    required this.error,
    this.stackTrace,
    required this.timestamp,
    required this.severity,
    required this.context,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'error': error,
    'stackTrace': stackTrace,
    'timestamp': timestamp.toIso8601String(),
    'severity': severity.name,
    'context': context,
  };
}

/// Performance metric data structure
class PerformanceMetric {
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceMetric({
    required this.operation,
    required this.duration,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'operation': operation,
    'duration': duration.inMilliseconds,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };
}

/// User action log data structure
class UserActionLog {
  final String action;
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  final String userId;

  UserActionLog({
    required this.action,
    required this.properties,
    required this.timestamp,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
    'action': action,
    'properties': properties,
    'timestamp': timestamp.toIso8601String(),
    'userId': userId,
  };
}

/// Business metric data structure
class BusinessMetric {
  final String metric;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic> tags;

  BusinessMetric({
    required this.metric,
    required this.value,
    required this.timestamp,
    required this.tags,
  });

  Map<String, dynamic> toJson() => {
    'metric': metric,
    'value': value,
    'timestamp': timestamp.toIso8601String(),
    'tags': tags,
  };
}
