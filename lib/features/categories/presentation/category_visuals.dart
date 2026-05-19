import "package:flutter/material.dart";

import "package:smart_expense/features/transactions/domain/entities/category.dart";

class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> byName = {
    "restaurant": Icons.restaurant,
    "local_cafe": Icons.local_cafe,
    "fastfood": Icons.fastfood,
    "local_bar": Icons.local_bar,
    "local_grocery_store": Icons.local_grocery_store,
    "cake": Icons.cake,
    "dinner_dining": Icons.dinner_dining,
    "directions_car": Icons.directions_car,
    "train": Icons.train,
    "flight": Icons.flight,
    "directions_bike": Icons.directions_bike,
    "motorcycle": Icons.motorcycle,
    "local_taxi": Icons.local_taxi,
    "electric_bolt": Icons.electric_bolt,
    "shopping_bag": Icons.shopping_bag,
    "receipt_long": Icons.receipt_long,
    "card_giftcard": Icons.card_giftcard,
    "local_mall": Icons.local_mall,
    "checkroom": Icons.checkroom,
    "movie": Icons.movie,
    "sports_esports": Icons.sports_esports,
    "headphones": Icons.headphones,
    "sports_basketball": Icons.sports_basketball,
    "beach_access": Icons.beach_access,
    "medical_services": Icons.medical_services,
    "spa": Icons.spa,
    "fitness_center": Icons.fitness_center,
    "local_pharmacy": Icons.local_pharmacy,
    "home": Icons.home,
    "apartment": Icons.apartment,
    "water_drop": Icons.water_drop,
    "wifi": Icons.wifi,
    "local_laundry_service": Icons.local_laundry_service,
    "build": Icons.build,
    "school": Icons.school,
    "work": Icons.work,
    "book": Icons.book,
    "business_center": Icons.business_center,
    "payments": Icons.payments,
    "savings": Icons.savings,
    "account_balance": Icons.account_balance,
    "credit_card": Icons.credit_card,
    "trending_up": Icons.trending_up,
    "currency_exchange": Icons.currency_exchange,
    "child_care": Icons.child_care,
    "pets": Icons.pets,
    "volunteer_activism": Icons.volunteer_activism,
    "phone_android": Icons.phone_android,
    "category": Icons.category,
    "label_outline": Icons.label_outline,
  };

  static IconData get(String key) => byName[key] ?? Icons.category;
}

extension CategoryVisuals on LedgerCategory {
  IconData get icon => CategoryIcons.get(iconKey);
  Color get color => Color(colorValue);
}
