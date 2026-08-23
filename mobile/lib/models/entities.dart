class AppUser {
  AppUser({required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(id: json['id'], name: json['name'], email: json['email']);
  }
}

class Product {
  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.weightGrams,
    this.imageUrl,
    this.packageQuantity,
    this.originBase,
    this.sourceUrl,
    this.retailerEvidence = const [],
  });

  final String id;
  final String barcode;
  final String name;
  final String brand;
  final String category;
  final double price;
  final int weightGrams;
  final String? imageUrl;
  final String? packageQuantity;
  final String? originBase;
  final String? sourceUrl;
  final List<RetailerEvidence> retailerEvidence;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      barcode: json['barcode'],
      name: json['name'],
      brand: json['brand'],
      category: json['category'],
      price: double.parse(json['price'].toString()),
      weightGrams: json['weightGrams'],
      imageUrl: json['imageUrl'],
      packageQuantity: json['packageQuantity'],
      originBase: json['originBase'],
      sourceUrl: json['sourceUrl'],
      retailerEvidence: ((json['retailerEvidence'] ?? []) as List)
          .map((item) => RetailerEvidence.fromJson(item))
          .toList(),
    );
  }
}

class RetailerEvidence {
  RetailerEvidence({
    required this.retailerName,
    this.region,
    this.linkMethod,
    this.confidence,
  });

  final String retailerName;
  final String? region;
  final String? linkMethod;
  final String? confidence;

  factory RetailerEvidence.fromJson(Map<String, dynamic> json) {
    return RetailerEvidence(
      retailerName: json['retailerName'],
      region: json['region'],
      linkMethod: json['linkMethod'],
      confidence: json['confidence'],
    );
  }
}

class Cart {
  Cart({required this.id, required this.code, required this.status});

  final String id;
  final String code;
  final String status;

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(id: json['id'], code: json['code'], status: json['status']);
  }
}

class ShoppingItem {
  ShoppingItem({
    required this.id,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.totalWeightGrams,
    required this.product,
  });

  final String id;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final int totalWeightGrams;
  final Product product;

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'],
      quantity: json['quantity'],
      unitPrice: double.parse(json['unitPrice'].toString()),
      totalPrice: double.parse(json['totalPrice'].toString()),
      totalWeightGrams: json['totalWeightGrams'],
      product: Product.fromJson(json['product']),
    );
  }
}

class ShoppingSession {
  ShoppingSession({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.expectedWeightGrams,
    required this.items,
    this.cart,
    this.createdAt,
  });

  final String id;
  final String status;
  final double totalAmount;
  final int expectedWeightGrams;
  final List<ShoppingItem> items;
  final Cart? cart;
  final DateTime? createdAt;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  factory ShoppingSession.fromJson(Map<String, dynamic> json) {
    return ShoppingSession(
      id: json['id'],
      status: json['status'],
      totalAmount: double.parse(json['totalAmount'].toString()),
      expectedWeightGrams: json['expectedWeightGrams'],
      cart: json['cart'] == null ? null : Cart.fromJson(json['cart']),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt']),
      items: ((json['items'] ?? []) as List)
          .map((item) => ShoppingItem.fromJson(item))
          .toList(),
    );
  }
}
