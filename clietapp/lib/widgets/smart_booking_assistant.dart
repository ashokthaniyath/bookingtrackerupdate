import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/vertex_ai_service.dart';
import '../providers/resort_data_provider.dart';
import '../models/booking.dart';
import '../models/guest.dart';
import '../models/room.dart';
import '../models/payment.dart';
import 'voice_booking_widget.dart';

/// Smart Booking Assistant Widget
/// Allows natural language booking input with AI processing
class SmartBookingAssistant extends StatefulWidget {
  const SmartBookingAssistant({super.key});

  @override
  State<SmartBookingAssistant> createState() => _SmartBookingAssistantState();
}

class _SmartBookingAssistantState extends State<SmartBookingAssistant> {
  final TextEditingController _inputController = TextEditingController();
  bool _isProcessing = false;
  BookingSuggestion? _lastSuggestion;
  String? _errorMessage;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _processBookingRequest() async {
    if (_inputController.text.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _lastSuggestion = null;
    });

    try {
      final provider = Provider.of<ResortDataProvider>(context, listen: false);

      // Get available rooms and existing guests
      final availableRooms = provider.rooms
          .where((room) => room.status.toLowerCase() == 'available')
          .toList();
      final existingGuests = provider.guests;

      // Process with AI
      final suggestion = await VertexAIService.processNaturalLanguageBooking(
        _inputController.text.trim(),
        availableRooms,
        existingGuests,
      );

      setState(() {
        _lastSuggestion = suggestion;
        _isProcessing = false;
      });

      if (suggestion.isError) {
        setState(() {
          _errorMessage = suggestion.errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to process request: $e';
      });
    }
  }

  Future<void> _createBookingFromSuggestion() async {
    if (_lastSuggestion == null || _lastSuggestion!.isError) return;

    try {
      final provider = Provider.of<ResortDataProvider>(context, listen: false);
      final suggestion = _lastSuggestion!;

      // Find or create guest
      Guest? guest =
          provider.guests
              .where(
                (g) =>
                    g.name.toLowerCase() == suggestion.guestName.toLowerCase(),
              )
              .isNotEmpty
          ? provider.guests
                .where(
                  (g) =>
                      g.name.toLowerCase() ==
                      suggestion.guestName.toLowerCase(),
                )
                .first
          : null;

      // Find suitable room
      Room? room;
      if (suggestion.roomType != null) {
        room =
            provider.rooms
                .where(
                  (r) =>
                      r.status.toLowerCase() == 'available' &&
                      r.type.toLowerCase().contains(
                        suggestion.roomType!.toLowerCase(),
                      ),
                )
                .isNotEmpty
            ? provider.rooms
                  .where(
                    (r) =>
                        r.status.toLowerCase() == 'available' &&
                        r.type.toLowerCase().contains(
                          suggestion.roomType!.toLowerCase(),
                        ),
                  )
                  .first
            : null;
      }

      room ??=
          provider.rooms
              .where((r) => r.status.toLowerCase() == 'available')
              .isNotEmpty
          ? provider.rooms
                .where((r) => r.status.toLowerCase() == 'available')
                .first
          : null;

      // Calculate booking cost
      final nights = suggestion.checkOutDate
          .difference(suggestion.checkInDate)
          .inDays;
      final baseRate = _getRoomRate(room.type);
      final totalAmount = nights * baseRate;

      // Create booking
      final booking = Booking(
        id: 'booking-${DateTime.now().millisecondsSinceEpoch}',
        guest: guest,
        room: room,
        checkIn: suggestion.checkInDate,
        checkOut: suggestion.checkOutDate,
        notes: 'Created by AI Assistant: ${suggestion.notes}',
        paymentStatus: suggestion.confidence >= 0.8
            ? 'Pending'
            : 'Quoted', // High confidence = booking, low confidence = quote
      );

      // Create corresponding payment record
      final payment = Payment(
        id: 'payment-${DateTime.now().millisecondsSinceEpoch}',
        guest: guest,
        amount: totalAmount,
        status: suggestion.confidence >= 0.8 ? 'Pending' : 'Quoted',
        date: DateTime.now(),
      );

      // Add to provider (this will update all pages automatically)
      await provider.addBooking(booking);
      await provider.addPayment(payment);
      await provider.updateRoomStatus(room.id!, 'Occupied');

      // Clear the form
      _inputController.clear();
      setState(() {
        _lastSuggestion = null;
      });

      // Show comprehensive success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🎉 AI Booking Complete!\n${guest.name} → Room ${room.number}\n💰 Total: ₹${totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create booking: $e';
      });
    }
  }

  // Helper method to get room rates
  double _getRoomRate(String roomType) {
    switch (roomType.toLowerCase()) {
      case 'suite':
        return 7000.0; // ₹7000 per night
      case 'deluxe':
        return 6000.0; // ₹6000 per night
      case 'premium':
        return 6000.0; // ₹6000 per night (same as Deluxe)
      case 'standard':
      default:
        return 5000.0; // ₹5000 per night
    }
  }

  void _showVoiceInput() {
    final provider = Provider.of<ResortDataProvider>(context, listen: false);

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
            setState(() {
              _lastSuggestion = suggestion;
              _errorMessage = null;
            });
          },
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Booking Assistant',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Powered by Vertex AI',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Input field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _inputController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Try: "Book Sarah Johnson in a deluxe room for 2 nights starting tomorrow"',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _processBookingRequest,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.psychology, size: 18),
                      label: Text(
                        _isProcessing ? 'Processing...' : 'Analyze with AI',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF667EEA),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _showVoiceInput,
                      icon: const Icon(Icons.mic, size: 18),
                      label: Text(
                        'Voice',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade100,
                        foregroundColor: Colors.purple.shade700,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[300],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.red[300],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Suggestion display
              if (_lastSuggestion != null && !_lastSuggestion!.isError) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Suggestion (${_lastSuggestion!.confidence.toInt()}% confidence)',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSuggestionItem('Guest', _lastSuggestion!.guestName),
                      if (_lastSuggestion!.guestEmail != null &&
                          _lastSuggestion!.guestEmail!.isNotEmpty)
                        _buildSuggestionItem(
                          'Email',
                          _lastSuggestion!.guestEmail!,
                        ),
                      if (_lastSuggestion!.roomType != null)
                        _buildSuggestionItem(
                          'Room Type',
                          _lastSuggestion!.roomType!,
                        ),
                      _buildSuggestionItem(
                        'Check-in',
                        _lastSuggestion!.checkInDate.toString().split(' ')[0],
                      ),
                      _buildSuggestionItem(
                        'Check-out',
                        _lastSuggestion!.checkOutDate.toString().split(' ')[0],
                      ),
                      if (_lastSuggestion!.notes.isNotEmpty)
                        _buildSuggestionItem('Notes', _lastSuggestion!.notes),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _createBookingFromSuggestion,
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(
                            'Create Booking',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
