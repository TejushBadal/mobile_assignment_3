import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/food_item.dart';
import '../models/order_plan.dart';
import '../widgets/food_item_card.dart';
import '../database/database_helper.dart';

/// Menu screen for creating new order plans
class MenuScreen extends StatefulWidget {
  final OrderPlan? existingOrder; // For editing existing orders

  const MenuScreen({super.key, this.existingOrder});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  double _budget = 50.0;
  DateTime _selectedDate = DateTime.now();
  final Set<int> _selectedFoodIds = {};
  final TextEditingController _budgetController = TextEditingController();

  List<FoodItem> _foodItems = [];
  bool _isLoading = true;
  final _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _budgetController.text = _budget.toStringAsFixed(2);
    _loadFoodItems();

    // If editing an existing order, pre-populate the fields
    if (widget.existingOrder != null) {
      _budget = widget.existingOrder!.targetCost;
      _selectedDate = widget.existingOrder!.date;
      _selectedFoodIds.addAll(
        widget.existingOrder!.foodItems.map((item) => item.id!),
      );
      _budgetController.text = _budget.toStringAsFixed(2);
    }
  }

  /// Load food items from database
  Future<void> _loadFoodItems() async {
    final items = await _dbHelper.getAllFoodItems();
    setState(() {
      _foodItems = items;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  /// Calculate total cost of selected items
  double get _totalCost {
    return _foodItems
        .where((item) => _selectedFoodIds.contains(item.id))
        .fold(0.0, (sum, item) => sum + item.cost);
  }

  /// Calculate remaining budget
  double get _remainingBudget {
    return _budget - _totalCost;
  }

  /// Check if a food item can be selected (doesn't exceed budget)
  bool _canSelectItem(FoodItem item) {
    if (_selectedFoodIds.contains(item.id)) {
      return true; // Already selected items are always selectable (for deselection)
    }
    return _remainingBudget >= item.cost;
  }

  /// Toggle food item selection
  void _toggleFoodItem(int itemId, bool selected) {
    setState(() {
      if (selected) {
        _selectedFoodIds.add(itemId);
      } else {
        _selectedFoodIds.remove(itemId);
      }
    });
  }

  /// Show date picker dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepOrange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Update budget from text field
  void _updateBudgetFromText() {
    final value = double.tryParse(_budgetController.text);
    if (value != null && value > 0) {
      setState(() {
        _budget = value;
      });
    } else {
      _budgetController.text = _budget.toStringAsFixed(2);
    }
  }

  /// Save order plan to database
  Future<void> _saveOrderPlan() async {
    if (_selectedFoodIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one food item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get selected food items
    final selectedItems = _foodItems
        .where((item) => _selectedFoodIds.contains(item.id))
        .toList();

    // Create order plan object
    final orderPlan = OrderPlan(
      id: widget.existingOrder?.id, // null for new, existing id for update
      date: _selectedDate,
      targetCost: _budget,
      foodItems: selectedItems,
    );

    try {
      // Save to database (create or update)
      if (widget.existingOrder == null) {
        await _dbHelper.createOrderPlan(orderPlan);
      } else {
        await _dbHelper.updateOrderPlan(orderPlan);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingOrder == null
                  ? 'Order plan saved for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}'
                  : 'Order plan updated',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to previous screen
        Navigator.pop(context, true); // Return true to indicate changes were made
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving order plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingOrder == null ? 'Create Order Plan' : 'Edit Order Plan',
        ),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Budget and date selection section
          Container(
            decoration: BoxDecoration(
              color: Colors.deepOrange,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Budget input section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set Your Budget',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Budget slider and text input
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _budget,
                              min: 0,
                              max: 200,
                              divisions: 200,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white.withOpacity(0.3),
                              onChanged: (value) {
                                setState(() {
                                  _budget = value;
                                  _budgetController.text = value.toStringAsFixed(2);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _budgetController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                prefixText: '\$ ',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (_) => _updateBudgetFromText(),
                            ),
                          ),
                        ],
                      ),

                      // Budget summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildBudgetInfo(
                              'Budget',
                              '\$${_budget.toStringAsFixed(2)}',
                            ),
                            _buildBudgetInfo(
                              'Spent',
                              '\$${_totalCost.toStringAsFixed(2)}',
                            ),
                            _buildBudgetInfo(
                              'Remaining',
                              '\$${_remainingBudget.toStringAsFixed(2)}',
                              isHighlight: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Date selection
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Order Date: ${DateFormat('MMMM dd, yyyy').format(_selectedDate)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Food items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 100),
              itemCount: _foodItems.length,
              itemBuilder: (context, index) {
                final item = _foodItems[index];
                final isSelected = _selectedFoodIds.contains(item.id);
                final isDisabled = !_canSelectItem(item);

                return FoodItemCard(
                  foodItem: item,
                  isSelected: isSelected,
                  isDisabled: isDisabled,
                  onChanged: (selected) {
                    _toggleFoodItem(item.id!, selected!);
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Floating action button to save order (shown when items are selected)
      floatingActionButton: _selectedFoodIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _saveOrderPlan,
              backgroundColor: Colors.green,
              icon: const Icon(Icons.check),
              label: Text(
                widget.existingOrder == null ? 'Create Order Plan' : 'Update Order Plan',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  /// Build budget information widget
  Widget _buildBudgetInfo(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.yellow : Colors.white,
          ),
        ),
      ],
    );
  }
}
