import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/voice_ai_service.dart';
import '../services/vertex_ai_service.dart';

import '../models/guest.dart';
import '../models/room.dart';

/// Voice-enabled booking widget with speech recognition and audio feedback
class VoiceBookingWidget extends StatefulWidget {
  final List<Room> availableRooms;
  final List<Guest> existingGuests;
  final Function(BookingSuggestion) onBookingSuggestion;
  final VoidCallback? onClose;

  const VoiceBookingWidget({
    Key? key,
    required this.availableRooms,
    required this.existingGuests,
    required this.onBookingSuggestion,
    this.onClose,
  }) : super(key: key);

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
    VoiceAIService.stop();
    super.dispose();
  }

  Future<void> _startVoiceBooking() async {
    if (_isListening || _isSpeaking || _isProcessing) return;

    try {
      setState(() {
        _isProcessing = true;
        _statusMessage = 'Initializing voice assistant...';
        _speechText = '';
      });

      // Initialize voice service if needed
      final initialized = await VoiceAIService.initialize();
      if (!initialized) {
        _showError(
          'Voice assistant not available. Please check microphone permissions.',
        );
        return;
      }

      // Start listening
      await VoiceAIService.startListening();

      // Vibrate for feedback
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showError('Error starting voice booking: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _stopVoiceBooking() async {
    await VoiceAIService.stop();
    setState(() {
      _statusMessage = 'Voice booking stopped';
    });
  }

  Future<void> _processVoiceInput() async {
    if (_speechText.trim().isEmpty) return;

    try {
      setState(() {
        _isProcessing = true;
        _statusMessage = 'Processing with enhanced date recognition...';
      });

      // Use the enhanced Calendar AI processing
      final suggestion = await VoiceAIService.processVoiceBookingWithCalendarAI(
        _speechText,
        widget.availableRooms,
        widget.existingGuests,
      );

      if (suggestion != null && !suggestion.isError) {
        setState(() {
          _statusMessage = 'Smart booking suggestion ready!';
        });

        // Show enhanced confirmation dialog with Calendar AI details
        final confirmed = await _showEnhancedBookingConfirmation(suggestion);
        if (confirmed) {
          widget.onBookingSuggestion(suggestion);
        }
      } else {
        _showError(
          'Could not process your booking request. Please try again with different wording.',
        );
      }
    } catch (e) {
      _showError('Error processing voice input: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Enhanced booking confirmation dialog with Calendar AI insights
  Future<bool> _showEnhancedBookingConfirmation(
    BookingSuggestion suggestion,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.blue.shade400],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Smart Booking Suggestion',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfirmationDetail(
                    'Guest',
                    suggestion.guestName,
                    Icons.person,
                  ),
                  _buildConfirmationDetail(
                    'Room Type',
                    suggestion.roomType ?? 'Any Available',
                    Icons.hotel,
                  ),
                  _buildConfirmationDetail(
                    'Check-in',
                    _formatDate(suggestion.checkInDate),
                    Icons.login,
                  ),
                  _buildConfirmationDetail(
                    'Check-out',
                    _formatDate(suggestion.checkOutDate),
                    Icons.logout,
                  ),
                  _buildConfirmationDetail(
                    'Duration',
                    '${suggestion.checkOutDate.difference(suggestion.checkInDate).inDays} nights',
                    Icons.schedule,
                  ),
                  if (suggestion.confidence > 0.7)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.green.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'High confidence booking with enhanced date recognition',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (suggestion.notes.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        suggestion.notes,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Confirm Booking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showBookingConfirmation(BookingSuggestion suggestion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.record_voice_over, color: Colors.blue),
            SizedBox(width: 8),
            Text('Voice Booking Confirmation'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'I understood:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildConfirmationItem('Guest', suggestion.guestName),
            _buildConfirmationItem(
              'Room Type',
              suggestion.roomType ?? 'Standard',
            ),
            _buildConfirmationItem(
              'Check-in',
              _formatDate(suggestion.checkInDate),
            ),
            _buildConfirmationItem(
              'Check-out',
              _formatDate(suggestion.checkOutDate),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.mic, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can also use voice commands: Say "yes" to confirm or "no" to cancel.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final voiceConfirmed =
                      await VoiceAIService.confirmBookingByVoice();
                  Navigator.of(context).pop(voiceConfirmed);
                },
                icon: const Icon(Icons.mic),
                tooltip: 'Use Voice',
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Widget _buildConfirmationItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  /// Helper method to build confirmation detail rows
  Widget _buildConfirmationDetail(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: Colors.blue.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    setState(() {
      _statusMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _startVoiceBooking,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.record_voice_over,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Voice Booking Assistant',
                  style: TextStyle(
                    fontSize: 20,
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
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Voice Input Visualization
          Center(
            child: GestureDetector(
              onTap: _isListening ? _stopVoiceBooking : _startVoiceBooking,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Wave animation background
                  if (_isListening)
                    AnimatedBuilder(
                      animation: _waveAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 140 + (_waveAnimation.value * 40),
                          height: 140 + (_waveAnimation.value * 40),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(
                              0.1 - (_waveAnimation.value * 0.05),
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
                        scale: _isListening ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isListening
                                  ? [Colors.red.shade400, Colors.red.shade600]
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
                                color: (_isListening ? Colors.red : Colors.blue)
                                    .withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
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
                            size: 50,
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

          const SizedBox(height: 20),

          // Status Message
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // Speech Text Display
          if (_speechText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_quote,
                        color: Colors.grey.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your request:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _speechText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_isProcessing)
                    ElevatedButton.icon(
                      onPressed: _processVoiceInput,
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Process Request'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await VoiceAIService.speakHelp();
                  },
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Help'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await VoiceAIService.testVoice();
                  },
                  icon: const Icon(Icons.mic_external_on),
                  label: const Text('Test Voice'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Voice Commands Help
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Voice Commands:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• "Book a room for John from tomorrow to Friday"\n'
                  '• "I need a deluxe room for 3 nights starting Monday"\n'
                  '• "Reserve a suite for Sarah checking in today"',
                  style: TextStyle(fontSize: 11, color: Colors.amber.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
