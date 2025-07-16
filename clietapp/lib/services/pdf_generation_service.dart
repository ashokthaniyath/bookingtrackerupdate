import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;
import '../models/booking.dart';
import '../models/payment.dart';

/// PDF Generation Service for Invoices
/// Provides functionality to generate and save invoices as PDF files
class PDFGenerationService {
  /// Generate an invoice PDF for a booking
  static Future<Uint8List> generateInvoicePDF({
    required Booking booking,
    required Payment payment,
    String? logoPath,
    Map<String, dynamic>? resortInfo,
  }) async {
    final pdf = pw.Document();

    // Default resort information
    final resort =
        resortInfo ??
        {
          'name': 'Resort Paradise',
          'address': '123 Beach Road, Paradise Island',
          'phone': '+91-555-RESORT',
          'email': 'info@resortparadise.com',
          'website': 'www.resortparadise.com',
        };

    // Calculate invoice details
    final checkInDate = booking.checkIn;
    final checkOutDate = booking.checkOut;
    final numberOfNights = checkOutDate.difference(checkInDate).inDays;
    final roomRate = _getRoomRate(booking.room.type);
    final subtotal = roomRate * numberOfNights;
    final taxes = subtotal * 0.12; // 12% tax
    final total = subtotal + taxes;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(resort),
              pw.SizedBox(height: 30),

              // Invoice title and details
              _buildInvoiceTitle(booking),
              pw.SizedBox(height: 30),

              // Guest and booking information
              _buildGuestInfo(booking),
              pw.SizedBox(height: 20),

              // Invoice items table
              _buildInvoiceTable(
                booking,
                roomRate,
                numberOfNights,
                subtotal,
                taxes,
                total,
              ),
              pw.SizedBox(height: 30),

              // Payment information
              _buildPaymentInfo(payment),
              pw.SizedBox(height: 30),

              // Footer
              _buildFooter(resort),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Build PDF header
  static pw.Widget _buildHeader(Map<String, dynamic> resort) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              resort['name'] ?? 'Resort Paradise',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              resort['address'] ?? '',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              'Phone: ${resort['phone'] ?? ''}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              'Email: ${resort['email'] ?? ''}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
        pw.Container(
          width: 80,
          height: 80,
          decoration: pw.BoxDecoration(
            color: PdfColors.blue100,
            borderRadius: pw.BorderRadius.circular(40),
          ),
          child: pw.Center(
            child: pw.Text(
              'LOGO',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build invoice title section
  static pw.Widget _buildInvoiceTitle(Booking booking) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Invoice #: INV-${booking.id?.substring(0, 8).toUpperCase() ?? 'UNKNOWN'}',
              style: const pw.TextStyle(fontSize: 14),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Date: ${_formatDate(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              'Due Date: ${_formatDate(booking.checkOut)}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  /// Build guest information section
  static pw.Widget _buildGuestInfo(Booking booking) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BILL TO:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                booking.guest.name,
                style: const pw.TextStyle(fontSize: 12),
              ),
              if (booking.guest.email != null)
                pw.Text(
                  booking.guest.email!,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              if (booking.guest.phone != null)
                pw.Text(
                  booking.guest.phone!,
                  style: const pw.TextStyle(fontSize: 12),
                ),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BOOKING DETAILS:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Room: ${booking.room.number} (${booking.room.type})',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Check-in: ${_formatDate(booking.checkIn)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Check-out: ${_formatDate(booking.checkOut)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Nights: ${booking.checkOut.difference(booking.checkIn).inDays}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build invoice table
  static pw.Widget _buildInvoiceTable(
    Booking booking,
    double roomRate,
    int numberOfNights,
    double subtotal,
    double taxes,
    double total,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _buildTableCell('Description', isHeader: true),
            _buildTableCell('Nights', isHeader: true),
            _buildTableCell('Rate', isHeader: true),
            _buildTableCell('Amount', isHeader: true),
          ],
        ),
        // Room charge row
        pw.TableRow(
          children: [
            _buildTableCell('${booking.room.type} Room ${booking.room.number}'),
            _buildTableCell(numberOfNights.toString()),
            _buildTableCell('${roomRate.toStringAsFixed(2)}'),
            _buildTableCell('${subtotal.toStringAsFixed(2)}'),
          ],
        ),
        // Subtotal row
        pw.TableRow(
          children: [
            _buildTableCell(''),
            _buildTableCell(''),
            _buildTableCell('Subtotal:', isHeader: true),
            _buildTableCell('${subtotal.toStringAsFixed(2)}', isHeader: true),
          ],
        ),
        // Tax row
        pw.TableRow(
          children: [
            _buildTableCell(''),
            _buildTableCell(''),
            _buildTableCell('Taxes (12%):', isHeader: true),
            _buildTableCell('${taxes.toStringAsFixed(2)}', isHeader: true),
          ],
        ),
        // Total row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _buildTableCell(''),
            _buildTableCell(''),
            _buildTableCell('TOTAL:', isHeader: true),
            _buildTableCell('${total.toStringAsFixed(2)}', isHeader: true),
          ],
        ),
      ],
    );
  }

  /// Build table cell
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Build payment information section
  static pw.Widget _buildPaymentInfo(Payment payment) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PAYMENT INFORMATION',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Payment Status:',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                payment.status,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: payment.status.toLowerCase() == 'paid'
                      ? PdfColors.green700
                      : PdfColors.orange700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Payment Date:', style: const pw.TextStyle(fontSize: 12)),
              pw.Text(
                _formatDate(payment.date),
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Amount:', style: const pw.TextStyle(fontSize: 12)),
              pw.Text(
                '${payment.amount.toStringAsFixed(2)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build footer
  static pw.Widget _buildFooter(Map<String, dynamic> resort) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for choosing ${resort['name'] ?? 'Resort Paradise'}!',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'We hope you enjoyed your stay. Please contact us for any questions.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Website: ${resort['website'] ?? 'www.resortparadise.com'}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// Save PDF to device (with web support)
  static Future<String> savePDFToFile(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    try {
      if (kIsWeb) {
        // For web platforms - trigger browser download
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = fileName;
        html.document.body?.children.add(anchor);

        // Trigger download
        anchor.click();

        // Clean up
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);

        debugPrint('✅ PDF download triggered for web: $fileName');
        return 'Downloads/$fileName'; // Return a user-friendly path
      } else {
        // For mobile/desktop platforms
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pdfBytes);
        debugPrint('✅ PDF saved to: ${file.path}');
        return file.path;
      }
    } catch (e) {
      debugPrint('❌ Error saving PDF: $e');
      rethrow;
    }
  }

  /// Get room rate based on room type
  static double _getRoomRate(String roomType) {
    switch (roomType.toLowerCase()) {
      case 'suite':
        return 7000.0;
      case 'deluxe':
        return 6000.0;
      case 'standard':
        return 5000.0;
      default:
        return 6500.0;
    }
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Generate invoice for a booking with automatic payment lookup
  static Future<Uint8List> generateBookingInvoice(
    Booking booking,
    List<Payment> payments,
  ) async {
    // Find the payment for this booking/guest
    final payment = payments.firstWhere(
      (p) => p.guest.id == booking.guest.id,
      orElse: () => Payment(
        id: null,
        guest: booking.guest,
        amount:
            _getRoomRate(booking.room.type) *
            booking.checkOut.difference(booking.checkIn).inDays,
        status: 'Pending',
        date: DateTime.now(),
      ),
    );

    return generateInvoicePDF(booking: booking, payment: payment);
  }
}
