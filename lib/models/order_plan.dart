import 'food_item.dart';

/// Model class representing a saved order plan
class OrderPlan {
  final int? id;
  final DateTime date;
  final double targetCost;
  final List<FoodItem> foodItems;

  OrderPlan({
    this.id,
    required this.date,
    required this.targetCost,
    required this.foodItems,
  });

  /// Calculate total cost of all items in the order
  double get totalCost {
    return foodItems.fold(0.0, (sum, item) => sum + item.cost);
  }

  /// Create OrderPlan from database map
  factory OrderPlan.fromMap(Map<String, dynamic> map, List<FoodItem> items) {
    return OrderPlan(
      id: map['id'],
      date: DateTime.parse(map['date']),
      targetCost: map['targetCost'],
      foodItems: items,
    );
  }

  /// Convert OrderPlan to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'targetCost': targetCost,
    };
  }
}
