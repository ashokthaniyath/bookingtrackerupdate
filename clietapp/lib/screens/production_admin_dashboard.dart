import 'package:flutter/material.dart';
import '../services/production_deployment_manager.dart';
import '../services/production_error_handler.dart';
import '../config/app_config.dart';

/// Production Admin Dashboard
/// Shows deployment status, health checks, performance metrics, and security reports
class ProductionAdminDashboard extends StatefulWidget {
  const ProductionAdminDashboard({super.key});

  @override
  State<ProductionAdminDashboard> createState() =>
      _ProductionAdminDashboardState();
}

class _ProductionAdminDashboardState extends State<ProductionAdminDashboard> {
  DeploymentStatus? _deploymentStatus;
  ProductionReadinessReport? _readinessReport;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final deploymentStatus =
          ProductionDeploymentManager.getDeploymentStatus();
      final readinessReport =
          await ProductionDeploymentManager.getReadinessReport();

      setState(() {
        _deploymentStatus = deploymentStatus;
        _readinessReport = readinessReport;
        _isLoading = false;
      });
    } catch (e) {
      ProductionErrorHandler.handleError(
        e,
        context: 'Failed to load dashboard data',
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Production Admin Dashboard'),
        backgroundColor: AppConfig.isProduction ? Colors.green : Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildReadinessCard(),
                  const SizedBox(height: 16),
                  _buildServicesCard(),
                  const SizedBox(height: 16),
                  _buildConfigurationCard(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    if (_deploymentStatus == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _deploymentStatus!.isInitialized
                      ? Icons.check_circle
                      : Icons.warning,
                  color: _deploymentStatus!.isInitialized
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Deployment Status',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusRow('Initialized', _deploymentStatus!.isInitialized),
            _buildStatusRow('Production Mode', _deploymentStatus!.isProduction),
            const SizedBox(height: 8),
            Text(
              'App Version: ${_deploymentStatus!.appVersion} (${_deploymentStatus!.buildNumber})',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Last Updated: ${_deploymentStatus!.timestamp.toLocal().toString().split('.').first}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadinessCard() {
    if (_readinessReport == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _readinessReport!.isProductionReady
                      ? Icons.verified
                      : Icons.warning_amber,
                  color: _readinessReport!.isProductionReady
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Production Readiness',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _readinessReport!.readinessScore / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _readinessReport!.readinessScore >= 85
                    ? Colors.green
                    : _readinessReport!.readinessScore >= 70
                    ? Colors.orange
                    : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Readiness Score: ${_readinessReport!.readinessScore}/100',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (_readinessReport!.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recommendations:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...(_readinessReport!.recommendations
                  .take(3)
                  .map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rec,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServicesCard() {
    if (_deploymentStatus == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Services Status',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...(_deploymentStatus!.serviceStatus.entries.map(
              (entry) => _buildStatusRow(entry.key, entry.value),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildConfigRow('Firebase', AppConfig.useFirebase),
            _buildConfigRow('Real APIs', AppConfig.useRealAPIs),
            _buildConfigRow('Analytics', AppConfig.enableAnalytics),
            _buildConfigRow('Crashlytics', AppConfig.enableCrashlytics),
            _buildConfigRow('Voice AI', AppConfig.enableVoiceAI),
            _buildConfigRow('Calendar AI', AppConfig.enableCalendarAI),
            _buildConfigRow('Encryption', AppConfig.enableEncryption),
            _buildConfigRow(
              'Real-time Updates',
              AppConfig.enableRealTimeUpdates,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _performHealthCheck,
                icon: const Icon(Icons.health_and_safety),
                label: const Text('Health Check'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _restartServices,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Restart Services'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showInitializationLog,
            icon: const Icon(Icons.list),
            label: const Text('View Initialization Log'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.error,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Switch(
            value: value,
            onChanged: null, // Read-only
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Future<void> _performHealthCheck() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Performing health check...'),
            ],
          ),
        ),
      );

      final healthCheck =
          await ProductionDeploymentManager.performHealthCheck();

      if (mounted) {
        Navigator.of(context).pop();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  healthCheck.isHealthy ? Icons.check_circle : Icons.warning,
                  color: healthCheck.isHealthy ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                const Text('Health Check Result'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  healthCheck.isHealthy
                      ? 'All systems are healthy!'
                      : 'Some issues detected:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (healthCheck.issues.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...healthCheck.issues.map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(issue)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Health check failed: $e')));
      }
    }
  }

  Future<void> _restartServices() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Restarting services...'),
            ],
          ),
        ),
      );

      final result = await ProductionDeploymentManager.restart();

      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.isSuccess ? Colors.green : Colors.red,
          ),
        );

        if (result.isSuccess) {
          _loadDashboardData();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Restart failed: $e')));
      }
    }
  }

  void _showInitializationLog() {
    if (_deploymentStatus == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Initialization Log'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _deploymentStatus!.initializationLog.length,
            itemBuilder: (context, index) {
              final logEntry = _deploymentStatus!.initializationLog[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  logEntry,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
