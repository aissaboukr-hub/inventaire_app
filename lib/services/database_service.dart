// lib/services/database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._();
  
  factory DatabaseService() => _instance;
  DatabaseService._();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  /// Initialiser la base de données
  Future<Database> _init() async {
    String path = join(await getDatabasesPath(), 'inventory.db');
    
    return openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT NOT NULL,
            designation TEXT NOT NULL,
            barcode TEXT UNIQUE NOT NULL,
            price REAL NOT NULL,
            quantity INTEGER DEFAULT 0
          )
        ''');
      },
      version: 1,
    );
  }

  /// Insérer un produit
  Future<int> insertProduct(Product product) async {
    try {
      final dbClient = await db;
      return await dbClient.insert(
        'products',
        product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Erreur insertion : $e');
      return -1;
    }
  }

  /// Récupérer tous les produits
  Future<List<Product>> getProducts() async {
    try {
      final dbClient = await db;
      final maps = await dbClient.query('products');
      return maps.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      print('Erreur récupération : $e');
      return [];
    }
  }

  /// Récupérer un produit par code-barres
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final dbClient = await db;
      final maps = await dbClient.query(
        'products',
        where: 'barcode = ?',
        whereArgs: [barcode],
      );
      if (maps.isNotEmpty) {
        return Product.fromMap(maps.first);
      }
    } catch (e) {
      print('Erreur recherche barcode : $e');
    }
    return null;
  }

  /// Mettre à jour la quantité d'un produit
  Future<int> updateQuantity(String barcode, int quantity) async {
    try {
      final dbClient = await db;
      return await dbClient.update(
        'products',
        {'quantity': quantity},
        where: 'barcode = ?',
        whereArgs: [barcode],
      );
    } catch (e) {
      print('Erreur MAJ quantité : $e');
      return -1;
    }
  }

  /// Incrémenter la quantité
  Future<int> incrementQuantity(String barcode) async {
    Product? product = await getProductByBarcode(barcode);
    if (product != null) {
      return await updateQuantity(barcode, product.quantity + 1);
    }
    return -1;
  }

  /// Supprimer un produit
  Future<int> deleteProduct(String barcode) async {
    try {
      final dbClient = await db;
      return await dbClient.delete(
        'products',
        where: 'barcode = ?',
        whereArgs: [barcode],
      );
    } catch (e) {
      print('Erreur suppression : $e');
      return -1;
    }
  }

  /// Effacer toute la base de données
  Future<void> clearDatabase() async {
    try {
      final dbClient = await db;
      await dbClient.delete('products');
    } catch (e) {
      print('Erreur clear DB : $e');
    }
  }

  /// Fermer la base de données
  Future<void> close() async {
    final dbClient = await db;
    await dbClient.close();
  }
}