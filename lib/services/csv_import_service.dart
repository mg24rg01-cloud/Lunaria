import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/schema.dart';

class CSVImportService {
  static final CSVImportService _instance = CSVImportService._internal();
  factory CSVImportService() => _instance;
  CSVImportService._internal();

  Future<List<Entry>> importCSV({required String notebookId, required String accountId}) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) return [];

    final file = File(result.files.single.path!);
    final csvString = await file.readAsString(encoding: utf8);
    final fields = csv.decode(csvString);

    if (fields.isEmpty) return [];

    // Intentar encontrar los índices de las columnas
    int dateIdx = -1;
    int descIdx = -1;
    int amountIdx = -1;

    // Buscamos en la primera fila (encabezados)
    List<dynamic> headers = fields[0];
    for (int i = 0; i < headers.length; i++) {
      String header = headers[i].toString().toLowerCase();
      if (header.contains('fecha') || header.contains('date')) dateIdx = i;
      if (header.contains('concepto') || header.contains('descrip') || header.contains('detail')) descIdx = i;
      if (header.contains('monto') || header.contains('importe') || header.contains('amount') || header.contains('valor')) amountIdx = i;
    }

    // Si no se encontraron por nombre, asumimos un orden común o fallamos
    if (dateIdx == -1 || descIdx == -1 || amountIdx == -1) {
      // Intento manual por tipos de datos en la segunda fila si existe
      if (fields.length > 1) {
         for(int i = 0; i < fields[1].length; i++) {
           var val = fields[1][i];
           if (dateIdx == -1 && _isDate(val.toString())) dateIdx = i;
           if (amountIdx == -1 && _isNumeric(val.toString())) amountIdx = i;
         }
         // El que sobra que no es fecha ni monto suele ser la descripción
         for(int i = 0; i < fields[1].length; i++) {
           if (i != dateIdx && i != amountIdx && descIdx == -1) descIdx = i;
         }
      }
    }

    if (dateIdx == -1 || descIdx == -1 || amountIdx == -1) {
      throw Exception('No se pudo identificar el formato del CSV. Asegúrate de que tenga columnas de Fecha, Concepto y Monto.');
    }

    List<Entry> importedEntries = [];
    final DateFormat formatter = DateFormat('dd/MM/yyyy'); // Formato común, se podría mejorar

    // Procesar filas (saltando el encabezado)
    for (int i = 1; i < fields.length; i++) {
      List<dynamic> row = fields[i];
      if (row.length <= [dateIdx, descIdx, amountIdx].reduce((a, b) => a > b ? a : b)) continue;

      try {
        String rawDate = row[dateIdx].toString();
        DateTime date = _parseDate(rawDate);
        String description = row[descIdx].toString();
        double amount = _parseAmount(row[amountIdx].toString());

        if (amount == 0) continue; // Ignorar transacciones de 0

        final entry = Entry(
          id: 'csv_${DateTime.now().millisecondsSinceEpoch}_$i',
          notebookId: notebookId,
          accountId: accountId,
          type: amount > 0 ? 'income' : 'expense',
          amount: amount.abs(),
          categoryId: 'c8', // Por defecto "Otros"
          date: date,
          notes: description,
          tags: ['Importado'],
        );

        importedEntries.add(entry);
      } catch (e) {
        print('Error procesando fila $i: $e');
      }
    }

    return importedEntries;
  }

  bool _isDate(String input) {
    try {
      _parseDate(input);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isNumeric(String input) {
    if (input.isEmpty) return false;
    final n = num.tryParse(input.replaceAll(',', '').replaceAll('\$', ''));
    return n != null;
  }

  DateTime _parseDate(String input) {
    // Intentar varios formatos comunes
    List<String> formats = [
      'dd/MM/yyyy',
      'yyyy-MM-dd',
      'MM/dd/yyyy',
      'dd-MM-yyyy',
      'dd/MM/yy',
    ];

    for (var f in formats) {
      try {
        return DateFormat(f).parse(input);
      } catch (_) {}
    }
    
    // Si falla, intentar parseo directo de DateTime
    return DateTime.parse(input);
  }

  double _parseAmount(String input) {
    String clean = input.replaceAll('\$', '').replaceAll(',', '').trim();
    // Manejar paréntesis para negativos: (100.00) -> -100.00
    if (clean.startsWith('(') && clean.endsWith(')')) {
      clean = '-${clean.substring(1, clean.length - 1)}';
    }
    return double.parse(clean);
  }
}
