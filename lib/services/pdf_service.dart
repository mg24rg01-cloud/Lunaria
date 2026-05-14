import 'dart:io';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/schema.dart';
import '../state/app_state.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateAndSaveReport({
    required DateTime month,
    required List<Entry> allEntries,
    bool share = false,
  }) async {
    final pdf = pw.Document();

    // Data Processing
    final currentMonthEntries = allEntries.where((e) => e.date.year == month.year && e.date.month == month.month).toList();
    final prevMonth = DateTime(month.year, month.month - 1);
    final prevMonthEntries = allEntries.where((e) => e.date.year == prevMonth.year && e.date.month == prevMonth.month).toList();

    double totalIncome = currentMonthEntries.where((e) => e.type == 'income').fold(0.0, (sum, e) => sum + e.amount);
    double totalExpense = currentMonthEntries.where((e) => e.type == 'expense').fold(0.0, (sum, e) => sum + e.amount);
    double totalSavings = totalIncome - totalExpense;
    if (totalSavings < 0) totalSavings = 0;

    // Category mapping
    Map<String, double> catGastos = {};
    for (var e in currentMonthEntries.where((e) => e.type == 'expense')) {
      catGastos[e.categoryId] = (catGastos[e.categoryId] ?? 0) + e.amount;
    }
    final sortedCats = catGastos.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // LIGHT MODE COLORS
    final baseColor = PdfColors.white;
    final textColor = PdfColor.fromHex('#2C2C37');
    final secondaryTextColor = PdfColor.fromHex('#8D8D8D');
    final accentColor = PdfColor.fromHex('#D4A5A5');
    final cardColor = PdfColor.fromHex('#F7F7FB');
    final borderColor = PdfColor.fromHex('#EEEEEE');

    // Font loading with fallback
    pw.ThemeData theme;
    try {
      theme = pw.ThemeData.withFont(
        base: await PdfGoogleFonts.interRegular(),
        bold: await PdfGoogleFonts.interBold(),
      );
    } catch (e) {
      theme = pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            color: baseColor,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Lunaria', style: pw.TextStyle(color: accentColor, fontSize: 32, fontWeight: pw.FontWeight.bold)),
                        pw.Text('REPORTES', style: pw.TextStyle(color: accentColor, fontSize: 12, letterSpacing: 2)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(DateFormat('MMMM yyyy').format(month).toUpperCase(), style: pw.TextStyle(color: textColor, fontSize: 20)),
                        pw.Text('Periodo: 01/${month.month}/${month.year} - ${DateTime(month.year, month.month + 1, 0).day}/${month.month}/${month.year}', 
                          style: pw.TextStyle(color: secondaryTextColor, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(color: borderColor),
                pw.SizedBox(height: 30),

                // Resumen General
                pw.Text('Resumen general', style: pw.TextStyle(color: textColor, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                pw.Row(
                  children: [
                    _buildSummaryCard('Ingresos', totalIncome, accentColor, cardColor, borderColor, textColor, secondaryTextColor, '100%'),
                    pw.SizedBox(width: 12),
                    _buildSummaryCard('Gastos', totalExpense, PdfColor.fromHex('#F49FB6'), cardColor, borderColor, textColor, secondaryTextColor, '${(totalIncome > 0 ? (totalExpense / totalIncome * 100) : 0).toStringAsFixed(1)}%'),
                    pw.SizedBox(width: 12),
                    _buildSummaryCard('Ahorros', totalSavings, PdfColor.fromHex('#81C784'), cardColor, borderColor, textColor, secondaryTextColor, '${(totalIncome > 0 ? (totalSavings / totalIncome * 100) : 0).toStringAsFixed(1)}%'),
                    pw.SizedBox(width: 12),
                    _buildSummaryCard('Balance final', totalIncome - totalExpense, PdfColor.fromHex('#9575CD'), cardColor, borderColor, textColor, secondaryTextColor, ''),
                  ],
                ),
                pw.SizedBox(height: 40),

                // Stats Table
                pw.Text('Gastos por categoría', style: pw.TextStyle(color: textColor, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                ...sortedCats.take(10).map((e) {
                  final cat = AppState().getCategory(e.key);
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    decoration: pw.BoxDecoration(
                      color: cardColor,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: borderColor),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Container(width: 10, height: 10, decoration: pw.BoxDecoration(color: PdfColor.fromInt(cat.color.value), shape: pw.BoxShape.circle)),
                        pw.SizedBox(width: 12),
                        pw.Text(cat.name, style: pw.TextStyle(color: textColor, fontSize: 11)),
                        pw.Spacer(),
                        pw.Text('\$${e.value.toStringAsFixed(2)}', style: pw.TextStyle(color: textColor, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 20),
                        pw.Text('${(totalExpense > 0 ? (e.value / totalExpense * 100) : 0).toStringAsFixed(0)}%', 
                          style: pw.TextStyle(color: secondaryTextColor, fontSize: 11)),
                      ],
                    ),
                  );
                }),
                
                pw.SizedBox(height: 40),

                // Analysis Row
                pw.Text('Análisis del mes', style: pw.TextStyle(color: textColor, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                pw.Row(
                  children: [
                    _buildAnalysisCard('¡Vas por buen camino!', 'Tus gastos disminuyeron comparado con el mes anterior.', cardColor, borderColor, textColor, secondaryTextColor),
                    pw.SizedBox(width: 16),
                    _buildAnalysisCard('Categoría principal', '${sortedCats.isNotEmpty ? AppState().getCategory(sortedCats.first.key).name : 'N/A'} fue tu mayor gasto este mes.', cardColor, borderColor, textColor, secondaryTextColor),
                    pw.SizedBox(width: 16),
                    _buildAnalysisCard('Recomendación', 'Intenta reducir gastos innecesarios para ahorrar más.', cardColor, borderColor, textColor, secondaryTextColor),
                  ],
                ),

                pw.Spacer(),
                // Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(color: accentColor, shape: pw.BoxShape.circle),
                          child: pw.Text('L', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Lunaria', style: pw.TextStyle(color: textColor, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Organiza tus finanzas, alcanza tus metas.', style: pw.TextStyle(color: secondaryTextColor, fontSize: 8)),
                          ],
                        ),
                      ],
                    ),
                    pw.Text('Reporte generado el ${DateFormat('dd/MM/yyyy').format(DateTime.now())}\nPágina 1 de 1', 
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(color: secondaryTextColor, fontSize: 8)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final fileName = 'Reporte_Lunaria_${month.year}_${month.month.toString().padLeft(2, '0')}.pdf';

    if (share) {
      // SHARE FUNCTIONALITY using share_plus for better web support
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: fileName, mimeType: 'application/pdf')],
        text: 'Reporte Mensual de Lunaria - ${DateFormat('MMMM yyyy').format(month)}',
      );
    } else {
      // DOWNLOAD/SAVE FUNCTIONALITY
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: fileName,
      );
    }
  }

  static pw.Widget _buildSummaryCard(String title, double amount, PdfColor color, PdfColor cardColor, PdfColor borderColor, PdfColor textColor, PdfColor secondaryTextColor, String perc) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: cardColor,
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: borderColor),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(color: secondaryTextColor, fontSize: 8)),
            pw.SizedBox(height: 8),
            pw.Text('\$${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}', 
              style: pw.TextStyle(color: color, fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (perc.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(perc, style: pw.TextStyle(color: secondaryTextColor, fontSize: 8)),
            ],
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildAnalysisCard(String title, String desc, PdfColor cardColor, PdfColor borderColor, PdfColor textColor, PdfColor secondaryTextColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        height: 100,
        decoration: pw.BoxDecoration(
          color: cardColor,
          borderRadius: pw.BorderRadius.circular(16),
          border: pw.Border.all(color: borderColor),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(color: textColor, fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text(desc, style: pw.TextStyle(color: secondaryTextColor, fontSize: 8)),
          ],
        ),
      ),
    );
  }
}
