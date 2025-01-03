// lib/screens/home.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'product_model.dart';
import 'detailpage.dart';
import 'payementpage.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String username = 'Loading...';
  List<Product> products = [];
  bool isLoading = true;
  static const String baseUrl =
      'http://127.0.0.1:8000'; // Update with your API URL
  double totalSelectedPrice = 0.0;
  Map<Product, int> selectedProducts = {};

  @override
  void initState() {
    super.initState();
    _loadUsername();
    fetchProducts();
  }

  Future<void> _loadUsername() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final storedUsername = prefs.getString('username');
      if (mounted) {
        setState(() {
          username = storedUsername ?? 'Guest';
        });
      }
    } catch (e) {
      print('Error loading username: $e');
      if (mounted) {
        setState(() {
          username = 'Error loading';
        });
      }
    }
  }

  Future<void> fetchProducts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      print(token);
      final response = await http.get(
        Uri.parse('$baseUrl/api/products'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          final productList = responseData['data']['data'] as List;
          products = productList.map((data) {
            data['product_image'] = '$baseUrl/storage/${data['product_image']}';
            return Product.fromJson(data);
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load products')),
        );
      }
    }
  }

  Future<void> _launchCallCenter() async {
    final Uri url = Uri.parse('tel:+6288232308327');
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchSmsCenter() async {
    final Uri url = Uri.parse('sms:+6288232308327');
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchMap() async {
    final Uri url = Uri.parse('https://maps.app.goo.gl/4MF1GX8ipqRTsaPY7');
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }

  void _addProductToSelection(Product product) {
    setState(() {
      if (selectedProducts.containsKey(product)) {
        selectedProducts[product] = selectedProducts[product]! + 1;
      } else {
        selectedProducts[product] = 1;
      }
      totalSelectedPrice += product.price;
    });
  }

  void _navigateToPaymentPage() {
    setState(() {
      // Save selected products and quantities to state
      selectedProducts = Map.from(selectedProducts);
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          totalPrice: totalSelectedPrice,
          purchasedItems: selectedProducts.entries.map((entry) {
            return {
              'id': entry.key.id, // Include product ID
              'name': entry.key.title,
              'price': entry.key.price,
              'quantity': entry.value,
            };
          }).toList(),
        ),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {
          totalSelectedPrice = 0.0;
          selectedProducts.clear();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Hi, $username',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            const Text(
              'COMO STORE',
              style: TextStyle(color: Colors.white),
            ),
            Container(width: 50),
          ],
        ),
        backgroundColor: const Color(0xFF003161),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchProducts,
              child: products.isEmpty
                  ? const Center(
                      child: Text('No products available'),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.9,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final quantity = selectedProducts[product] ?? 0;
                        return Card(
                          elevation: 4,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetailPage(product: product),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4)),
                                      child: Image.network(
                                        product.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Center(
                                            child:
                                                Icon(Icons.image_not_supported),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        product.description,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: () =>
                                            _addProductToSelection(product),
                                        child: Container(
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4.0),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Rp${product.price.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: quantity > 0
                                                      ? Colors.green
                                                      : Colors.blue,
                                                ),
                                              ),
                                              if (quantity > 0)
                                                Text(
                                                  'Quantity: $quantity',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: _navigateToPaymentPage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 20.0),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                backgroundColor: const Color(0xFF003161), // Button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(
                'Total Harga: Rp${totalSelectedPrice.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          BottomAppBar(
            color: const Color(0xFF003161),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.white),
                    onPressed: _launchCallCenter,
                    tooltip: 'Call Center',
                  ),
                  IconButton(
                    icon: const Icon(Icons.sms, color: Colors.white),
                    onPressed: _launchSmsCenter,
                    tooltip: 'SMS Center',
                  ),
                  IconButton(
                    icon: const Icon(Icons.map, color: Colors.white),
                    onPressed: _launchMap,
                    tooltip: 'Location/Maps',
                  ),
                  IconButton(
                    icon: const Icon(Icons.person, color: Colors.white),
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/updateUser');
                      _loadUsername();
                    },
                    tooltip: 'Update User',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
