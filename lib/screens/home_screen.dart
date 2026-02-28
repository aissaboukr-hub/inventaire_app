// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../services/excel_service.dart';
import '../services/barcode_service.dart';
import '../widgets/product_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  final ExcelService _excelService = ExcelService();
  
  List<Product> scannedProducts = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadScannedProducts();
  }

  /// Charger les produits scannés (quantité > 0)
  Future<void> _loadScannedProducts() async {
    setState(() => isLoading = true);
    try {
      List<Product> allProducts = await _db.getProducts();
      setState(() {
        scannedProducts = allProducts.where((p) => p.quantity > 0).toList();
      });
    } catch (e) {
      print('Erreur chargement: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Scanner un produit
  void _scanProduct() async {
    String? barcode = await BarcodeService.scanBarcode(context);
    
    if (barcode == null) return;

    Product? product = await _db.getProductByBarcode(barcode);

    if (product == null) {
      _showProductNotFoundDialog(barcode);
    } else {
      _showQuantityDialog(product);
    }

    await _loadScannedProducts();
  }

  /// Importer un fichier Excel
  void _importExcel() async {
    setState(() => isLoading = true);
    
    var result = await _excelService.importFromExcel();

    setState(() => isLoading = false);

    if (!mounted) return;

    String message = result['message'] ?? 'Erreur inconnue';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ),
    );

    if (result['success']) {
      await _loadScannedProducts();
    }
  }

  /// Exporter en Excel
  void _exportExcel() async {
    setState(() => isLoading = true);

    var result = await _excelService.exportToExcel();

    setState(() => isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      String filePath = result['filePath'] ?? '';
      String fileName = result['fileName'] ?? 'inventaire.xlsx';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fichier créé: $fileName'),
          backgroundColor: Colors.green,
        ),
      );

      // Proposer le partage
      _showShareOptions(filePath, fileName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur export'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Options de partage
  void _showShareOptions(String filePath, String fileName) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Partager'),
              onTap: () async {
                Navigator.pop(context);
                await Share.shareXFiles(
                  [XFile(filePath)],
                  text: 'Inventaire - $fileName',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_open),
              title: const Text('Voir le fichier'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fichier sauvegardé: $filePath')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog: Produit non trouvé
  void _showProductNotFoundDialog(String barcode) {
    TextEditingController codeCtrl = TextEditingController(text: barcode);
    TextEditingController designationCtrl = TextEditingController();
    TextEditingController priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ Produit non trouvé'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Text('Voulez-vous l\'ajouter manuellement ?'),
              const SizedBox(height: 16),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Code produit',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: designationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Désignation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prix',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              double price = double.tryParse(priceCtrl.text) ?? 0.0;

              Product newProduct = Product(
                code: codeCtrl.text.isEmpty ? barcode : codeCtrl.text,
                designation: designationCtrl.text,
                barcode: barcode,
                price: price,
                quantity: 1,
              );

              await _db.insertProduct(newProduct);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Produit ajouté'),
                  backgroundColor: Colors.green,
                ),
              );

              await _loadScannedProducts();
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  /// Dialog: Saisie quantité
  void _showQuantityDialog(Product product) {
    TextEditingController qtyCtrl = TextEditingController(text: product.quantity.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(product.designation),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Code: ${product.code}', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Text('Prix: ${product.price.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantité réelle',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              int qty = int.tryParse(qtyCtrl.text) ?? 0;
              await _db.updateQuantity(product.barcode, qty);
              Navigator.pop(context);
              await _loadScannedProducts();
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  /// Calculer le total
  double _calculateTotal() {
    return scannedProducts.fold(
      0.0,
      (sum, product) => sum + (product.price * product.quantity),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 Gestion d\'Inventaire'),
        backgroundColor: Colors.deepPurple,
        elevation: 4,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Boutons action
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _importExcel,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Importer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _scanProduct,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Scanner'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exportExcel,
                          icon: const Icon(Icons.download_file),
                          label: const Text('Exporter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Liste produits
                Expanded(
                  child: scannedProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inbox, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text('Aucun produit scanné'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _scanProduct,
                                child: const Text('Commencer le scan'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: scannedProducts.length,
                          itemBuilder: (context, index) {
                            return ProductTile(
                              product: scannedProducts[index],
                              onTap: () => _showQuantityDialog(scannedProducts[index]),
                              onDelete: () async {
                                await _db.deleteProduct(scannedProducts[index].barcode);
                                await _loadScannedProducts();
                              },
                            );
                          },
                        ),
                ),
                // Total
                if (scannedProducts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      border: const Border(top: BorderSide(color: Colors.deepPurple)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${scannedProducts.length} produit(s)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Total: ${_calculateTotal().toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}