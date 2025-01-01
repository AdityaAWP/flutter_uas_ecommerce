class Product {
  final int id; // Add the id property
  final String title;
  final String description;
  final double price;
  final String imageUrl;

  Product({
    required this.id, // Include id in the constructor
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'], // Parse id from JSON
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
