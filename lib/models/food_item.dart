/// Model class representing a food item in the menu
class FoodItem {
  final int? id;
  final String name;
  final String description;
  final double cost;
  final String? imagePath; // Path to food image (optional)

  FoodItem({
    this.id,
    required this.name,
    required this.description,
    required this.cost,
    this.imagePath,
  });

  /// Create FoodItem from database map
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      cost: map['cost'],
      imagePath: map['imagePath'],
    );
  }

  /// Convert FoodItem to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cost': cost,
      'imagePath': imagePath,
    };
  }
}
