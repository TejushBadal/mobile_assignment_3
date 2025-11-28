# Food Ordering Mobile Application

A Flutter-based mobile application for planning daily food orders within a specified budget. Users can select food items from a pre-populated menu, set daily budget constraints, and manage their order plans through an intuitive interface with persistent local storage.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Database Schema](#database-schema)
- [Key Components](#key-components)
- [Installation & Setup](#installation--setup)
- [Usage Guide](#usage-guide)

## Overview

The Food Ordering app is designed to help users plan their daily meals while staying within budget constraints. The application provides a simple yet functional interface for selecting food items, tracking costs in real-time, and managing order plans with full CRUD (Create, Read, Update, Delete) functionality. All data is persisted locally using SQLite, ensuring offline capability and fast performance.

### Core Functionality
- **Budget Management**: Set and track daily food budgets with real-time cost calculations
- **Smart Selection**: Dynamic item availability based on remaining budget
- **Order Planning**: Create, view, edit, and delete order plans
- **Date-based Queries**: Filter and search order plans by specific dates
- **Persistent Storage**: Local SQLite database for offline data persistence

## Features

### 1. Menu Selection Screen
- **Budget Input**: Dual input method (slider and text field) for setting daily budget (up to $200)
- **Date Selection**: Calendar picker for selecting order plan dates
- **Real-time Budget Tracking**: Live display of budget, spent amount, and remaining balance
- **Smart Item Filtering**: Automatically disables items that exceed remaining budget
- **Visual Feedback**: Grayed-out UI for unavailable items based on budget constraints

### 2. Order History Management
- **Complete Order List**: View all saved order plans sorted by date
- **Date-based Filtering**: Query orders for specific dates using calendar picker
- **Order Details**: View comprehensive breakdown of each order (items, costs, date, budget)
- **Edit Functionality**: Modify existing orders with pre-populated data
- **Delete Capability**: Remove orders with confirmation dialog

### 3. Data Persistence
- **SQLite Database**: Local database for storing food items and order plans
- **Pre-populated Menu**: 22 food items automatically loaded on first launch
- **Relational Data**: Proper relationship management between orders and food items
- **ACID Compliance**: Reliable data transactions with rollback capability

## Technology Stack

- **Framework**: Flutter 3.10.1
- **Language**: Dart
- **Database**: SQLite (via sqflite package 2.3.0)
- **Design Pattern**: MVC (Model-View-Controller) architecture
- **State Management**: StatefulWidget with setState
- **UI Design**: Material Design 3 with custom theming

### Dependencies
```yaml
dependencies:
  flutter: sdk: flutter
  cupertino_icons: ^1.0.8
  intl: ^0.19.0          # Date formatting
  sqflite: ^2.3.0        # SQLite database
  path: ^1.8.3           # Path manipulation
```

## Project Structure

```
mobile_assignment_3/
├── lib/
│   ├── main.dart                          # Application entry point
│   ├── models/                            # Data models
│   │   ├── food_item.dart                 # Food item model
│   │   └── order_plan.dart                # Order plan model
│   ├── screens/                           # UI screens
│   │   ├── home_screen.dart               # Home/landing screen
│   │   ├── menu_screen.dart               # Menu selection screen
│   │   └── order_history_screen.dart      # Order history & management
│   ├── widgets/                           # Reusable UI components
│   │   └── food_item_card.dart            # Food item display card
│   ├── database/                          # Database layer
│   │   └── database_helper.dart           # SQLite operations
│   └── data/                              # Static data
│       └── dummy_data.dart                # Initial food items (22 items)
├── assets/
│   └── images/                            # Food images (placeholder ready)
├── test/                                  # Unit and widget tests
├── pubspec.yaml                           # Project dependencies
└── README.md                              # This file
```

## Database Schema

### Tables

#### 1. `food_items`
Stores the menu of available food items.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PRIMARY KEY | Unique identifier |
| name | TEXT NOT NULL | Food item name |
| description | TEXT NOT NULL | Item description |
| cost | REAL NOT NULL | Item price in dollars |
| imagePath | TEXT | Path to food image (optional) |

#### 2. `order_plans`
Stores user-created order plans.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PRIMARY KEY | Unique identifier |
| date | TEXT NOT NULL | Order date (ISO 8601 format) |
| targetCost | REAL NOT NULL | Daily budget limit |

#### 3. `order_items`
Junction table linking order plans to food items (many-to-many relationship).

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PRIMARY KEY | Unique identifier |
| orderPlanId | INTEGER NOT NULL | Foreign key to order_plans |
| foodItemId | INTEGER NOT NULL | Foreign key to food_items |

### Relationships
- One `order_plan` can contain multiple `food_items` (one-to-many)
- One `food_item` can appear in multiple `order_plans` (many-to-one)
- `order_items` serves as the junction table implementing the many-to-many relationship

## Key Components

### 1. Models (`lib/models/`)

#### `food_item.dart`
Represents a menu item with properties and database conversion methods.

**Key Properties:**
- `id`: Database identifier
- `name`: Item name (e.g., "Classic Burger")
- `description`: Brief description
- `cost`: Item price
- `imagePath`: Optional image reference

**Key Methods:**
- `fromMap()`: Deserializes database row to FoodItem object
- `toMap()`: Serializes FoodItem object to database-compatible map

#### `order_plan.dart`
Represents a saved order plan with calculated properties.

**Key Properties:**
- `id`: Database identifier
- `date`: Order date
- `targetCost`: Budget limit
- `foodItems`: List of selected food items

**Key Methods:**
- `totalCost`: Computed property calculating sum of all item costs
- `fromMap()`: Deserializes database row with related food items
- `toMap()`: Serializes order plan for database storage

### 2. Database Layer (`lib/database/`)

#### `database_helper.dart`
Singleton class managing all SQLite operations.

**Key Properties:**
- `instance`: Singleton instance for global access
- `database`: Lazy-loaded database connection

**Key Methods:**

##### Database Initialization
- `_initDB()`: Creates database file and establishes connection
- `_createDB()`: Creates tables with proper schema and constraints
- `_populateFoodItems()`: Inserts 22 default food items on first launch

##### Food Items Operations (READ-only)
- `getAllFoodItems()`: Retrieves all menu items sorted alphabetically
- `getFoodItem(id)`: Retrieves specific food item by ID

##### Order Plans Operations (Full CRUD)
- `createOrderPlan(OrderPlan)`: Inserts new order plan with associated items
  - Inserts into `order_plans` table
  - Inserts relationships into `order_items` junction table
  - Returns new order ID

- `getAllOrderPlans()`: Retrieves all order plans with food items
  - Joins `order_plans` with `order_items` and `food_items`
  - Sorts by date (descending)
  - Returns fully populated OrderPlan objects

- `getOrderPlansByDate(DateTime)`: Queries orders for specific date
  - Filters by date string matching
  - Returns matching order plans with items

- `updateOrderPlan(OrderPlan)`: Modifies existing order plan
  - Updates order plan details
  - Deletes old order items
  - Inserts updated order items
  - Maintains referential integrity

- `deleteOrderPlan(id)`: Removes order plan
  - Deletes from `order_items` first (foreign key constraint)
  - Deletes from `order_plans`
  - Ensures cascading deletion

##### Helper Methods
- `_getFoodItemsForOrder(orderPlanId)`: Retrieves food items for specific order
  - Uses SQL JOIN for efficient querying
  - Returns list of FoodItem objects

### 3. Screens (`lib/screens/`)

#### `home_screen.dart`
Landing page with navigation to main features.

**Key Features:**
- Gradient background with app branding
- "Begin Order" button → navigates to Menu Screen
- "View Past Orders" button → navigates to Order History Screen

**Key Methods:**
- `_buildNavigationButton()`: Creates styled navigation buttons with icons

#### `menu_screen.dart`
Core screen for creating and editing order plans.

**Key State Variables:**
- `_budget`: Current budget amount
- `_selectedDate`: Date for order plan
- `_selectedFoodIds`: Set of selected food item IDs
- `_foodItems`: List of available food items from database
- `_isLoading`: Loading state indicator

**Key Methods:**
- `_loadFoodItems()`: Fetches menu items from database on screen initialization
- `_canSelectItem(FoodItem)`: Determines if item is selectable based on remaining budget
- `_toggleFoodItem(id, selected)`: Adds/removes item from selection
- `_selectDate()`: Shows date picker dialog with custom styling
- `_updateBudgetFromText()`: Validates and updates budget from text input
- `_saveOrderPlan()`: Saves or updates order plan to database
  - Validates at least one item selected
  - Creates OrderPlan object
  - Calls appropriate database method (create vs update)
  - Shows success/error feedback
  - Navigates back on success

**Key Computed Properties:**
- `_totalCost`: Sum of selected items' costs
- `_remainingBudget`: Budget minus total cost

**UI Components:**
- Budget slider (0-200) with synchronized text input
- Budget summary panel (budget, spent, remaining)
- Date selector with calendar icon
- Scrollable list of food item cards
- Floating action button for saving (appears when items selected)

#### `order_history_screen.dart`
Displays and manages saved order plans.

**Key State Variables:**
- `_orderPlans`: All order plans from database
- `_filteredOrderPlans`: Filtered order plans (by date or all)
- `_selectedFilterDate`: Active filter date (null = show all)
- `_isLoading`: Loading state indicator

**Key Methods:**
- `_loadOrders()`: Fetches all order plans from database
- `_filterByDate(DateTime?)`: Filters orders by specific date or shows all
  - Calls `getOrderPlansByDate()` for specific date
  - Calls `getAllOrderPlans()` for all orders
  - Updates UI with filtered results

- `_selectFilterDate()`: Shows date picker for filtering
  - Custom Material Design theme
  - Calls `_filterByDate()` with selected date

- `_clearFilter()`: Removes date filter and shows all orders

- `_deleteOrder(id)`: Deletes order plan with confirmation
  - Shows confirmation dialog
  - Calls `deleteOrderPlan()` on database helper
  - Reloads orders on success
  - Shows feedback snackbar

- `_editOrder(OrderPlan)`: Navigates to Menu Screen for editing
  - Passes existing order to Menu Screen
  - Reloads orders when returning (if changes made)

**UI Components:**
- App bar with filter icon and clear filter button
- Filter indicator banner (shows active filter)
- Order cards with:
  - Date and budget display
  - List of items with prices
  - Total cost calculation
  - Edit and Delete buttons
- Empty state with helpful messages

### 4. Widgets (`lib/widgets/`)

#### `food_item_card.dart`
Reusable card component for displaying food items.

**Key Properties:**
- `foodItem`: FoodItem object to display
- `isSelected`: Selection state
- `isDisabled`: Whether item is selectable (based on budget)
- `onChanged`: Callback for checkbox state changes

**Key Features:**
- Displays food icon placeholder (ready for custom images)
- Shows name, description, and cost
- Checkbox for selection
- Opacity change when disabled
- Tap gesture support for entire card

**Key Methods:**
- `_buildFoodImage()`: Creates placeholder food icon
  - Container with rounded corners
  - Background color based on theme
  - FastFood icon placeholder

### 5. Data (`lib/data/`)

#### `dummy_data.dart`
Contains 22 pre-defined food items for database population.

**Food Categories Included:**
- Burgers & Sandwiches (5 items)
- Pizza & Italian (4 items)
- Salads & Healthy (4 items)
- Asian Cuisine (3 items)
- Mexican Food (3 items)
- Seafood (1 item)
- Soups (2 items)

**Price Range:** $6.50 - $18.99

### 6. Main Application (`lib/main.dart`)

#### `FoodOrderingApp`
Root widget configuring app-wide settings.

**Key Configurations:**
- Material Design 3 enabled
- Orange/deep orange color scheme (appetite-appealing)
- Custom theme for buttons, cards, and inputs
- Centered app bar titles
- Rounded corner design language

**Theme Elements:**
- Primary color: Deep Orange
- Secondary color: Orange
- Card elevation: 2
- Border radius: 12px (consistent throughout)
- Button padding: 24x12

## Installation & Setup

### Prerequisites
- Flutter SDK 3.10.1 or higher
- Dart SDK
- Android Studio or VS Code with Flutter extensions
- Android Emulator or physical device

### Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mobile_assignment_3
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

4. **First Launch**
   - Database will be created automatically
   - 22 food items will be pre-populated
   - App is ready to use

## Usage Guide

### Creating an Order Plan

1. From the home screen, tap **"Begin Order"**
2. Set your daily budget using the slider or text input
3. Select the date for your order plan
4. Browse the food items and tap checkboxes to select
   - Items exceeding remaining budget will be grayed out
5. Monitor your budget summary (Budget, Spent, Remaining)
6. Once satisfied, tap the **"Create Order Plan"** button
7. Success message confirms the order is saved

### Viewing Order History

1. From the home screen, tap **"View Past Orders"**
2. All saved orders are displayed, sorted by date (newest first)
3. Each card shows:
   - Order date
   - Budget allocated
   - List of food items with individual costs
   - Total cost

### Filtering Orders by Date

1. In Order History, tap the **filter icon** in the app bar
2. Select a date from the calendar picker
3. Only orders for that date will be displayed
4. A filter indicator banner appears at the top
5. Tap the **"X" icon** or **"Show All Orders"** to clear the filter

### Editing an Order Plan

1. In Order History, find the order you want to edit
2. Tap the **"Edit"** button on the order card
3. Menu screen opens with pre-filled data:
   - Previously selected items are checked
   - Original budget is set
   - Original date is selected
4. Make your changes (add/remove items, adjust budget, change date)
5. Tap **"Update Order Plan"** to save changes

### Deleting an Order Plan

1. In Order History, find the order you want to delete
2. Tap the **"Delete"** button on the order card
3. Confirm deletion in the dialog
4. Order is permanently removed from the database

## Technical Highlights

### Design Patterns
- **Singleton Pattern**: DatabaseHelper ensures single database connection
- **Repository Pattern**: Database layer abstracts data access from UI
- **MVC Architecture**: Clear separation of models, views, and logic

### Performance Optimizations
- Lazy database initialization (only created when needed)
- Efficient SQL queries with JOINs instead of multiple queries
- Widget reusability (FoodItemCard component)
- Computed properties for derived data (totalCost, remainingBudget)

### User Experience Features
- Real-time budget calculations
- Smart item filtering based on budget
- Visual feedback for disabled items
- Loading indicators during database operations
- Confirmation dialogs for destructive actions
- Success/error snackbars for user feedback
- Smooth navigation with data passing

### Data Integrity
- Foreign key constraints for referential integrity
- Cascading deletes to maintain consistency
- Date filtering using ISO 8601 format
- Validation before database operations

## Future Enhancements

Potential improvements for future versions:
- Custom food images support (placeholder system already in place)
- Export order plans to PDF or CSV
- Weekly/monthly budget tracking
- Food item favorites system
- Nutrition information tracking
- Multiple user profiles
- Cloud sync for backup
- Analytics and spending insights
- Recipe suggestions based on budget

## Project Information

**Course Assignment**: Mobile Application Development - Assignment 3
**Framework**: Flutter
**Database**: SQLite
**Design Pattern**: MVC with Repository Pattern
**Development Period**: 2025

---

**Note**: This application demonstrates fundamental mobile development concepts including UI/UX design, local data persistence, CRUD operations, state management, and Material Design implementation in Flutter.
