import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/voice_ai_service_stub.dart';
import '../services/vertex_ai_service.dart';

import '../models/guest.dart';
import '../models/room.dart';

/// Voice-enabled booking widget with speech recognition and audio feedback
/// Responsive design for high-resolution mobile devices like Samsung S25 Ultra
class VoiceBookingWidget extends StatefulWidget {
  final List<Room> availableRooms;
  final List<Guest> existingGuests;
  final Function(BookingSuggestion) onBookingSuggestion;
  final VoidCallback? onClose;

  const VoiceBookingWidget({
    super.key,
    required this.availableRooms,
    required this.existingGuests,
    required this.onBookingSuggestion,
    this.onClose,
  });

  @override
  State<VoiceBookingWidget> createState() => _VoiceBookingWidgetState();
}

class _VoiceBookingWidgetState extends State<VoiceBookingWidget>
    with TickerProviderStateMixin {
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isProcessing = false;
  String _speechText = '';
  String _statusMessage = 'Tap the microphone to start voice booking';
  BookingSuggestion? _lastSuggestion;

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  StreamSubscription? _listeningSubscription;
  StreamSubscription? _speakingSubscription;
  StreamSubscription? _speechSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupVoiceListeners();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  void _setupVoiceListeners() {
    _listeningSubscription = VoiceAIService.listeningStream.listen((
      isListening,
    ) {
      if (mounted) {
        setState(() {
          _isListening = isListening;
          if (isListening) {
            _statusMessage = 'Listening... Speak your booking request';
            _pulseController.repeat(reverse: true);
            _waveController.repeat(reverse: true);
          } else {
            _pulseController.stop();
            _waveController.stop();
          }
        });
      }
    });

    _speakingSubscription = VoiceAIService.speakingStream.listen((isSpeaking) {
      if (mounted) {
        setState(() {
          _isSpeaking = isSpeaking;
          if (isSpeaking) {
            _statusMessage = 'Speaking response...';
          }
        });
      }
    });

    _speechSubscription = VoiceAIService.speechStream.listen((speech) {
      if (mounted) {
        setState(() {
          _speechText = speech;
          if (speech.isNotEmpty) {
            _statusMessage = 'Processing: "$speech"';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _listeningSubscription?.cancel();
    _speakingSubscription?.cancel();
    _speechSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startVoiceBooking() async {
    try {
      HapticFeedback.lightImpact();
      await VoiceAIService.startListening();
      setState(() {
        _speechText = '';
        _lastSuggestion = null;
        _statusMessage = 'Listening... Speak your booking request';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error starting voice recognition: $e';
      });
    }
  }

  Future<void> _stopVoiceBooking() async {
    try {
      await VoiceAIService.stopListening();
      setState(() {
        _statusMessage = 'Processing your request...';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error stopping voice recognition: $e';
      });
    }
  }

  Future<void> _processVoiceInput() async {
    if (_speechText.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing your booking request...';
    });

    try {
      final suggestion = await VertexAIService.processNaturalLanguageBooking(
        _speechText,
        widget.availableRooms,
        widget.existingGuests,
      );

      if (mounted && !suggestion.isError) {
        setState(() {
          _lastSuggestion = suggestion;
          _statusMessage = 'Booking suggestion ready!';
          _isProcessing = false;
        });

        await VoiceAIService.speak(
          'I found a suitable booking for ${suggestion.guestName}. '
          'Check-in on ${_formatDate(suggestion.checkInDate.toString())} and check-out on ${_formatDate(suggestion.checkOutDate.toString())}. '
          'Would you like to confirm this booking?',
        );
      } else {
        setState(() {
          _statusMessage = 'Could not process your request. Please try again.';
          _isProcessing = false;
        });

        await VoiceAIService.speak(
          'I could not understand your booking request. Please try again with details like guest name, room preference, and dates.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error processing request: ${e.toString()}';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Responsive calculations for different device sizes
    final isLargeScreen = screenWidth > 400;
    final isVeryLargeScreen = screenWidth > 600;
    final padding = isVeryLargeScreen
        ? 32.0
        : isLargeScreen
        ? 24.0
        : 16.0;
    final titleFontSize = isVeryLargeScreen
        ? 22.0
        : isLargeScreen
        ? 20.0
        : 18.0;
    final micSize = isVeryLargeScreen
        ? 140.0
        : isLargeScreen
        ? 120.0
        : 100.0;
    final waveSize = isVeryLargeScreen
        ? 160.0
        : isLargeScreen
        ? 140.0
        : 120.0;

    // Dialog constraints for responsive design on high-res devices
    final maxDialogWidth = screenWidth * 0.92;
    final maxDialogHeight = screenHeight * 0.88;
    final dialogWidth = maxDialogWidth > 550 ? 550 : maxDialogWidth;
    final dialogHeight = maxDialogHeight > 700 ? 700 : maxDialogHeight;

    return Dialog(
      insetPadding: EdgeInsets.all(padding),
      child: Container(
        width: dialogWidth.toDouble(),
        height: dialogHeight.toDouble(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.indigo.shade50],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(padding * 0.33),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.record_voice_over,
                      color: Colors.white,
                      size: isVeryLargeScreen
                          ? 28
                          : isLargeScreen
                          ? 24
                          : 20,
                    ),
                  ),
                  SizedBox(width: padding * 0.5),
                  Expanded(
                    child: Text(
                      'Voice Booking Assistant',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close),
                      tooltip: 'Close Voice Assistant',
                      iconSize: isLargeScreen ? 28 : 24,
                    ),
                ],
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: padding),
                  child: Column(
                    children: [
                      // Voice Input Visualization
                      Center(
                        child: GestureDetector(
                          onTap: _isListening
                              ? _stopVoiceBooking
                              : _startVoiceBooking,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Wave animation background
                              if (_isListening)
                                AnimatedBuilder(
                                  animation: _waveAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      width:
                                          waveSize +
                                          (_waveAnimation.value *
                                              (isVeryLargeScreen
                                                  ? 50
                                                  : isLargeScreen
                                                  ? 40
                                                  : 30)),
                                      height:
                                          waveSize +
                                          (_waveAnimation.value *
                                              (isVeryLargeScreen
                                                  ? 50
                                                  : isLargeScreen
                                                  ? 40
                                                  : 30)),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(
                                          0.15 - (_waveAnimation.value * 0.1),
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  },
                                ),

                              // Pulse animation
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _isListening
                                        ? _pulseAnimation.value
                                        : 1.0,
                                    child: Container(
                                      width: micSize,
                                      height: micSize,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: _isListening
                                              ? [
                                                  Colors.red.shade400,
                                                  Colors.red.shade600,
                                                ]
                                              : _isSpeaking
                                              ? [
                                                  Colors.green.shade400,
                                                  Colors.green.shade600,
                                                ]
                                              : [
                                                  Colors.blue.shade400,
                                                  Colors.blue.shade600,
                                                ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (_isListening
                                                        ? Colors.red
                                                        : Colors.blue)
                                                    .withOpacity(0.4),
                                            blurRadius: 25,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _isListening
                                            ? Icons.mic
                                            : _isSpeaking
                                            ? Icons.volume_up
                                            : _isProcessing
                                            ? Icons.hourglass_empty
                                            : Icons.mic_none,
                                        size: isVeryLargeScreen
                                            ? 60
                                            : isLargeScreen
                                            ? 50
                                            : 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: padding * 1.5),

                      // Status and Instructions
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(padding),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Status Message
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(padding * 0.75),
                              decoration: BoxDecoration(
                                color: _isListening
                                    ? Colors.red.withOpacity(0.1)
                                    : _isSpeaking
                                    ? Colors.green.withOpacity(0.1)
                                    : _isProcessing
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _statusMessage,
                                style: TextStyle(
                                  fontSize: isVeryLargeScreen
                                      ? 18
                                      : isLargeScreen
                                      ? 16
                                      : 14,
                                  fontWeight: FontWeight.w600,
                                  color: _isListening
                                      ? Colors.red.shade700
                                      : _isSpeaking
                                      ? Colors.green.shade700
                                      : _isProcessing
                                      ? Colors.orange.shade700
                                      : Colors.blue.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            // Speech text display
                            if (_speechText.isNotEmpty) ...[
                              SizedBox(height: padding),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(padding * 0.75),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.format_quote,
                                          color: Colors.grey.shade600,
                                          size: isLargeScreen ? 18 : 16,
                                        ),
                                        SizedBox(width: padding * 0.25),
                                        Text(
                                          'Your request:',
                                          style: TextStyle(
                                            fontSize: isVeryLargeScreen
                                                ? 14
                                                : isLargeScreen
                                                ? 13
                                                : 12,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: padding * 0.5),
                                    Text(
                                      _speechText,
                                      style: TextStyle(
                                        fontSize: isVeryLargeScreen
                                            ? 16
                                            : isLargeScreen
                                            ? 15
                                            : 14,
                                        color: Colors.grey.shade800,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            SizedBox(height: padding),

                            // Instructions
                            Text(
                              _isListening
                                  ? 'Speak clearly and mention guest name, room preference, and dates'
                                  : _isSpeaking
                                  ? 'Please wait while I respond...'
                                  : _isProcessing
                                  ? 'Analyzing your request...'
                                  : 'Tap the microphone to start voice booking',
                              style: TextStyle(
                                fontSize: isVeryLargeScreen
                                    ? 14
                                    : isLargeScreen
                                    ? 13
                                    : 12,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: padding * 1.5),

                      // Control Buttons
                      Wrap(
                        spacing: padding,
                        runSpacing: padding * 0.75,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : (_isListening
                                      ? _stopVoiceBooking
                                      : _startVoiceBooking),
                            icon: Icon(
                              _isListening ? Icons.stop : Icons.mic,
                              size: isVeryLargeScreen
                                  ? 24
                                  : isLargeScreen
                                  ? 22
                                  : 20,
                            ),
                            label: Text(
                              _isListening
                                  ? 'Stop Listening'
                                  : 'Start Voice Booking',
                              style: TextStyle(
                                fontSize: isVeryLargeScreen
                                    ? 16
                                    : isLargeScreen
                                    ? 14
                                    : 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isListening
                                  ? Colors.red
                                  : Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: padding * 1.25,
                                vertical: padding * 0.75,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 8,
                            ),
                          ),

                          if (_speechText.isNotEmpty && !_isProcessing)
                            ElevatedButton.icon(
                              onPressed: _processVoiceInput,
                              icon: Icon(
                                Icons.send,
                                size: isVeryLargeScreen
                                    ? 24
                                    : isLargeScreen
                                    ? 22
                                    : 20,
                              ),
                              label: Text(
                                'Process Request',
                                style: TextStyle(
                                  fontSize: isVeryLargeScreen
                                      ? 16
                                      : isLargeScreen
                                      ? 14
                                      : 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: padding * 1.25,
                                  vertical: padding * 0.75,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 8,
                              ),
                            ),
                        ],
                      ),

                      // Suggestion Card
                      if (_lastSuggestion != null) ...[
                        SizedBox(height: padding * 1.5),
                        _buildSuggestionCard(
                          _lastSuggestion!,
                          isLargeScreen,
                          isVeryLargeScreen,
                          padding,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build suggestion card with responsive design
  Widget _buildSuggestionCard(
    BookingSuggestion suggestion,
    bool isLargeScreen,
    bool isVeryLargeScreen,
    double padding,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: isVeryLargeScreen
                    ? 28
                    : isLargeScreen
                    ? 24
                    : 20,
              ),
              SizedBox(width: padding * 0.5),
              Expanded(
                child: Text(
                  'Booking Suggestion',
                  style: TextStyle(
                    fontSize: isVeryLargeScreen
                        ? 20
                        : isLargeScreen
                        ? 18
                        : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: padding),

          _buildSuggestionRow(
            'Guest:',
            suggestion.guestName,
            isLargeScreen,
            isVeryLargeScreen,
          ),
          _buildSuggestionRow(
            'Room Type:',
            suggestion.roomType ?? 'Standard',
            isLargeScreen,
            isVeryLargeScreen,
          ),
          _buildSuggestionRow(
            'Check-in:',
            _formatDate(suggestion.checkInDate.toString()),
            isLargeScreen,
            isVeryLargeScreen,
          ),
          _buildSuggestionRow(
            'Check-out:',
            _formatDate(suggestion.checkOutDate.toString()),
            isLargeScreen,
            isVeryLargeScreen,
          ),

          if (suggestion.notes.isNotEmpty)
            _buildSuggestionRow(
              'Notes:',
              suggestion.notes,
              isLargeScreen,
              isVeryLargeScreen,
            ),

          SizedBox(height: padding * 1.25),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.onBookingSuggestion(suggestion),
                  icon: Icon(
                    Icons.check,
                    size: isVeryLargeScreen
                        ? 22
                        : isLargeScreen
                        ? 20
                        : 18,
                  ),
                  label: Text(
                    'Accept Booking',
                    style: TextStyle(
                      fontSize: isVeryLargeScreen
                          ? 16
                          : isLargeScreen
                          ? 14
                          : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: padding * 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                  ),
                ),
              ),
              SizedBox(width: padding),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _lastSuggestion = null;
                      _speechText = '';
                      _statusMessage =
                          'Tap the microphone to start voice booking';
                    });
                  },
                  icon: Icon(
                    Icons.edit,
                    size: isVeryLargeScreen
                        ? 22
                        : isLargeScreen
                        ? 20
                        : 18,
                  ),
                  label: Text(
                    'Modify',
                    style: TextStyle(
                      fontSize: isVeryLargeScreen
                          ? 16
                          : isLargeScreen
                          ? 14
                          : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue, width: 2),
                    padding: EdgeInsets.symmetric(vertical: padding * 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionRow(
    String label,
    String value,
    bool isLargeScreen,
    bool isVeryLargeScreen,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isVeryLargeScreen
                ? 120
                : isLargeScreen
                ? 110
                : 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isVeryLargeScreen
                    ? 15
                    : isLargeScreen
                    ? 14
                    : 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isVeryLargeScreen
                    ? 15
                    : isLargeScreen
                    ? 14
                    : 12,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
