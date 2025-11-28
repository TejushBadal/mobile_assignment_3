import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_item.dart';
import '../models/order_plan.dart';
import '../data/dummy_data.dart';

/// Database helper class for managing SQLite database operations
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Get database instance (initialize if not exists)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('food_ordering.db');
    return _database!;
  }

  /// Initialize database and create tables
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Create database tables
  Future<void> _createDB(Database db, int version) async {
    // Create food_items table
    await db.execute('''
      CREATE TABLE food_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        cost REAL NOT NULL,
        imagePath TEXT
      )
    ''');

    // Create order_plans table
    await db.execute('''
      CREATE TABLE order_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        targetCost REAL NOT NULL
      )
    ''');

    // Create order_items junction table (links order_plans to food_items)
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderPlanId INTEGER NOT NULL,
        foodItemId INTEGER NOT NULL,
        FOREIGN KEY (orderPlanId) REFERENCES order_plans (id) ON DELETE CASCADE,
        FOREIGN KEY (foodItemId) REFERENCES food_items (id) ON DELETE CASCADE
      )
    ''');

    // Pre-populate food items from dummy data
    await _populateFoodItems(db);
  }

  /// Pre-populate database with default food items
  Future<void> _populateFoodItems(Database db) async {
    for (var item in dummyFoodItems) {
      await db.insert('food_items', {
        'name': item.name,
        'description': item.description,
        'cost': item.cost,
        'imagePath': item.imagePath,
      });
    }
  }

  // ==================== FOOD ITEMS OPERATIONS ====================

  /// Get all food items from database
  Future<List<FoodItem>> getAllFoodItems() async {
    final db = await database;
    final result = await db.query('food_items', orderBy: 'name ASC');
    return result.map((json) => FoodItem.fromMap(json)).toList();
  }

  /// Get a specific food item by ID
  Future<FoodItem?> getFoodItem(int id) async {
    final db = await database;
    final result = await db.query(
      'food_items',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return FoodItem.fromMap(result.first);
    }
    return null;
  }

  // ==================== ORDER PLANS OPERATIONS ====================

  /// Create a new order plan
  Future<int> createOrderPlan(OrderPlan orderPlan) async {
    final db = await database;

    // Insert order plan
    final orderPlanId = await db.insert('order_plans', {
      'date': orderPlan.date.toIso8601String(),
      'targetCost': orderPlan.targetCost,
    });

    // Insert order items (food items in this order)
    for (var foodItem in orderPlan.foodItems) {
      await db.insert('order_items', {
        'orderPlanId': orderPlanId,
        'foodItemId': foodItem.id,
      });
    }

    return orderPlanId;
  }

  /// Get all order plans
  Future<List<OrderPlan>> getAllOrderPlans() async {
    final db = await database;
    final result = await db.query('order_plans', orderBy: 'date DESC');

    List<OrderPlan> orderPlans = [];
    for (var orderPlanMap in result) {
      final foodItems = await _getFoodItemsForOrder(orderPlanMap['id'] as int);
      orderPlans.add(OrderPlan.fromMap(orderPlanMap, foodItems));
    }

    return orderPlans;
  }

  /// Get order plans for a specific date
  Future<List<OrderPlan>> getOrderPlansByDate(DateTime date) async {
    final db = await database;

    // Format date to match only the date part (ignore time)
    final dateStr = date.toIso8601String().split('T')[0];

    final result = await db.query(
      'order_plans',
      where: 'date LIKE ?',
      whereArgs: ['$dateStr%'],
      orderBy: 'date DESC',
    );

    List<OrderPlan> orderPlans = [];
    for (var orderPlanMap in result) {
      final foodItems = await _getFoodItemsForOrder(orderPlanMap['id'] as int);
      orderPlans.add(OrderPlan.fromMap(orderPlanMap, foodItems));
    }

    return orderPlans;
  }

  /// Get a specific order plan by ID
  Future<OrderPlan?> getOrderPlan(int id) async {
    final db = await database;
    final result = await db.query(
      'order_plans',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      final foodItems = await _getFoodItemsForOrder(id);
      return OrderPlan.fromMap(result.first, foodItems);
    }
    return null;
  }

  /// Update an existing order plan
  Future<int> updateOrderPlan(OrderPlan orderPlan) async {
    final db = await database;

    // Update order plan details
    await db.update(
      'order_plans',
      {
        'date': orderPlan.date.toIso8601String(),
        'targetCost': orderPlan.targetCost,
      },
      where: 'id = ?',
      whereArgs: [orderPlan.id],
    );

    // Delete existing order items
    await db.delete(
      'order_items',
      where: 'orderPlanId = ?',
      whereArgs: [orderPlan.id],
    );

    // Insert updated order items
    for (var foodItem in orderPlan.foodItems) {
      await db.insert('order_items', {
        'orderPlanId': orderPlan.id,
        'foodItemId': foodItem.id,
      });
    }

    return orderPlan.id!;
  }

  /// Delete an order plan
  Future<int> deleteOrderPlan(int id) async {
    final db = await database;

    // Delete order items first (foreign key constraint)
    await db.delete(
      'order_items',
      where: 'orderPlanId = ?',
      whereArgs: [id],
    );

    // Delete order plan
    return await db.delete(
      'order_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== HELPER METHODS ====================

  /// Get food items for a specific order plan
  Future<List<FoodItem>> _getFoodItemsForOrder(int orderPlanId) async {
    final db = await database;

    // Join order_items with food_items to get all food items for this order
    final result = await db.rawQuery('''
      SELECT f.* FROM food_items f
      INNER JOIN order_items oi ON f.id = oi.foodItemId
      WHERE oi.orderPlanId = ?
    ''', [orderPlanId]);

    return result.map((json) => FoodItem.fromMap(json)).toList();
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
