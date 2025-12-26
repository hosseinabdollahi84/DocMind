import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  Future<String> extractText(String path) async {
    try {
      final File file = File(path);
      final List<int> bytes = await file.readAsBytes();

      final PdfDocument document = PdfDocument(inputBytes: bytes);

      String text = PdfTextExtractor(document).extractText();

      document.dispose();

      return text;
    } catch (e) {
      throw Exception('Error reading PDF: $e');
    }
  }

  List<String> searchInText(String fullText, String query) {
    if (query.isEmpty) return [];

    final sentences = fullText.split(RegExp(r'[.?!]'));

    final results = sentences.where((sentence) {
      return sentence.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return results.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
}
