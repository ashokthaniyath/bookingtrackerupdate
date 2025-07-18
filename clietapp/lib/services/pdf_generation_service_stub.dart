// Stub service for PDF generation - production deployment ready
import '../models/booking.dart';
import '../models/payment.dart';

class PDFGenerationService {
  static Future<void> generateInvoicePDF(
    Booking booking,
    Payment payment,
  ) async {
    // TODO: Implement PDF generation when pdf packages are available
    print('PDF generation not available in this build');
  }

  static Future<void> downloadPDF(List<int> pdfBytes, String fileName) async {
    // TODO: Implement PDF download when pdf packages are available
    print('PDF download not available in this build');
  }

  static Future<void> sharePDF(List<int> pdfBytes, String fileName) async {
    // TODO: Implement PDF sharing when pdf packages are available
    print('PDF sharing not available in this build');
  }
}
