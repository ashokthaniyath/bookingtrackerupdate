import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/resort_data_provider.dart';

class RoomStatusScreen extends StatelessWidget {
  const RoomStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Status'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Consumer<ResortDataProvider>(
        builder: (context, provider, _) {
          if (provider.rooms.isEmpty) {
            return const Center(child: Text('No rooms available'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.rooms.length,
            itemBuilder: (context, index) {
              final room = provider.rooms[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(room.status),
                    child: Text(
                      room.number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text('Room ${room.number}'),
                  subtitle: Text('${room.type} - ${room.status}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (status) async {
                      await provider.updateRoomStatus(room.number, status);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'available',
                        child: Text('Available'),
                      ),
                      const PopupMenuItem(
                        value: 'occupied',
                        child: Text('Occupied'),
                      ),
                      const PopupMenuItem(
                        value: 'cleaning',
                        child: Text('Cleaning'),
                      ),
                      const PopupMenuItem(
                        value: 'maintenance',
                        child: Text('Maintenance'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'occupied':
        return Colors.red;
      case 'cleaning':
        return Colors.orange;
      case 'maintenance':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
