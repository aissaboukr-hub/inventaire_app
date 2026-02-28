// lib/services/excel_service.dart

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';
import 'database_service.dart';

class ExcelService {
  final DatabaseService _db = DatabaseService();

  /// Importer depuis un fichier Excel
  Future<Map<String, dynamic>> importFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null) {
        return {'success': false, 'message': 'Aucun fichier sélectionné'};
      }

      var bytes = File(result.files.single.path!).readAsBytesSync();
      Excel excel = Excel.decodeBytes(bytes);

      int imported = 0;
      int errors = 0;

      for (var table in excel.tables.keys) {
        var rows = excel.tables[table]!.rows;
        
        // Sauter l'en-tête (première ligne)
        for (int i = 1; i < rows.length; i++) {
          try {
            var row = rows[i];
            
            if (row.length < 4) continue; // Ignorer les lignes incomplètes
            
            final code = row[0]?.value?.toString().trim() ?? '';
            final designation = row[1]?.value?.toString().trim() ?? '';
            final barcode = row[2]?.value?.toString().trim() ?? '';
            final priceStr = row[3]?.value?.toString().trim() ?? '0';
            
            if (code.isEmpty || barcode.isEmpty) continue;
            
            final price = double.tryParse(priceStr) ?? 0.0;

            final product = Product(
              code: code,
              designation: designation,
              barcode: barcode,
              price: price,
              quantity: 0,
            );

            int result = await _db.insertProduct(product);
            if (result > 0) {
              imported++;
            }
          } catch (e) {
            print('Erreur ligne $i: $e');
            errors++;
          }
        }
      }

      return {
        'success': true,
        'message': 'Import réussi: $imported produits importés, $errors erreurs'
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur import: $e'};
    }
  }

  /// Exporter les produits vers Excel
  Future<Map<String, dynamic>> exportToExcel() async {
    try {
      List<Product> products = await _db.getProducts();

      if (products.isEmpty) {
        return {'success': false, 'message': 'Aucun produit à exporter'};
      }

      // Créer un nouveau fichier Excel
      Excel excel = Excel.createExcel();
      Sheet sheet = excel['Inventaire'];

      // Ajouter l'en-tête
      sheet.appendRow([
        'Code produit',
        'Désignation',
        'Code-barres',
        'Prix',
        'Quantité réelle'
      ]);

      // Ajouter les produits
      for (var product in products) {
        sheet.appendRow([
          product.code,
          product.designation,
          product.barcode,
          product.price,
          product.quantity,
        ]);
      }

      // Sauvegarder le fichier
      String? dir = (await getExternalStorageDirectory())?.path;
      
      if (dir == null) {
        return {'success': false, 'message': 'Accès au stockage impossible'};
      }

      String fileName = 'inventaire_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      String filePath = '$dir/$fileName';

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.save()!);

      return {
        'success': true,
        'message': 'Export réussi',
        'filePath': filePath,
        'fileName': fileName
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur export: $e'};
    }
  }
}