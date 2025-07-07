import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import '../models/booking.dart';
import '../models/guest.dart';
import '../models/room.dart';

class BookingFormPage extends StatefulWidget {
  final DateTime? initialDate;
  const BookingFormPage({super.key, this.initialDate});

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  bool _depositPaid = false;
  String _paymentStatus = 'Pending';

  Guest? _selectedGuest;
  Room? _selectedRoom;
  String? _selectedRoomType;
  String? _selectedRoomStatus;

  List<Guest> _guests = [];
  List<Room> _rooms = [];
  final List<String> _roomTypes = ['Standard', 'Deluxe', 'Suite'];
  final List<String> _roomStatuses = [
    'Available',
    'Occupied',
    'Cleaning',
    'Maintenance',
  ];

  @override
  void initState() {
    super.initState();
    _loadGuestsAndRooms();
    // Set initial date if provided
    if (widget.initialDate != null) {
      _checkInDate = widget.initialDate;
      _checkOutDate = widget.initialDate;
    }
  }

  Future<void> _loadGuestsAndRooms() async {
    final guestBox = Hive.box<Guest>('guests');
    final roomBox = Hive.box<Room>('rooms');
    setState(() {
      _guests = guestBox.values.toList();
      _rooms = roomBox.values.toList();
    });
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  void _onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
        (route) => false,
      );
    } else if (index == 1) {
      Navigator.pushNamedAndRemoveUntil(context, '/calendar', (route) => false);
    } else if (index == 2) {
      Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
    }
  }

  void _showAddGuestDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add Guest',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
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
              if (nameController.text.trim().isNotEmpty) {
                final guestBox = Hive.box<Guest>('guests');
                final newGuest = Guest(
                  name: nameController.text.trim(),
                  email: emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                  phone: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                );
                await guestBox.add(newGuest);
                setState(() {
                  _guests.add(newGuest);
                  _selectedGuest = newGuest;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFormReady =
        _selectedGuest != null &&
        _selectedRoom != null &&
        _checkInDate != null &&
        _checkOutDate != null;
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
        title: const Text('Booking Form'),
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
            _buildDrawerItem(
              context,
              Icons.attach_money_rounded,
              'Sales / Payment',
              '/sales',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guest Info',
                          style: textTheme(
                            context,
                          ).titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<Guest>(
                          value: _selectedGuest,
                          items: [
                            ..._guests.map(
                              (g) => DropdownMenuItem(
                                value: g,
                                child: Text(g.name),
                              ),
                            ),
                            DropdownMenuItem<Guest>(
                              value: null,
                              child: Row(
                                children: const [
                                  Icon(Icons.add, size: 18),
                                  SizedBox(width: 4),
                                  Text('Add New Guest'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (g) {
                            if (g == null) {
                              _showAddGuestDialog();
                            } else {
                              setState(() => _selectedGuest = g);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Select Guest',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        if (_selectedGuest != null &&
                            (_selectedGuest!.email != null ||
                                _selectedGuest!.phone != null))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                if (_selectedGuest!.email != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.email, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        _selectedGuest!.email!,
                                        style: GoogleFonts.inter(fontSize: 13),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                  ),
                                if (_selectedGuest!.phone != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        _selectedGuest!.phone!,
                                        style: GoogleFonts.inter(fontSize: 13),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room Info',
                          style: textTheme(
                            context,
                          ).titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<Room>(
                          value:
                              _selectedRoom?.status.toLowerCase() == 'occupied'
                              ? null
                              : _selectedRoom,
                          items: _rooms.map((room) {
                            final isOccupied =
                                room.status.toLowerCase() == 'occupied';
                            return DropdownMenuItem<Room>(
                              value: isOccupied ? null : room,
                              enabled: !isOccupied,
                              child: Row(
                                children: [
                                  Text('${room.number} (${room.type})'),
                                  if (isOccupied)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(
                                        'Unavailable',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (room) {
                            if (room != null) {
                              setState(() {
                                _selectedRoom = room;
                                _selectedRoomType = room.type;
                                _selectedRoomStatus = room.status;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Select Room',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        if (_selectedRoom != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.meeting_room, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Type: ${_selectedRoom!.type}',
                                  style: GoogleFonts.inter(fontSize: 13),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.info_outline, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Status: ${_selectedRoom!.status}',
                                  style: GoogleFonts.inter(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedRoomType,
                                items: _roomTypes
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _selectedRoom == null
                                    ? null
                                    : (type) {
                                        setState(() {
                                          _selectedRoomType = type;
                                          if (_selectedRoom != null) {
                                            _selectedRoom = Room(
                                              number: _selectedRoom!.number,
                                              type: type!,
                                              status:
                                                  _selectedRoomStatus ??
                                                  'Available',
                                            );
                                          }
                                        });
                                      },
                                decoration: InputDecoration(
                                  labelText: 'Room Type',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedRoomStatus,
                                items: _roomStatuses
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _selectedRoom == null
                                    ? null
                                    : (status) {
                                        setState(() {
                                          _selectedRoomStatus = status;
                                          if (_selectedRoom != null) {
                                            _selectedRoom = Room(
                                              number: _selectedRoom!.number,
                                              type:
                                                  _selectedRoomType ??
                                                  'Standard',
                                              status: status!,
                                            );
                                          }
                                        });
                                      },
                                decoration: InputDecoration(
                                  labelText: 'Room Status',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Details',
                          style: textTheme(
                            context,
                          ).titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today),
                                label: Text(
                                  _checkInDate == null
                                      ? 'Select Check-in'
                                      : '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}',
                                ),
                                onPressed: () => _pickDate(isCheckIn: true),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today),
                                label: Text(
                                  _checkOutDate == null
                                      ? 'Select Check-out'
                                      : '${_checkOutDate!.day}/${_checkOutDate!.month}/${_checkOutDate!.year}',
                                ),
                                onPressed: () => _pickDate(isCheckIn: false),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'Notes',
                            labelStyle: GoogleFonts.inter(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Checkbox(
                              value: _depositPaid,
                              onChanged: (v) =>
                                  setState(() => _depositPaid = v ?? false),
                              activeColor: const Color(0xFF007AFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            Text('Deposit Paid', style: GoogleFonts.inter()),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _paymentStatus,
                          items: const [
                            DropdownMenuItem(
                              value: 'Pending',
                              child: Text('Pending'),
                            ),
                            DropdownMenuItem(
                              value: 'Paid',
                              child: Text('Paid'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _paymentStatus = v ?? 'Pending'),
                          decoration: InputDecoration(
                            labelText: 'Payment Status',
                            labelStyle: GoogleFonts.inter(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isFormReady)
                  Card(
                    color: Colors.blueGrey[50],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking Summary',
                            style: textTheme(context).titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Guest: ${_selectedGuest?.name ?? ''}'),
                          Text(
                            'Room: ${_selectedRoom?.number ?? ''} (${_selectedRoomType ?? ''}, ${_selectedRoomStatus ?? ''})',
                          ),
                          Text(
                            'Check-in: ${_checkInDate != null ? '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}' : ''}',
                          ),
                          Text(
                            'Check-out: ${_checkOutDate != null ? '${_checkOutDate!.day}/${_checkOutDate!.month}/${_checkOutDate!.year}' : ''}',
                          ),
                          Text('Deposit Paid: ${_depositPaid ? 'Yes' : 'No'}'),
                          Text('Payment Status: $_paymentStatus'),
                          if (_notesController.text.isNotEmpty)
                            Text('Notes: ${_notesController.text}'),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onPressed: isFormReady
                        ? () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              final bookingBox = Hive.box<Booking>('bookings');
                              final guest = _selectedGuest;
                              final room = _selectedRoom;
                              if (guest == null ||
                                  room == null ||
                                  _checkInDate == null ||
                                  _checkOutDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please fill all required fields.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final booking = Booking(
                                guest: guest,
                                room: Room(
                                  number: room.number,
                                  type: _selectedRoomType ?? room.type,
                                  status: 'Occupied', // Set status to Occupied
                                ),
                                checkIn: _checkInDate!,
                                checkOut: _checkOutDate!,
                                notes: _notesController.text,
                                depositPaid: _depositPaid,
                                paymentStatus: _paymentStatus,
                              );
                              await bookingBox.add(booking);
                              // Update the room status in Hive
                              final roomBox = Hive.box<Room>('rooms');
                              final roomKey = roomBox.keys.firstWhere(
                                (k) => roomBox.get(k)?.number == room.number,
                                orElse: () => null,
                              );
                              if (roomKey != null) {
                                final updatedRoom = Room(
                                  number: room.number,
                                  type: room.type,
                                  status: 'Occupied',
                                );
                                await roomBox.put(roomKey, updatedRoom);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Booking saved!')),
                              );
                              Navigator.pop(context);
                            }
                          }
                        : null,
                    child: Text(
                      'Save Booking',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: isFormReady
          ? FloatingActionButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  final bookingBox = Hive.box<Booking>('bookings');
                  final guest = _selectedGuest;
                  final room = _selectedRoom;
                  if (guest == null ||
                      room == null ||
                      _checkInDate == null ||
                      _checkOutDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all required fields.'),
                      ),
                    );
                    return;
                  }
                  final booking = Booking(
                    guest: guest,
                    room: Room(
                      number: room.number,
                      type: _selectedRoomType ?? room.type,
                      status: _selectedRoomStatus ?? room.status,
                    ),
                    checkIn: _checkInDate!,
                    checkOut: _checkOutDate!,
                    notes: _notesController.text,
                    depositPaid: _depositPaid,
                    paymentStatus: _paymentStatus,
                  );
                  await bookingBox.add(booking);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking saved!')),
                  );
                  Navigator.pop(context);
                }
              },
              backgroundColor: const Color(0xFF007AFF),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: 0,
        onItemTapped: _onTabSelected,
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

  TextTheme textTheme(BuildContext context) => Theme.of(context).textTheme;
}
