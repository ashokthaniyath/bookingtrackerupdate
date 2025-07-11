import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../providers/resort_data_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class InvoiceCard extends StatelessWidget {
  final Booking booking;

  const InvoiceCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Consumer<ResortDataProvider>(
      builder: (context, provider, _) {
        // Calculate the total amount for this booking
        final payments = provider.payments
            .where((p) => p.guest.name == booking.guest.name)
            .toList();

        final totalAmount = payments.fold<double>(
          0.0,
          (sum, payment) => sum + payment.amount,
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Invoice #${booking.id?.substring(0, 8).toUpperCase() ?? 'NEW'}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Chip(
                      label: Text(
                        booking.paymentStatus,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: booking.paymentStatus == 'Paid'
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      booking.guest.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.hotel, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Room ${booking.room.number} (${booking.room.type})',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('MMM dd').format(booking.checkIn)} - ${DateFormat('MMM dd, yyyy').format(booking.checkOut)}',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '\$${totalAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                if (payments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Payments:',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  ...payments
                      .take(2)
                      .map(
                        (payment) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM dd, yyyy').format(payment.date),
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              Text(
                                '\$${payment.amount.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (payments.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '... and ${payments.length - 2} more',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
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
}
