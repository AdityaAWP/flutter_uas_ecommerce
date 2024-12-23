class Product {
  final String title;
  final String description;
  final double price;
  final String imageUrl;

  Product({
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      title: json['product_title'] ?? 'Unknown',
      description: json['product_description'] ?? 'No description available',
      price: double.tryParse(json['product_price'].toString()) ?? 0.0,
      imageUrl: json['product_image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_title': title,
      'product_description': description,
      'product_price': price,
      'product_image': imageUrl,
    };
  }
}
