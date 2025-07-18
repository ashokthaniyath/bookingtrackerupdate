import 'dart:async';
import '../config/app_config.dart';
import 'production_error_handler.dart';
import 'production_security_service.dart';
import 'production_performance_service.dart';
import 'production_firebase_service.dart';
import 'production_ai_service.dart';
import 'production_voice_service.dart';
import 'production_calendar_service.dart';

/// Production deployment manager
/// Orchestrates all production services and ensures proper initialization
class ProductionDeploymentManager {
  static bool _isInitialized = false;
  static final List<String> _initializationLog = [];
  static final Map<String, bool> _serviceStatus = {};

  /// Initialize all production services
  static Future<DeploymentResult> initializeProduction() async {
    if (_isInitialized) {
      return DeploymentResult.success(
        'Production services already initialized',
      );
    }

    try {
      _logStep('🚀 Starting production deployment initialization...');

      // Step 1: Initialize error handling first
      await _initializeService('ErrorHandler', () async {
        await ProductionErrorHandler.initialize();
      });

      // Step 2: Initialize security service
      await _initializeService('SecurityService', () async {
        await ProductionSecurityService.initialize();
      });

      // Step 3: Initialize performance monitoring
      await _initializeService('PerformanceService', () async {
        await ProductionPerformanceService.initialize();
      });

      // Step 4: Initialize Firebase service
      await _initializeService('FirebaseService', () async {
        await ProductionFirebaseService.initialize();
      });

      // Step 5: Initialize AI services
      await _initializeService('AIService', () async {
        await ProductionAIService.initialize();
      });

      // Step 6: Initialize voice service
      await _initializeService('VoiceService', () async {
        await ProductionVoiceService.initialize();
      });

      // Step 7: Initialize calendar service
      await _initializeService('CalendarService', () async {
        await ProductionCalendarService.initialize();
      });

      // Step 8: Verify all services are working
      final healthCheck = await _performHealthCheck();
      if (!healthCheck.isHealthy) {
        throw Exception(
          'Health check failed: ${healthCheck.issues.join(', ')}',
        );
      }

      _isInitialized = true;
      _logStep('✅ All production services initialized successfully!');

      return DeploymentResult.success(
        'Production deployment completed successfully',
      );
    } catch (e) {
      _logStep('❌ Production deployment failed: $e');
      ProductionErrorHandler.handleError(
        e,
        context: 'Production deployment initialization failed',
      );

      return DeploymentResult.failure('Production deployment failed: $e');
    }
  }

  /// Get deployment status
  static DeploymentStatus getDeploymentStatus() {
    return DeploymentStatus(
      isInitialized: _isInitialized,
      serviceStatus: Map.from(_serviceStatus),
      initializationLog: List.from(_initializationLog),
      appVersion: AppConfig.version,
      buildNumber: AppConfig.buildNumber,
      isProduction: AppConfig.isProduction,
      timestamp: DateTime.now(),
    );
  }

  /// Perform comprehensive health check
  static Future<HealthCheckResult> performHealthCheck() async {
    try {
      return await _performHealthCheck();
    } catch (e) {
      ProductionErrorHandler.handleError(e, context: 'Health check failed');
      return HealthCheckResult(
        isHealthy: false,
        issues: ['Health check failed: $e'],
        services: {},
      );
    }
  }

  /// Get production readiness report
  static Future<ProductionReadinessReport> getReadinessReport() async {
    try {
      final healthCheck = await _performHealthCheck();
      final performanceStats =
          ProductionPerformanceService.getPerformanceStats();
      final securityReport = ProductionSecurityService.getSecurityReport();
      final performanceRecommendations =
          ProductionPerformanceService.getRecommendations();

      final readinessScore = _calculateReadinessScore(
        healthCheck,
        performanceStats,
        securityReport,
      );

      return ProductionReadinessReport(
        readinessScore: readinessScore,
        isProductionReady: readinessScore >= 85,
        healthCheck: healthCheck,
        performanceStats: performanceStats,
        securityReport: securityReport,
        recommendations: [
          ...performanceRecommendations.map((r) => r.recommendation),
          ...securityReport.recommendations,
        ],
        timestamp: DateTime.now(),
      );
    } catch (e) {
      ProductionErrorHandler.handleError(
        e,
        context: 'Failed to generate readiness report',
      );
      return ProductionReadinessReport.empty();
    }
  }

  /// Shutdown all production services
  static Future<void> shutdown() async {
    try {
      _logStep('🔄 Shutting down production services...');

      // Shutdown services in reverse order
      ProductionCalendarService.dispose();
      ProductionVoiceService.dispose();
      ProductionAIService.dispose();
      ProductionPerformanceService.dispose();

      _serviceStatus.clear();
      _initializationLog.clear();
      _isInitialized = false;

      _logStep('✅ Production services shut down successfully');
    } catch (e) {
      ProductionErrorHandler.handleError(
        e,
        context: 'Failed to shutdown production services',
      );
    }
  }

  /// Restart all production services
  static Future<DeploymentResult> restart() async {
    try {
      _logStep('🔄 Restarting production services...');

      await shutdown();
      await Future.delayed(Duration(seconds: 2));

      return await initializeProduction();
    } catch (e) {
      ProductionErrorHandler.handleError(
        e,
        context: 'Failed to restart production services',
      );
      return DeploymentResult.failure('Restart failed: $e');
    }
  }

