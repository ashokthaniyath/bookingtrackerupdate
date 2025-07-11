import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarBookingModal extends StatelessWidget {
  final DateTime date;
  const CalendarBookingModal({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bookings for ${date.day}/${date.month}/${date.year}',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            itemCount: 2,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, i) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple[100 * (i + 2)],
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF7C3AED),
                ),
              ),
              title: Text(
                'Guest ${i + 1}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Room ${101 + i} • 12/7 - 14/7'),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Colors.grey[400],
              ),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
