import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/guest.dart';
import '../providers/resort_data_provider.dart';

class GuestManagementPage extends StatefulWidget {
  const GuestManagementPage({super.key});

  @override
  State<GuestManagementPage> createState() => _GuestManagementPageState();
}

class _GuestManagementPageState extends State<GuestManagementPage> {
  void _showGuestDialog({Guest? guest}) {
    final nameController = TextEditingController(text: guest?.name ?? '');
    final emailController = TextEditingController(text: guest?.email ?? '');
    final phoneController = TextEditingController(text: guest?.phone ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(guest == null ? 'Add Guest' : 'Edit Guest'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final provider = Provider.of<ResortDataProvider>(
                  context,
                  listen: false,
                );
                final newGuest = Guest(
                  id:
                      guest?.id ??
                      'guest-${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                );

                if (guest == null) {
                  provider.addGuest(newGuest);
                } else {
                  provider.updateGuest(guest.id!, newGuest);
                }
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(guest == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _deleteGuest(Guest guest) async {
    try {
      final provider = Provider.of<ResortDataProvider>(context, listen: false);
      provider.deleteGuest(guest.id!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting guest: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF007AFF)),
        title: const Text('Guest Management'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildDrawerItem(context, Icons.bed_rounded, 'Rooms', '/rooms'),
            _buildDrawerItem(
              context,
              Icons.people_alt_rounded,
              'Guest List',
              '/guests',
            ),
            _buildDrawerItem(
              context,
              Icons.analytics_outlined,
              'Analytics',
              '/analytics',
            ),
            _buildDrawerItem(
              context,
              Icons.add_box_rounded,
              'Booking',
              '/booking-form',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Guests',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _showGuestDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Consumer<ResortDataProvider>(
                  builder: (context, provider, child) {
                    final guests = provider.guests;
                    final bookings = provider.bookings;

                    // Pre-group bookings by guest ID for fast lookup
                    final Map<String, int> guestBookingCount = {};
                    for (final b in bookings) {
                      guestBookingCount[b.guest.id ?? ''] =
                          (guestBookingCount[b.guest.id ?? ''] ?? 0) + 1;
                    }

                    if (guests.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No guests found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: guests.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final guest = guests[i];
                        final bookingCount =
                            guestBookingCount[guest.id ?? ''] ?? 0;
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          color: Colors.white,
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person_outline),
                            ),
                            title: Text(
                              guest.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(guest.email ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (bookingCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$bookingCount booking(s)',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Color(0xFF007AFF),
                                  ),
                                  onPressed: () =>
                                      _showGuestDialog(guest: guest),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFF43F5E),
                                  ),
                                  onPressed: () => _deleteGuest(guest),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}
