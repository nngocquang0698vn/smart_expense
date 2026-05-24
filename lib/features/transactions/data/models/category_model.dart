import "package:flutter/material.dart";

/// All Material icons available for category selection.
/// Keys are stored in the database; values are the actual IconData.
class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> byName = {
    // Food & Drink
    "restaurant": Icons.restaurant,
    "local_cafe": Icons.local_cafe,
    "fastfood": Icons.fastfood,
    "local_bar": Icons.local_bar,
    "local_grocery_store": Icons.local_grocery_store,
    "cake": Icons.cake,
    "dinner_dining": Icons.dinner_dining,
    // Transport
    "directions_car": Icons.directions_car,
    "train": Icons.train,
    "flight": Icons.flight,
    "directions_bike": Icons.directions_bike,
    "motorcycle": Icons.motorcycle,
    "local_taxi": Icons.local_taxi,
    "electric_bolt": Icons.electric_bolt,
    // Shopping
    "shopping_bag": Icons.shopping_bag,
    "receipt_long": Icons.receipt_long,
    "card_giftcard": Icons.card_giftcard,
    "local_mall": Icons.local_mall,
    "checkroom": Icons.checkroom,
    // Entertainment
    "movie": Icons.movie,
    "sports_esports": Icons.sports_esports,
    "headphones": Icons.headphones,
    "sports_basketball": Icons.sports_basketball,
    "beach_access": Icons.beach_access,
    // Health & Beauty
    "medical_services": Icons.medical_services,
    "spa": Icons.spa,
    "fitness_center": Icons.fitness_center,
    "local_pharmacy": Icons.local_pharmacy,
    // Home & Utilities
    "home": Icons.home,
    "apartment": Icons.apartment,
    "water_drop": Icons.water_drop,
    "wifi": Icons.wifi,
    "local_laundry_service": Icons.local_laundry_service,
    "build": Icons.build,
    // Education & Work
    "school": Icons.school,
    "work": Icons.work,
    "book": Icons.book,
    "business_center": Icons.business_center,
    // Finance
    "payments": Icons.payments,
    "savings": Icons.savings,
    "account_balance": Icons.account_balance,
    "credit_card": Icons.credit_card,
    "trending_up": Icons.trending_up,
    "currency_exchange": Icons.currency_exchange,
    // Family & Pets
    "child_care": Icons.child_care,
    "pets": Icons.pets,
    "volunteer_activism": Icons.volunteer_activism,
    // Other
    "phone_android": Icons.phone_android,
    "category": Icons.category,
    "label_outline": Icons.label_outline,
  };

  static IconData get(String key) => byName[key] ?? Icons.category;
}

/// Preset colors for category selection.
const List<int> kCategoryColors = [
  0xFF26A69A, // teal
  0xFF42A5F5, // blue
  0xFF66BB6A, // green
  0xFFEF5350, // red
  0xFFFF7043, // deep orange
  0xFFFFCA28, // amber
  0xFFAB47BC, // purple
  0xFF8D6E63, // brown
  0xFF78909C, // blue-grey
  0xFF26C6DA, // cyan
  0xFFEC407A, // pink
  0xFF7E57C2, // deep purple
  0xFF29B6F6, // light blue
  0xFF9CCC65, // light green
  0xFFFFA726, // orange
];

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.isIncome,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String iconKey;
  final int colorValue;
  final bool isIncome;
  final bool enabled;

  Map<String, Object?> toMap() => {
    "name": name,
    "iconKey": iconKey,
    "colorValue": colorValue,
    "isIncome": isIncome,
    "enabled": enabled,
  };

  static CategoryModel fromMap(String id, Map<String, Object?> map) {
    return CategoryModel(
      id: id,
      name: map["name"]! as String,
      iconKey: map["iconKey"]! as String,
      colorValue: map["colorValue"]! as int,
      isIncome: (map["isIncome"] as bool?) ?? false,
      enabled: (map["enabled"] as bool?) ?? true,
    );
  }
}