  // Private methods
  static Future<void> _initializeService(
    String serviceName,
    Future<void> Function() initializer,
  ) async {
    try {
      _logStep('🔧 Initializing $serviceName...');

      await initializer();

      _serviceStatus[serviceName] = true;
      _logStep('✅ $serviceName initialized successfully');
    } catch (e) {
      _serviceStatus[serviceName] = false;
      _logStep('❌ Failed to initialize $serviceName: $e');
      throw Exception('Failed to initialize $serviceName: $e');
    }
  }

  static Future<HealthCheckResult> _performHealthCheck() async {
    final issues = <String>[];
    final services = <String, bool>{};

    // Check configuration
    if (!AppConfig.isProduction) {
      issues.add('App is not in production mode');
    }

    if (!AppConfig.useFirebase) {
      issues.add('Firebase is not enabled');
    }

    // Check service status
    for (final entry in _serviceStatus.entries) {
      services[entry.key] = entry.value;
      if (!entry.value) {
        issues.add('${entry.key} is not healthy');
      }
    }

    // Check API keys
    if (AppConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      issues.add('Gemini API key is not configured');
    }

    if (AppConfig.firebaseApiKey == 'YOUR_API_KEY_HERE') {
      issues.add('Firebase API key is not configured');
    }

    // Check required services
    final requiredServices = [
      'ErrorHandler',
      'SecurityService',
      'PerformanceService',
      'FirebaseService',
      'AIService',
      'VoiceService',
      'CalendarService',
    ];

    for (final service in requiredServices) {
      if (!_serviceStatus.containsKey(service) || !_serviceStatus[service]!) {
        issues.add('Required service $service is not available');
      }
    }

    return HealthCheckResult(
      isHealthy: issues.isEmpty,
      issues: issues,
      services: services,
    );
  }

  static int _calculateReadinessScore(
    HealthCheckResult healthCheck,
    PerformanceStats performanceStats,
    SecurityReport securityReport,
  ) {
    int score = 0;

    // Health check contributes 40%
    if (healthCheck.isHealthy) {
      score += 40;
    } else {
      score += (40 * (1 - healthCheck.issues.length / 10)).round().clamp(0, 40);
    }

    // Performance contributes 30%
    if (performanceStats.averageResponseTime < 500) {
      score += 30;
    } else if (performanceStats.averageResponseTime < 1000) {
      score += 20;
    } else if (performanceStats.averageResponseTime < 2000) {
      score += 10;
    }

    // Security contributes 30%
    if (securityReport.totalEvents < 10) {
      score += 30;
    } else if (securityReport.totalEvents < 50) {
      score += 20;
    } else if (securityReport.totalEvents < 100) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  static void _logStep(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $message';
    _initializationLog.add(logEntry);
    print(logEntry);
  }
}

/// Deployment result model
class DeploymentResult {
  final bool isSuccess;
  final String message;
  final DateTime timestamp;

  DeploymentResult({
    required this.isSuccess,
    required this.message,
    required this.timestamp,
  });

  static DeploymentResult success(String message) {
    return DeploymentResult(
      isSuccess: true,
      message: message,
      timestamp: DateTime.now(),
    );
  }

  static DeploymentResult failure(String message) {
    return DeploymentResult(
      isSuccess: false,
      message: message,
      timestamp: DateTime.now(),
    );
  }
}

/// Deployment status model
class DeploymentStatus {
  final bool isInitialized;
  final Map<String, bool> serviceStatus;
  final List<String> initializationLog;
  final String appVersion;
  final String buildNumber;
  final bool isProduction;
  final DateTime timestamp;

  DeploymentStatus({
    required this.isInitialized,
    required this.serviceStatus,
    required this.initializationLog,
    required this.appVersion,
    required this.buildNumber,
    required this.isProduction,
    required this.timestamp,
  });
}

/// Health check result model
class HealthCheckResult {
  final bool isHealthy;
  final List<String> issues;
  final Map<String, bool> services;

  HealthCheckResult({
    required this.isHealthy,
    required this.issues,
    required this.services,
  });
}

/// Production readiness report model
class ProductionReadinessReport {
  final int readinessScore;
  final bool isProductionReady;
  final HealthCheckResult healthCheck;
  final PerformanceStats performanceStats;
  final SecurityReport securityReport;
  final List<String> recommendations;
  final DateTime timestamp;

  ProductionReadinessReport({
    required this.readinessScore,
    required this.isProductionReady,
    required this.healthCheck,
    required this.performanceStats,
    required this.securityReport,
    required this.recommendations,
    required this.timestamp,
  });

  static ProductionReadinessReport empty() {
    return ProductionReadinessReport(
      readinessScore: 0,
      isProductionReady: false,
      healthCheck: HealthCheckResult(
        isHealthy: false,
        issues: [],
        services: {},
      ),
      performanceStats: PerformanceStats.empty(),
      securityReport: SecurityReport(
        totalEvents: 0,
        threatCounts: {},
        lastUpdated: DateTime.now(),
        recommendations: [],
      ),
      recommendations: [],
      timestamp: DateTime.now(),
    );
  }
}
