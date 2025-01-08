import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OrderHistory extends StatefulWidget {
  const OrderHistory({Key? key}) : super(key: key);

  @override
  _OrderHistoryState createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrderHistory();
  }

  // Convert string to double safely
  double parsePrice(dynamic price) {
    if (price is int) return price.toDouble();
    if (price is double) return price;
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  Future<void> fetchOrderHistory() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse(
            'https://3289-103-246-107-4.ngrok-free.app/api/order-history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          orders = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load order history');
      }
    } catch (e) {
      print('Error fetching order history: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load order history')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: const Color(0xFF003161),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('No orders found'))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final totalPrice = parsePrice(order['total_price']);
                    final shippingPrice =
                        parsePrice(order['shipping_price'] ?? 0);

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ExpansionTile(
                        title: Text('Order #${order['id']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total: Rp${double.parse(totalPrice.toString()).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Shipping: Rp${double.parse(shippingPrice.toString()).toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                        children: [
                          // Shipping Information
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            color: Colors.grey[100],
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Shipping Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                    'To: ${order['shipping_destination'] ?? 'N/A'}'),
                                Text(
                                    'Courier: ${order['courier_service'] ?? 'N/A'}'),
                                Text(
                                    'Estimated Delivery: ${order['estimated_days'] ?? 'N/A'} days'),
                                const Divider(),
                              ],
                            ),
                          ),
                          // Order Items
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: order['details'].length,
                            itemBuilder: (context, detailIndex) {
                              final detail = order['details'][detailIndex];
                              final productPrice =
                                  parsePrice(detail['product_price']);
                              final quantity = detail['product_quantity'] ?? 0;
                              final subtotal = productPrice * quantity;

                              return ListTile(
                                title: Text(detail['product']
                                        ['product_title'] ??
                                    'Unknown Product'),
                                subtitle: Text(
                                  'Quantity: $quantity x Rp${productPrice.toStringAsFixed(0)}',
                                ),
                                trailing: Text(
                                  'Rp${subtotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
