import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/booking.dart';
import '../models/guest.dart';
import '../models/room.dart';
import '../providers/resort_data_provider.dart';
import '../widgets/smart_booking_assistant.dart';
import '../widgets/voice_booking_widget.dart';
import '../services/vertex_ai_service.dart';

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
    try {
      // Android Fix: Use a different approach to prevent state conflicts
      final result = await showDialog<Guest>(
        context: context,
        builder: (context) => _AddGuestDialog(),
      );

      if (result != null && mounted) {
        try {
          // Add guest to provider
          await provider.addGuest(result);

          // Use post-frame callback to ensure state update after frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _guests = provider.guests;
                _selectedGuest = result;
              });
            }
          });
        } catch (e) {
          debugPrint('Error adding guest: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error adding guest: $e'),
                backgroundColor: const Color(0xFFF43F5E),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Dialog error: $e');
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
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width > 600 ? 32 : 20,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // AI Smart Booking Assistant
                          const SmartBookingAssistant(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height > 800
                                ? 32
                                : 24,
                          ),

                          // Voice Booking Quick Access Card - Responsive
                          _buildVoiceBookingCard(provider),
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
              value:
                  _selectedGuest != null &&
                      _guests.any((g) => g.name == _selectedGuest!.name)
                  ? _selectedGuest!.name
                  : null,
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

            // Date Selection - Responsive
            _buildDateSelectionSection(),

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

            // Payment Details - Responsive Layout
            _buildPaymentDetailsSection(),
          ],
        ),
      ),
    );
  }

  // UI Enhancement: Responsive Date Selection Section
  Widget _buildDateSelectionSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get screen dimensions for responsive design
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isHighResolution = screenWidth > 400 && screenHeight > 800;
        final isTablet = screenWidth > 600;
        final isCompact = screenWidth < 350;

        // Calculate responsive dimensions
        final horizontalPadding = isTablet ? 24.0 : 16.0;
        final spacingBetween = isCompact ? 12.0 : 16.0;
        final iconSize = isHighResolution ? 20.0 : 16.0;
        final labelFontSize = isHighResolution ? 13.0 : 12.0;
        final dateFontSize = isHighResolution ? 16.0 : 14.0;

        // For very wide screens or tablets, use horizontal layout
        if (constraints.maxWidth > 600) {
          return Row(
            children: [
              // Check-in Date
              Expanded(
                child: _buildResponsiveDateSelector(
                  'Check-in Date',
                  _checkInDate,
                  () => _pickDate(isCheckIn: true),
                  horizontalPadding: horizontalPadding,
                  iconSize: iconSize,
                  labelFontSize: labelFontSize,
                  dateFontSize: dateFontSize,
                ),
              ),
              SizedBox(width: spacingBetween),
              // Check-out Date
              Expanded(
                child: _buildResponsiveDateSelector(
                  'Check-out Date',
                  _checkOutDate,
                  () => _pickDate(isCheckIn: false),
                  horizontalPadding: horizontalPadding,
                  iconSize: iconSize,
                  labelFontSize: labelFontSize,
                  dateFontSize: dateFontSize,
                ),
              ),
            ],
          );
        }

        // For mobile devices, use vertical layout to prevent overflow
        return Column(
          children: [
            // Check-in Date
            _buildResponsiveDateSelector(
              'Check-in Date',
              _checkInDate,
              () => _pickDate(isCheckIn: true),
              horizontalPadding: horizontalPadding,
              iconSize: iconSize,
              labelFontSize: labelFontSize,
              dateFontSize: dateFontSize,
            ),
            SizedBox(height: spacingBetween),
            // Check-out Date
            _buildResponsiveDateSelector(
              'Check-out Date',
              _checkOutDate,
              () => _pickDate(isCheckIn: false),
              horizontalPadding: horizontalPadding,
              iconSize: iconSize,
              labelFontSize: labelFontSize,
              dateFontSize: dateFontSize,
            ),
          ],
        );
      },
    );
  }

  // UI Enhancement: Responsive Date Selector Widget
  Widget _buildResponsiveDateSelector(
    String label,
    DateTime? date,
    VoidCallback onTap, {
    required double horizontalPadding,
    required double iconSize,
    required double labelFontSize,
    required double dateFontSize,
  }) {
    final isSelected = date != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 350;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(horizontalPadding),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF14B8A6) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(15),
          color: isSelected
              ? const Color(0xFF14B8A6).withOpacity(0.05)
              : Colors.grey.shade50,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF14B8A6).withOpacity(0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: labelFontSize,
                color: isSelected
                    ? const Color(0xFF14B8A6)
                    : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: isCompact ? 6 : 8),
            // Date Display
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: iconSize,
                  color: isSelected
                      ? const Color(0xFF14B8A6)
                      : Colors.grey.shade400,
                ),
                SizedBox(width: isCompact ? 6 : 8),
                Expanded(
                  child: Text(
                    date != null ? _formatDate(date) : 'Select Date',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: dateFontSize,
                      color: isSelected
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
                // Visual indicator for selected state
                if (isSelected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF14B8A6),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            // Additional info for selected dates
            if (isSelected) ...[
              SizedBox(height: isCompact ? 4 : 6),
              Text(
                _getDateInfo(date, label),
                style: GoogleFonts.poppins(
                  fontSize: labelFontSize - 1,
                  color: const Color(0xFF64748B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to format date display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today (${date.day}/${date.month}/${date.year})';
    } else if (difference == 1) {
      return 'Tomorrow (${date.day}/${date.month}/${date.year})';
    } else if (difference == -1) {
      return 'Yesterday (${date.day}/${date.month}/${date.year})';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Helper method to get additional date info
  String _getDateInfo(DateTime date, String label) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (label.contains('Check-in')) {
      if (difference > 0) {
        return 'In $difference days';
      } else if (difference == 0) {
        return 'Today';
      } else {
        return '${difference.abs()} days ago';
      }
    } else {
      // Check-out date
      if (_checkInDate != null) {
        final stayDuration = date.difference(_checkInDate!).inDays;
        return stayDuration == 1 ? '1 night stay' : '$stayDuration nights stay';
      }
      return '';
    }
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

  // Show Voice Booking Dialog
  void _showVoiceBookingDialog(ResortDataProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: VoiceBookingWidget(
          availableRooms: provider.rooms
              .where((room) => room.status.toLowerCase() != 'occupied')
              .toList(),
          existingGuests: provider.guests,
          onBookingSuggestion: (suggestion) {
            Navigator.pop(context);
            _applyVoiceBookingSuggestion(suggestion, provider);
          },
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // Apply Voice Booking Suggestion
  void _applyVoiceBookingSuggestion(
    BookingSuggestion suggestion,
    ResortDataProvider provider,
  ) {
    try {
      setState(() {
        // Validate and clean up guest name
        String cleanGuestName = suggestion.guestName.trim();

        // If guest name contains booking-related words, use a default name
        final bookingWords = [
          'reservation',
          'booking',
          'suit',
          'suite',
          'room',
          'check',
          'today',
          'tomorrow',
        ];
        if (bookingWords.any(
          (word) => cleanGuestName.toLowerCase().contains(word),
        )) {
          cleanGuestName = 'Voice Booking Guest';
        }

        // Find or create guest
        final existingGuest = provider.guests.firstWhere(
          (guest) => guest.name.toLowerCase() == cleanGuestName.toLowerCase(),
          orElse: () => Guest(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: cleanGuestName,
            email:
                '${cleanGuestName.toLowerCase().replaceAll(' ', '.')}@example.com',
            phone: '+1234567890',
          ),
        );

        // Set guest
        _selectedGuest = existingGuest;

        // Find room by type or availability
        final availableRooms = provider.rooms
            .where((room) => room.status.toLowerCase() != 'occupied')
            .toList();

        Room? selectedRoom;
        if (suggestion.roomType != null) {
          selectedRoom = availableRooms.firstWhere(
            (room) => room.type.toLowerCase().contains(
              suggestion.roomType!.toLowerCase(),
            ),
            orElse: () => availableRooms.isNotEmpty
                ? availableRooms.first
                : Room(
                    id: 'temp',
                    number: '101',
                    type: suggestion.roomType ?? 'Standard',
                    status: 'Available',
                    pricePerNight: 100.0,
                  ),
          );
        } else if (availableRooms.isNotEmpty) {
          selectedRoom = availableRooms.first;
        }

        _selectedRoom = selectedRoom;
        _selectedRoomType = selectedRoom?.type;

        // Set dates
        _checkInDate = suggestion.checkInDate;
        _checkOutDate = suggestion.checkOutDate;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Voice booking applied! Review and save to confirm.',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error applying voice booking suggestion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error applying voice booking. Please try again.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // UI Enhancement: Responsive Payment Details Section
  Widget _buildPaymentDetailsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get screen dimensions for responsive design
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isHighResolution = screenWidth > 400 && screenHeight > 800;
        final isTablet = screenWidth > 600;

        // Calculate responsive dimensions
        final horizontalPadding = isTablet ? 24.0 : 16.0;
        final verticalSpacing = isHighResolution ? 20.0 : 16.0;
        final fontSize = isHighResolution ? 14.0 : 13.0;
        final checkboxScale = isHighResolution ? 1.2 : 1.0;

        // For very wide screens or tablets, use horizontal layout
        if (constraints.maxWidth > 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Deposit Paid Section
              Expanded(
                flex: 1,
                child: _buildDepositPaidWidget(
                  fontSize: fontSize,
                  checkboxScale: checkboxScale,
                  horizontalPadding: horizontalPadding,
                ),
              ),
              SizedBox(width: horizontalPadding),
              // Payment Status Section
              Expanded(
                flex: 1,
                child: _buildPaymentStatusWidget(
                  fontSize: fontSize,
                  horizontalPadding: horizontalPadding,
                ),
              ),
            ],
          );
        }

        // For mobile devices, use vertical layout to prevent overflow
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Deposit Paid Section
            _buildDepositPaidWidget(
              fontSize: fontSize,
              checkboxScale: checkboxScale,
              horizontalPadding: horizontalPadding,
            ),
            SizedBox(height: verticalSpacing),
            // Payment Status Section
            _buildPaymentStatusWidget(
              fontSize: fontSize,
              horizontalPadding: horizontalPadding,
            ),
          ],
        );
      },
    );
  }

  // UI Enhancement: Deposit Paid Widget
  Widget _buildDepositPaidWidget({
    required double fontSize,
    required double checkboxScale,
    required double horizontalPadding,
  }) {
    return Container(
      padding: EdgeInsets.all(horizontalPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF14B8A6).withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _depositPaid ? const Color(0xFF14B8A6) : Colors.grey.shade300,
          width: _depositPaid ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: checkboxScale,
            child: Checkbox(
              value: _depositPaid,
              onChanged: (v) => setState(() => _depositPaid = v ?? false),
              activeColor: const Color(0xFF14B8A6),
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Deposit Paid',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: fontSize,
                color: _depositPaid
                    ? const Color(0xFF14B8A6)
                    : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UI Enhancement: Payment Status Widget
  Widget _buildPaymentStatusWidget({
    required double fontSize,
    required double horizontalPadding,
  }) {
    return DropdownButtonFormField<String>(
      value: _paymentStatus,
      items: const [
        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
        DropdownMenuItem(value: 'Paid', child: Text('Paid')),
        DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
      ],
      onChanged: (v) => setState(() => _paymentStatus = v ?? 'Pending'),
      decoration: InputDecoration(
        labelText: 'Payment Status',
        labelStyle: GoogleFonts.poppins(
          fontSize: fontSize,
          color: const Color(0xFF64748B),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF14B8A6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 16,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        color: const Color(0xFF1E293B),
      ),
      dropdownColor: Colors.white,
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF14B8A6)),
    );
  }

  // UI Enhancement: Responsive Voice Booking Card
  Widget _buildVoiceBookingCard(ResortDataProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isHighResolution = screenWidth > 400 && screenHeight > 800;
        final isCompact = screenWidth < 350;

        // Responsive dimensions
        final cardPadding = isHighResolution ? 20.0 : 16.0;
        final iconSize = isHighResolution ? 32.0 : 28.0;
        final titleFontSize = isHighResolution ? 16.0 : 14.0;
        final subtitleFontSize = isHighResolution ? 13.0 : 12.0;
        final buttonFontSize = isHighResolution ? 13.0 : 12.0;
        final spacingBetween = isCompact ? 8.0 : 12.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade50, Colors.indigo.shade50],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.shade100.withOpacity(0.3),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              // For very compact screens, use vertical layout
              if (isCompact) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mic,
                      color: Colors.purple.shade600,
                      size: iconSize,
                    ),
                    SizedBox(width: spacingBetween),
                    Text(
                      'Voice Booking',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                        fontSize: titleFontSize,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacingBetween),
                Text(
                  'Create bookings with speech recognition',
                  style: GoogleFonts.poppins(
                    fontSize: subtitleFontSize,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacingBetween),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showVoiceBookingDialog(provider),
                    icon: Icon(
                      Icons.mic_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Start Voice Booking',
                      style: GoogleFonts.poppins(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ]
              // For normal screens, use horizontal layout
              else ...[
                Row(
                  children: [
                    Icon(
                      Icons.mic,
                      color: Colors.purple.shade600,
                      size: iconSize,
                    ),
                    SizedBox(width: spacingBetween),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voice Booking Available',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                              fontSize: titleFontSize,
                            ),
                          ),
                          Text(
                            'Create bookings with speech recognition',
                            style: GoogleFonts.poppins(
                              fontSize: subtitleFontSize,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: spacingBetween),
                    ElevatedButton.icon(
                      onPressed: () => _showVoiceBookingDialog(provider),
                      icon: Icon(
                        Icons.mic_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Start Voice',
                        style: GoogleFonts.poppins(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// Android Fix: Separate StatefulWidget for guest dialog to prevent state conflicts
class _AddGuestDialog extends StatefulWidget {
  @override
  _AddGuestDialogState createState() => _AddGuestDialogState();
}

class _AddGuestDialogState extends State<_AddGuestDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a guest name';
      });
      return;
    }

    final newGuest = Guest(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );

    Navigator.pop(context, newGuest);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.poppins(
                  color: const Color(0xFFF43F5E),
                  fontSize: 12,
                ),
              ),
            ),
          TextField(
            controller: _nameController,
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
            onChanged: (value) {
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
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
            controller: _phoneController,
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
          onPressed: _handleSubmit,
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
    );
  }
}
