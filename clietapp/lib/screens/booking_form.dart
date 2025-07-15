import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/booking.dart';
import '../models/guest.dart';
import '../models/room.dart';
import '../providers/resort_data_provider.dart';
import '../widgets/smart_booking_assistant.dart';

class BookingFormPage extends StatefulWidget {
  final DateTime? initialDate;
  const BookingFormPage({super.key, this.initialDate});

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  bool _depositPaid = false;
  String _paymentStatus = 'Pending';

  Guest? _selectedGuest;
  Room? _selectedRoom;
  String? _selectedRoomType;

  List<Guest> _guests = [];
  List<Room> _rooms = [];

  // UI Enhancement: Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    try {
      // UI Enhancement: Initialize Animation Controllers with error handling
      _fadeController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      _slideController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );

      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
      );
      _slideAnimation =
          Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
              parent: _slideController,
              curve: Curves.easeOutBack,
            ),
          );

      // Bug Prevention: Set initial dates with null safety checks
      if (widget.initialDate != null) {
        _checkInDate = widget.initialDate;
        _checkOutDate = widget.initialDate!.add(const Duration(days: 1));
      } else {
        // Reflect current date: July 08, 2025 11:23 AM IST
        final now = DateTime(2025, 7, 8, 11, 23);
        _checkInDate = now;
        _checkOutDate = now.add(const Duration(days: 1));
      }

      // Use addPostFrameCallback to ensure widget is fully laid out before animations
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Start animations safely after layout completion
          _fadeController.forward();
          _slideController.forward();
        }
      });
    } catch (e) {
      // Bug Prevention: Graceful error handling for animation initialization
      debugPrint('Animation initialization error: $e');
    }
  }

  @override
  void dispose() {
    // Bug Prevention: Proper disposal to prevent memory leaks
    _fadeController.dispose();
    _slideController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    try {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: isCheckIn
            ? (_checkInDate ?? now)
            : (_checkOutDate ?? now.add(const Duration(days: 1))),
        firstDate: now.subtract(const Duration(days: 365)),
        lastDate: now.add(const Duration(days: 365)),
      );

      if (picked != null && mounted) {
        setState(() {
          if (isCheckIn) {
            _checkInDate = picked;
            // Bug Prevention: Ensure check-out is after check-in
            if (_checkOutDate != null && _checkOutDate!.isBefore(picked)) {
              _checkOutDate = picked.add(const Duration(days: 1));
            }
          } else {
            _checkOutDate = picked;
            // Bug Prevention: Ensure check-in is before check-out
            if (_checkInDate != null && picked.isBefore(_checkInDate!)) {
              _checkInDate = picked.subtract(const Duration(days: 1));
            }
          }
        });
      }
    } catch (e) {
      // Bug Prevention: Handle date picker errors
      debugPrint('Date picker error: $e');
    }
  }

  void _showAddGuestDialog(ResortDataProvider provider) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    try {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Add Guest',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  labelText: 'Name *',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF14B8A6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFF14B8A6),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  labelText: 'Email (Optional)',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF14B8A6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFF14B8A6),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  labelText: 'Phone (Optional)',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF14B8A6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFF14B8A6),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Bug Prevention: Validate input before creating guest
                if (nameController.text.trim().isNotEmpty) {
                  try {
                    final newGuest = Guest(
                      name: nameController.text.trim(),
                      email: emailController.text.trim().isEmpty
                          ? null
                          : emailController.text.trim(),
                      phone: phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim(),
                    );

                    await provider.addGuest(newGuest);
                    if (mounted) {
                      setState(() {
                        _guests = provider.guests;
                        _selectedGuest = newGuest;
                      });
                      if (mounted) Navigator.pop(context);
                    }
                  } catch (e) {
                    debugPrint('Error adding guest: $e');
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error adding guest: $e'),
                          backgroundColor: const Color(0xFFF43F5E),
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Add',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Dialog error: $e');
    } finally {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Data Flow: Use Consumer to listen to provider changes for real-time data
    return Consumer<ResortDataProvider>(
      builder: (context, provider, child) {
        // Bug Prevention: Ensure widget is mounted and data is available
        if (!mounted) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF87CEEB), // Sky blue
                  Color(0xFFFFFFFF), // White
                ],
              ),
            ),
            child: const Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
                ),
              ),
            ),
          );
        }

        // Bug Prevention: Null safety checks for provider data
        _guests = provider.guests;
        _rooms = provider.rooms;

        // Bug Prevention: Clear selected room if it's no longer available
        if (_selectedRoom != null) {
          final isRoomStillAvailable = _rooms
              .where((room) => room.status.toLowerCase() != 'occupied')
              .any((room) => room.number == _selectedRoom!.number);
          if (!isRoomStillAvailable) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedRoom = null;
              });
            });
          }
        }

        // Bug Prevention: Validate form readiness with null checks
        final isFormReady =
            _selectedGuest != null &&
            _selectedRoom != null &&
            _checkInDate != null &&
            _checkOutDate != null;

        return Container(
          // UI Enhancement: Luxury Gradient Background
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF87CEEB), // Sky blue
                Color(0xFFFFFFFF), // White
              ],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF1E3A8A)),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Text(
                'Create Booking',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
                  onPressed: () async {
                    try {
                      // Refresh data from provider
                      await provider.loadData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Data refreshed!',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            backgroundColor: const Color(0xFF14B8A6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Refresh error: $e');
                    }
                  },
                ),
              ],
            ),
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // AI Smart Booking Assistant
                          const SmartBookingAssistant(),
                          const SizedBox(height: 24),

                          // UI Enhancement: Guest Selection Card
                          _buildGuestSelectionCard(provider),
                          const SizedBox(height: 20),

                          // UI Enhancement: Room Selection Card
                          _buildRoomSelectionCard(provider),
                          const SizedBox(height: 20),

                          // UI Enhancement: Booking Details Card
                          _buildBookingDetailsCard(),
                          const SizedBox(height: 30),

                          // UI Enhancement: Save Button
                          _buildSaveButton(provider, isFormReady),
                          const SizedBox(
                            height: 100,
                          ), // Space for bottom navigation
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // UI Enhancement: Drawer Menu
            drawer: _buildDrawer(),
          ),
        );
      },
    );
  }

  // UI Enhancement: Guest Selection Card
  Widget _buildGuestSelectionCard(ResortDataProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF14B8A6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Guest Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGuest?.name,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select or add a guest';
                }
                return null;
              },
              items: [
                ..._guests
                    .toList()
                    .fold<Map<String, Guest>>({}, (map, guest) {
                      // Ensure unique guest names
                      map[guest.name] = guest;
                      return map;
                    })
                    .values
                    .map(
                      (g) => DropdownMenuItem(
                        value: g.name,
                        child: Text(g.name, style: GoogleFonts.poppins()),
                      ),
                    ),
                const DropdownMenuItem<String>(
                  value: '__ADD_NEW__',
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 18, color: Color(0xFF14B8A6)),
                      SizedBox(width: 4),
                      Text(
                        'Add New Guest',
                        style: TextStyle(
                          color: Color(0xFF14B8A6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (guestName) {
                if (guestName == '__ADD_NEW__') {
                  _showAddGuestDialog(provider);
                } else if (guestName != null) {
                  final guest = _guests.firstWhere(
                    (g) => g.name == guestName,
                    orElse: () => _guests.first,
                  );
                  setState(() => _selectedGuest = guest);
                }
              },
              decoration: InputDecoration(
                labelText: 'Select Guest',
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFF14B8A6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Color(0xFF14B8A6),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFFF43F5E)),
                ),
              ),
            ),
            // Bug Prevention: Null safety checks for guest details
            if (_selectedGuest != null &&
                (_selectedGuest!.email != null ||
                    _selectedGuest!.phone != null))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      if (_selectedGuest!.email != null) ...[
                        const Icon(
                          Icons.email,
                          size: 16,
                          color: Color(0xFF14B8A6),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _selectedGuest!.email!,
                            style: GoogleFonts.poppins(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selectedGuest!.phone != null)
                          const SizedBox(width: 12),
                      ],
                      if (_selectedGuest!.phone != null) ...[
                        const Icon(
                          Icons.phone,
                          size: 16,
                          color: Color(0xFF14B8A6),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _selectedGuest!.phone!,
                            style: GoogleFonts.poppins(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // UI Enhancement: Room Selection Card
  Widget _buildRoomSelectionCard(ResortDataProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.hotel,
                    color: Color(0xFF14B8A6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Room Selection',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value:
                  _selectedRoom != null &&
                      _rooms
                          .where(
                            (room) => room.status.toLowerCase() != 'occupied',
                          )
                          .any((room) => room.number == _selectedRoom!.number)
                  ? _selectedRoom!.number
                  : null,
              validator: (value) {
                if (value == null) {
                  return 'Please select a room';
                }
                return null;
              },
              items: _rooms
                  .where((room) => room.status.toLowerCase() != 'occupied')
                  .toList()
                  .fold<Map<String, Room>>({}, (map, room) {
                    // Ensure unique room numbers by using the room number as key
                    map[room.number] = room;
                    return map;
                  })
                  .values
                  .map((room) {
                    return DropdownMenuItem(
                      value: room.number,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Room ${room.number} (${room.type})',
                              style: GoogleFonts.poppins(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(),
              onChanged: (roomNumber) {
                if (roomNumber != null) {
                  final room = _rooms.firstWhere(
                    (r) => r.number == roomNumber,
                    orElse: () => _rooms.first,
                  );
                  setState(() {
                    _selectedRoom = room;
                    _selectedRoomType = room.type;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Select Room',
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFF14B8A6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Color(0xFF14B8A6),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFFF43F5E)),
                ),
              ),
            ),
            // Bug Prevention: Null safety for selected room
            if (_selectedRoom != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.meeting_room,
                        size: 16,
                        color: Color(0xFF14B8A6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Type: ${_selectedRoom!.type}',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Color(0xFF14B8A6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Status: ${_selectedRoom!.status}',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // UI Enhancement: Booking Details Card
  Widget _buildBookingDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: Color(0xFF14B8A6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Booking Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date Selection Row
            Row(
              children: [
                Expanded(
                  child: _buildDateSelector(
                    'Check-in Date',
                    _checkInDate,
                    () => _pickDate(isCheckIn: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateSelector(
                    'Check-out Date',
                    _checkOutDate,
                    () => _pickDate(isCheckIn: false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Notes Field
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFF14B8A6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Color(0xFF14B8A6),
                    width: 2,
                  ),
                ),
                prefixIcon: const Icon(Icons.notes, color: Color(0xFF14B8A6)),
              ),
              maxLines: 3,
              style: GoogleFonts.poppins(),
            ),

            const SizedBox(height: 16),

            // Payment Details
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Checkbox(
                        value: _depositPaid,
                        onChanged: (v) =>
                            setState(() => _depositPaid = v ?? false),
                        activeColor: const Color(0xFF14B8A6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          'Deposit Paid',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _paymentStatus,
                    items: const [
                      DropdownMenuItem(
                        value: 'Pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                      DropdownMenuItem(
                        value: 'Cancelled',
                        child: Text('Cancelled'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _paymentStatus = v ?? 'Pending'),
                    decoration: InputDecoration(
                      labelText: 'Payment Status',
                      labelStyle: GoogleFonts.poppins(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF14B8A6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Color(0xFF14B8A6),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // UI Enhancement: Date Selector Widget
  Widget _buildDateSelector(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: date != null
                ? const Color(0xFF14B8A6)
                : Colors.grey.shade300,
            width: date != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(15),
          color: date != null
              ? const Color(0xFF14B8A6).withValues(alpha: 0.05)
              : Colors.grey.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: date != null
                      ? const Color(0xFF14B8A6)
                      : Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Select Date',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: date != null
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // UI Enhancement: Save Button
  Widget _buildSaveButton(ResortDataProvider provider, bool isFormReady) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: isFormReady
            ? const LinearGradient(
                colors: [Color(0xFF14B8A6), Color(0xFF059669)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : LinearGradient(
                colors: [
                  Colors.grey.withValues(alpha: 0.5),
                  Colors.grey.withValues(alpha: 0.3),
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isFormReady
            ? [
                BoxShadow(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                  offset: const Offset(0, 8),
                  blurRadius: 20,
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: isFormReady ? () => _saveBooking(provider) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isFormReady) ...[
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              isFormReady ? 'Create Booking' : 'Complete Form to Continue',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bug Prevention: Separate method for saving booking with comprehensive error handling
  Future<void> _saveBooking(ResortDataProvider provider) async {
    try {
      // Validate form
      if (!_formKey.currentState!.validate()) {
        return;
      }

      // Bug Prevention: Additional null checks
      final guest = _selectedGuest;
      final room = _selectedRoom;
      final checkIn = _checkInDate;
      final checkOut = _checkOutDate;

      if (guest == null ||
          room == null ||
          checkIn == null ||
          checkOut == null) {
        _showErrorSnackBar('Please complete all required fields');
        return;
      }

      // Bug Prevention: Validate date logic
      if (checkOut.isBefore(checkIn) || checkOut.isAtSameMomentAs(checkIn)) {
        _showErrorSnackBar('Check-out date must be after check-in date');
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF14B8A6)),
                const SizedBox(height: 16),
                Text('Creating booking...', style: GoogleFonts.poppins()),
              ],
            ),
          ),
        ),
      );

      // Data Flow: Use ResortDataProvider for real-time synchronization
      final booking = Booking(
        guest: guest,
        room: Room(
          number: room.number,
          type: _selectedRoomType ?? room.type,
          status: 'Occupied', // Set status to Occupied
        ),
        checkIn: checkIn,
        checkOut: checkOut,
        notes: _notesController.text.trim(),
        depositPaid: _depositPaid,
        paymentStatus: _paymentStatus,
      );

      // Add booking through provider for real-time sync
      await provider.addBooking(booking);

      // Update room status to occupied
      await provider.updateRoomStatusByNumber(room.number, 'Occupied');

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Booking created successfully!',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF14B8A6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Debug: Print success message
      print(
        "Form Saved Successfully - Booking created for ${guest.name} in Room ${room.number}",
      );

      // Clear form and show success state
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          // Reset form to allow new booking
          setState(() {
            _selectedGuest = null;
            _selectedRoom = null;
            _selectedRoomType = null;
            _checkInDate = null;
            _checkOutDate = null;
            _notesController.clear();
            _depositPaid = false;
            _paymentStatus = 'Pending';
          });

          // Show additional success feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Form cleared. Ready for next booking!',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      debugPrint('Error saving booking: $e');
      _showErrorSnackBar('Failed to create booking: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFF43F5E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // UI Enhancement: Drawer Menu
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              ),
            ),
            child: Text(
              'Resort Manager',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildDrawerItem(context, Icons.dashboard, 'Dashboard', '/dashboard'),
          _buildDrawerItem(context, Icons.bed_rounded, 'Rooms', '/rooms'),
          _buildDrawerItem(
            context,
            Icons.people_alt_rounded,
            'Guest List',
            '/guests',
          ),
          _buildDrawerItem(
            context,
            Icons.attach_money_rounded,
            'Sales / Payment',
            '/sales',
          ),
          _buildDrawerItem(
            context,
            Icons.analytics_outlined,
            'Analytics',
            '/analytics',
          ),
          _buildDrawerItem(
            context,
            Icons.person_outline,
            'Profile',
            '/profile',
          ),
        ],
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
      leading: Icon(icon, color: const Color(0xFF1E3A8A)),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context);
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}
