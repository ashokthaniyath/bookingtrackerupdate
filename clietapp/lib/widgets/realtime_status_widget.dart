import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/resort_data_provider.dart';
import '../utils/realtime_sync_service.dart';

class RealtimeStatusWidget extends StatefulWidget {
  const RealtimeStatusWidget({super.key});

  @override
  State<RealtimeStatusWidget> createState() => _RealtimeStatusWidgetState();
}

class _RealtimeStatusWidgetState extends State<RealtimeStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final List<RealtimeEvent> _recentEvents = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Listen to real-time events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ResortDataProvider>();
      provider.realtimeService.eventStream.listen((event) {
        if (mounted) {
          setState(() {
            _recentEvents.insert(0, event);
            // Keep only recent 10 events
            if (_recentEvents.length > 10) {
              _recentEvents.removeLast();
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ResortDataProvider>(
      builder: (context, provider, child) {
        final connectionStatus = provider.realtimeService.connectionStatus;
        final isConnected = connectionStatus == ConnectionStatus.connected;

        // Start/stop pulse animation based on connection
        if (isConnected && !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        } else if (!isConnected) {
          _pulseController.stop();
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: isConnected ? _pulseAnimation.value : 1.0,
                          child: Icon(
                            _getConnectionIcon(connectionStatus),
                            color: _getConnectionColor(connectionStatus),
                            size: 20,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Real-time Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (isConnected)
                      IconButton(
                        icon: const Icon(Icons.sync, size: 18),
                        onPressed: () => provider.manualSync(),
                        tooltip: 'Manual Sync',
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getConnectionColor(connectionStatus),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getConnectionText(connectionStatus),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                if (_recentEvents.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: ListView.builder(
                      itemCount: _recentEvents.length,
                      itemBuilder: (context, index) {
                        final event = _recentEvents[index];
                        return _buildEventTile(context, event);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventTile(BuildContext context, RealtimeEvent event) {
    final icon = _getEventIcon(event.type);
    final title = _getEventTitle(event);
    final subtitle = _getEventSubtitle(event);
    final timeAgo = _getTimeAgo(event.timestamp);

    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            )
          : null,
      trailing: Text(
        timeAgo,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }

  IconData _getConnectionIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Icons.cloud_done;
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
        return Icons.cloud_sync;
      case ConnectionStatus.disconnected:
        return Icons.cloud_off;
      case ConnectionStatus.error:
        return Icons.error;
    }
  }

  Color _getConnectionColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
        return Colors.orange;
      case ConnectionStatus.disconnected:
        return Colors.grey;
      case ConnectionStatus.error:
        return Colors.red;
    }
  }

  String _getConnectionText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connected - Live updates active';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting...';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.error:
        return 'Connection error';
    }
  }

  IconData _getEventIcon(RealtimeEventType type) {
    switch (type) {
      case RealtimeEventType.bookingAdded:
      case RealtimeEventType.bookingUpdated:
        return Icons.event_note;
      case RealtimeEventType.bookingDeleted:
        return Icons.event_busy;
      case RealtimeEventType.roomStatusChanged:
      case RealtimeEventType.roomUpdated:
        return Icons.hotel;
      case RealtimeEventType.roomAdded:
        return Icons.add_business;
      case RealtimeEventType.roomDeleted:
        return Icons.remove_circle_outline;
      case RealtimeEventType.guestAdded:
      case RealtimeEventType.guestUpdated:
        return Icons.person;
      case RealtimeEventType.guestDeleted:
        return Icons.person_remove;
      case RealtimeEventType.paymentAdded:
      case RealtimeEventType.paymentUpdated:
        return Icons.payment;
      case RealtimeEventType.paymentDeleted:
        return Icons.money_off;
      case RealtimeEventType.connectionStatus:
        return Icons.network_check;
      case RealtimeEventType.syncComplete:
        return Icons.sync;
      case RealtimeEventType.error:
        return Icons.error;
    }
  }

  String _getEventTitle(RealtimeEvent event) {
    switch (event.type) {
      case RealtimeEventType.bookingAdded:
        return 'New booking';
      case RealtimeEventType.bookingUpdated:
        return 'Booking updated';
      case RealtimeEventType.bookingDeleted:
        return 'Booking cancelled';
      case RealtimeEventType.roomStatusChanged:
        return 'Room status changed';
      case RealtimeEventType.roomAdded:
        return 'Room added';
      case RealtimeEventType.roomUpdated:
        return 'Room updated';
      case RealtimeEventType.roomDeleted:
        return 'Room removed';
      case RealtimeEventType.guestAdded:
        return 'Guest registered';
      case RealtimeEventType.guestUpdated:
        return 'Guest updated';
      case RealtimeEventType.guestDeleted:
        return 'Guest removed';
      case RealtimeEventType.paymentAdded:
        return 'Payment added';
      case RealtimeEventType.paymentUpdated:
        return 'Payment updated';
      case RealtimeEventType.paymentDeleted:
        return 'Payment removed';
      case RealtimeEventType.connectionStatus:
        return 'Connection status';
      case RealtimeEventType.syncComplete:
        return 'Sync completed';
      case RealtimeEventType.error:
        return 'Error occurred';
    }
  }

  String _getEventSubtitle(RealtimeEvent event) {
    switch (event.type) {
      case RealtimeEventType.bookingAdded:
      case RealtimeEventType.bookingUpdated:
      case RealtimeEventType.bookingDeleted:
        final guestName = event.data['guestName'] as String?;
        final roomNumber = event.data['roomNumber'] as String?;
        if (guestName != null && roomNumber != null) {
          return '$guestName - Room $roomNumber';
        }
        return '';
      case RealtimeEventType.roomStatusChanged:
        final roomNumber = event.data['roomNumber'] as String?;
        final newStatus = event.data['newStatus'] as String?;
        if (roomNumber != null && newStatus != null) {
          return 'Room $roomNumber → $newStatus';
        }
        return '';
      case RealtimeEventType.paymentUpdated:
        final guestName = event.data['guestName'] as String?;
        final amount = event.data['amount'] as double?;
        final newStatus = event.data['newStatus'] as String?;
        if (guestName != null && amount != null && newStatus != null) {
          return '$guestName - ₹${amount.toStringAsFixed(2)} → $newStatus';
        }
        return '';
      case RealtimeEventType.syncComplete:
        return 'All data synchronized';
      case RealtimeEventType.error:
        final message = event.data['message'] as String?;
        return message ?? 'Unknown error';
      default:
        return '';
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
