import 'package:flutter/material.dart';
import '../models/food_item.dart';

/// Reusable card widget for displaying a food item
class FoodItemCard extends StatelessWidget {
  final FoodItem foodItem;
  final bool isSelected;
  final bool isDisabled;
  final ValueChanged<bool?>? onChanged;

  const FoodItemCard({
    super.key,
    required this.foodItem,
    this.isSelected = false,
    this.isDisabled = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isDisabled ? 1 : 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isDisabled || onChanged == null
            ? null
            : () => onChanged!(!isSelected),
        child: Opacity(
          opacity: isDisabled ? 0.4 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Food image placeholder
                _buildFoodImage(),
                const SizedBox(width: 16),

                // Food name and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food name
                      Text(
                        foodItem.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Food description
                      Text(
                        foodItem.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Food cost
                      Text(
                        '\$${foodItem.cost.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkbox
                if (onChanged != null)
                  Checkbox(
                    value: isSelected,
                    onChanged: isDisabled ? null : onChanged,
                    activeColor: Colors.deepOrange,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build placeholder food image
  Widget _buildFoodImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.fastfood,
        size: 40,
        color: Colors.deepOrange,
      ),
    );
  }
}
