import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../products/domain/product.dart';
import '../domain/inventory_report.dart';

class ExportService {
  Future<void> shareInventory(
    InventoryReport report,
    String currency,
    Rect origin,
  ) async {
    final bytes = Uint8List.fromList(utf8.encode(report.csv(currency)));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'text/csv')],
        fileNameOverrides: [
          'inventario-${DateTime.now().toIso8601String().split('T').first}.csv',
        ],
        title: 'Inventario',
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<Uint8List> label(Product product) async {
    final font = pw.Font.ttf(await rootBundle.load('assets/fonts/Manrope.ttf'));
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          100 * PdfPageFormat.mm,
          130 * PdfPageFormat.mm,
          marginAll: 8 * PdfPageFormat.mm,
        ),
        theme: pw.ThemeData.withFont(base: font),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            pw.Text(
              product.name,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              product.category,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: product.code,
              width: 220,
              height: 65,
            ),
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: product.code,
              width: 110,
              height: 110,
            ),
            pw.Text(product.code, style: const pw.TextStyle(fontSize: 14)),
            pw.Text(
              'Consulta las existencias en Trazal',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }
}
